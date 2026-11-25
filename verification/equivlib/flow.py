"""The GHDL + Yosys flow that proves one VHDL design equivalent to its Verilog reference.

Two proof engines share the same miter of both designs:
- 'sat': Yosys' built-in SAT solver ('sat -seq N -prove-asserts') proves it inside Yosys.
- an SMT solver (boolector, bitwuzla, yices, z3): Yosys exports the miter with 'write_smt2' and
  yosys-smtbmc runs the bounded model check with that solver. Usually several times faster.
"""

import os
import re
import shlex
import shutil
import signal
import subprocess
import threading
import time
from dataclasses import dataclass
from pathlib import Path

from . import vcddiff
from .config import EquivTest
from .toolchain import Toolchain


CUT_SEPARATOR = ":"     # Port names of blackboxed instances: <instance>:<port>
# The inputs of the exported miter, with their widths: '; yosys-smt2-input <name> <width>'
SMT2_INPUT = re.compile(r"^; yosys-smt2-input (\S+) (\d+)$", re.MULTILINE)

# Process groups of the running yosys-smtbmc processes, see _run() and kill_running()
_groups: set[int] = set()
_groups_lock = threading.Lock()


class FlowError(Exception):
    """The flow for a test could not be set up (e.g. the top-level entity was not found)."""


@dataclass
class Plan:
    """Everything needed to run one test; also what --check prints."""
    test: EquivTest
    workdir: Path                            # build/<module>/<test id>/, deleted and recreated by execute()
    ghdl_args: list[str]                     # Without the ghdl executable, which comes from the toolchain
    vhdl_override: tuple[Path, str] | None   # Patched copy of the top-level VHDL file (path, text)
    silver: Path                             # GHDL's Verilog netlist of the VHDL design
    script: Path                             # Yosys script file (equivalence.ys)
    script_text: str
    smt2: Path | None                        # SMT solvers: miter exported by Yosys (equivalence.smt2)
    smtc: Path | None                        # SMT solvers: reset sequence as yosys-smtbmc constraints
    smtbmc_args: list[str] | None            # SMT solvers: without the yosys-smtbmc executable
    log: Path                                # Commands and output of GHDL, Yosys and yosys-smtbmc
    vcd: Path | None                         # Counterexample waveform, only written if the proof fails
    divergence: Path | None                  # Analysis of the counterexample (see vcddiff)


def plan(test: EquivTest, build_root: Path, dump_vcd: bool = False) -> Plan:
    """
    Return a Plan for one equivalence test, including the GHDL command line and the Yosys script.

    Parameters:
        test: The equivalence test to plan.
        build_root: The root directory for build artifacts.
        dump_vcd: If True, dump the counterexample of a failing proof to a VCD file.
    Returns:
        A Plan object containing all the information needed to run the test.
    """
    workdir = build_root / test.module / test.id
    ghdl_work = workdir / "ghdl-work"
    silver = workdir / f"{test.top}.v"
    script = workdir / "equivalence.ys"
    smt = test.solver != "sat"
    smt2 = workdir / "equivalence.smt2" if smt else None
    smtc = workdir / "reset.smtc" if smt else None
    vcd =workdir / f"{test.top}_counterexample.vcd" if dump_vcd else None
    divergence = workdir / f"{test.top}_divergence.txt" if dump_vcd else None

    # GHDL can't set array generics via -g, so those become the new default value in a
    # copy of the file that declares the top-level entity.
    vhdl = list(test.vhdl)
    scalar = {k: v for k, v in test.generics.items() if not isinstance(v, list)}
    arrays = {k: v for k, v in test.generics.items() if isinstance(v, list)}
    override = None
    if arrays:
        index = _entity_file_index(test)
        text = vhdl[index].read_text()
        for name, value in arrays.items():
            text = _override_generic_default(text, test.top, name, vhdl_value(value))
        path = ghdl_work / f"{vhdl[index].stem}.generic.vhdl"
        vhdl[index] = path
        override = (path, text)

    # Synthesize the VHDL to a Verilog netlist; files in analysis order, then '-e' with the top entity
    ghdl_args = ["--synth", "--std=08", "--out=verilog", f"--workdir={ghdl_work}",
                 *(f"-g{k}={vhdl_value(v)}" for k, v in scalar.items()),
                 *map(str, vhdl), "-e", test.top]

    # yosys-smtbmc checks the asserts in steps 0 .. sat_cycles - 1, as many as 'sat -seq'. The
    # reset constraints are only added when they exist (written by execute(), see _smtc()).
    smtbmc_args = None
    if smt:
        smtbmc_args = ["-s", test.solver, "-t", str(test.sat_cycles)]
        if test.reset:
            smtbmc_args += ["--smtc", str(smtc)]
        if vcd:
            smtbmc_args += ["--dump-vcd", str(vcd)]
        smtbmc_args.append(str(smt2))

    return Plan(test=test, workdir=workdir, ghdl_args=ghdl_args, vhdl_override=override, silver=silver,
                script=script, script_text=_yosys_script(test, silver, script, smt2, vcd),
                smt2=smt2, smtc=smtc, smtbmc_args=smtbmc_args,
                log=workdir / f"{test.top}.log", vcd=vcd, divergence=divergence)


def execute(plan: Plan, toolchain: Toolchain, timeout: float | None) -> str:
    """Run the plan, returning 'proven', 'ghdl-synth-failed', 'equivalence-failed', 'timeout',
    'killed' or 'error' (Yosys or yosys-smtbmc failed without a verdict; SMT solvers only)."""
    # Start from a clean work directory, so no artifacts of an earlier run are mistaken for new ones
    shutil.rmtree(plan.workdir, ignore_errors=True)
    (plan.workdir / "ghdl-work").mkdir(parents=True)
    if plan.vhdl_override:
        plan.vhdl_override[0].write_text(plan.vhdl_override[1])

    # The timeout covers GHDL and Yosys together: each gets the time that is left
    deadline = time.monotonic() + timeout if timeout else None
    ghdl = [toolchain.ghdl, *plan.ghdl_args]
    yosys = [toolchain.yosys, "-s", str(plan.script)]

    with plan.log.open("w") as log:
        try:
            # flush() before each tool, so our lines end up in front of the tool's output in the log
            log.write(f"=== {plan.test.module}/{plan.test.id} ===\n$ {shlex.join(ghdl)}\n")
            log.flush()
            # GHDL writes the netlist to stdout and its messages to stderr. The netlist is captured and
            # written in one go: GHDL writes it in many tiny unbuffered writes, which take over a minute
            # on a slow file system (Docker Desktop's bind mount of a Windows drive).
            result = _run(ghdl, toolchain, plan.workdir, subprocess.PIPE, log, deadline)
            plan.silver.write_bytes(result.stdout)
            code = result.returncode
            # A negative return code means the process was terminated by that signal number
            if code != 0:
                return _killed(log, "ghdl", code) if code < 0 else "ghdl-synth-failed"
            # Which blackboxed instances exist depends on the generics (generate statements), so the
            # script is only final now that the netlist shows which ones GHDL instantiated
            if plan.test.blackbox_instances:
                present = _netlist_instances(plan.silver, plan.test.top)
                for vhdl_name, _ in plan.test.blackbox_instances:
                    if vhdl_name not in present:
                        log.write(f"note: blackboxed instance '{vhdl_name}' does not exist in this configuration\n")
                plan.script_text = _yosys_script(plan.test, plan.silver, plan.script, plan.smt2,
                                                 plan.vcd, present)
            plan.script.write_text(plan.script_text)
            log.write(f"\n$ {shlex.join(yosys)}\n")
            log.flush()
            code = _run(yosys, toolchain, plan.workdir, log, log, deadline).returncode
            if code < 0:
                return _killed(log, "yosys", code)
            if plan.smtbmc_args is None:
                # 'sat': Yosys exits with an error if 'sat -verify' finds a counterexample (or on any other error)
                if code > 0:
                    _analyze_counterexample(plan, log)
                    return "equivalence-failed"
                return "proven"
            if code > 0:
                log.write("\n*** Yosys failed to export the miter ***\n")
                return "error"
            return _smtbmc(plan, toolchain, log, deadline)
        except subprocess.TimeoutExpired:
            log.write(f"\n*** Timed out after {timeout} s ***\n")
            return "timeout"


def _smtbmc(plan: Plan, toolchain: Toolchain, log, deadline: float | None) -> str:
    """Run the bounded model check of the exported miter with yosys-smtbmc; return the status."""
    if plan.test.reset:
        plan.smtc.write_text(_smtc(plan.test.reset, plan.smt2.read_text()))
    smtbmc = [toolchain.smtbmc, *plan.smtbmc_args]
    log.write(f"\n$ {shlex.join(smtbmc)}\n")
    log.flush()
    start = plan.log.stat().st_size     # Only the output of yosys-smtbmc is searched for its verdict
    code = _run(smtbmc, toolchain, plan.workdir, log, log, deadline, own_group=True).returncode
    if code < 0:
        return _killed(log, "yosys-smtbmc", code)
    with plan.log.open("rb") as f:
        f.seek(start)
        output = f.read().decode(errors="replace")
    # yosys-smtbmc ends with 'Status: PASSED' or 'Status: FAILED'. Anything else (a missing solver,
    # a solver error, a Python traceback) is no verdict, and must not look like a counterexample.
    if code == 0 and "Status: PASSED" in output:
        return "proven"
    if "Status: FAILED" in output:
        _analyze_counterexample(plan, log)
        return "equivalence-failed"
    log.write(f"\n*** yosys-smtbmc ({plan.test.solver}) failed without a verdict (exit code {code}) ***\n")
    return "error"


def _smtc(reset: dict[str, list[int]], smt2: str) -> str:
    """Return the yosys-smtbmc constraints that apply the reset sequence, e.g.
    { rst_n = [0, 1] } -> 'state 0 / assume (= [rst_n] false) / state 1 / assume (= [rst_n] true)'.

    The step numbers of the TOML start at 1 (like 'sat -set-at'), those of yosys-smtbmc at 0. Only
    the listed steps are constrained; afterwards the signal is free, as with 'sat'. Yosys exports
    1-bit signals as SMT Booleans, wider ones as bit vectors, so the widths are taken from the
    exported miter.
    """
    widths = {name: int(width) for name, width in SMT2_INPUT.findall(smt2)}
    steps: dict[int, list[str]] = {}
    for name, values in reset.items():
        if name not in widths:
            raise FlowError(f"reset signal '{name}' is not an input of the design")
        width = widths[name]
        for step, value in enumerate(values):
            if not 0 <= value < 1 << width:
                raise FlowError(f"reset value {value} of '{name}' does not fit in {width} bit(s)")
            literal = ("true" if value else "false") if width == 1 else f"#b{value:0{width}b}"
            steps.setdefault(step, []).append(f"assume (= [{name}] {literal})")
    return "".join(f"state {step}\n" + "".join(f"{line}\n" for line in lines)
                   for step, lines in sorted(steps.items()))


def _killed(log, tool: str, code: int) -> str:
    """A tool terminated by a signal (e.g. by the OOM killer or by hand) has not disproven anything."""
    try:
        name = signal.Signals(-code).name
    except ValueError:
        name = f"signal {-code}"
    log.write(f"\n*** {tool} was terminated by {name} ***\n")
    return "killed"


def _analyze_counterexample(plan: Plan, log):
    """Append the gold/gate divergence report to the log and save it next to the VCD."""
    if not plan.vcd:
        return      # Run without --vcd
    # No VCD although requested: usually Yosys failed for another reason than a counterexample
    if not plan.vcd.is_file():
        log.write(f"\n*** No counterexample was dumped to {plan.vcd.name} ***\n")
        return
    try:
        text = vcddiff.report(vcddiff.analyze(plan.vcd, plan.silver), plan.vcd)
    except Exception as error:      # The analysis is a debugging aid, it must not hide the result
        text = f"Counterexample analysis failed: {type(error).__name__}: {error}\n"
    log.write(f"\n{text}")
    plan.divergence.write_text(text)


def vhdl_value(value: object) -> str:
    """Return the VHDL literal of a generic value: a boolean, a list of booleans (array generic),
    a raw { vhdl, verilog } table (its 'vhdl' string) or anything else (integers) with str()."""
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, list):
        # The first element is the highest index, matching the MSB-first Verilog literal
        high = len(value) - 1
        return "(" + ", ".join(f"{high - i} => {vhdl_value(v)}" for i, v in enumerate(value)) + ")"
    if isinstance(value, dict):
        return value["vhdl"]
    return str(value)


def verilog_value(value: object) -> str:
    """Return the Verilog literal of a generic value, see vhdl_value(); boolean lists become N'b...,
    first element = MSB."""
    if isinstance(value, bool):
        return "1" if value else "0"
    if isinstance(value, list):
        return f"{len(value)}'b" + "".join("1" if bit else "0" for bit in value)
    if isinstance(value, dict):
        return value["verilog"]
    return str(value)


def _run(argv, toolchain, cwd, stdout, stderr, deadline, own_group: bool = False) -> subprocess.CompletedProcess:
    """Run a command with the given toolchain and working directory; its returncode is negative if
    it was terminated by that signal. Raises subprocess.TimeoutExpired after the deadline;
    subprocess.run kills the process in that case.

    own_group: start the command in its own process group, and kill the whole group on a timeout.
    For yosys-smtbmc, whose solver process would otherwise keep running after yosys-smtbmc is
    killed. Outside the terminal's process group it doesn't receive Ctrl-C, so the runner calls
    kill_running() instead. POSIX only; elsewhere only the command itself is killed.
    """
    timeout = max(deadline - time.monotonic(), 0.1) if deadline else None
    if not own_group or os.name != "posix":
        return subprocess.run(argv, cwd=cwd, env=toolchain.env, stdout=stdout, stderr=stderr,
                              stdin=subprocess.DEVNULL, timeout=timeout)
    with subprocess.Popen(argv, cwd=cwd, env=toolchain.env, stdout=stdout, stderr=stderr,
                          stdin=subprocess.DEVNULL, process_group=0) as process:
        with _groups_lock:
            _groups.add(process.pid)    # process_group=0: the group ID is the process ID
        try:
            process.wait(timeout=timeout)
        except subprocess.TimeoutExpired:
            _kill_group(process.pid)
            process.wait()
            raise
        finally:
            with _groups_lock:
                _groups.discard(process.pid)
            # The solver may outlive yosys-smtbmc if that crashed
            _kill_group(process.pid)
    return subprocess.CompletedProcess(argv, process.returncode)


def _kill_group(group: int):
    """Kill all processes of a process group, if any are left."""
    try:
        os.killpg(group, signal.SIGKILL)
    except (ProcessLookupError, PermissionError):
        pass


def kill_running():
    """Kill the running yosys-smtbmc processes and their solvers (on Ctrl-C, see _run())."""
    with _groups_lock:
        for group in _groups:
            _kill_group(group)


def _netlist_instances(silver: Path, top: str) -> set[str]:
    """Return the names of the instances in the top-level module of GHDL's Verilog netlist."""
    # GHDL writes one instance per line as '  <module> <instance> (' and the top level last;
    # GHDL 7 puts a '(* src="<file>:<line>" *) ' attribute in front of the module name
    text = silver.read_text()
    start = text.rfind(f"\nmodule {top}")
    return set(re.findall(r'^  (?:\(\* .*?\*\) )?\S+ (\S+) \($', text[start:], re.MULTILINE)) if start >= 0 else set()


def _blackbox_commands(test: EquivTest, design: str, present: set[str] | None) -> list[str]:
    """Return the Yosys commands that replace the blackboxed instances of 'design' (gold or silver)
    by cut points: 'expose -evert' removes each instance and turns its ports into top-level ports
    named <instance>:<port>. The outputs of the instance become inputs, which the gold and silver
    copies share, and its inputs become outputs, which are compared. Only the wiring around the
    instance is proven, its contents are left to the instance's own tests.

    'present' holds the instances of GHDL's netlist; None (the --check listing) assumes all exist.
    """
    if not test.blackbox_instances:
        return []
    commands = []
    if design == "gold":
        # Yosys names cells in generate blocks <scope>.<instance>, GHDL <scope>_<instance>
        commands.append("rename -unescape gold/c:*")
        # 'rename' fails on a missing cell, so only instances that exist in this configuration
        renames = [(vhdl, verilog) for vhdl, verilog in test.blackbox_instances
                   if vhdl != verilog and (present is None or vhdl in present)]
        if renames:
            commands += ["cd gold", *(f"rename {verilog} {vhdl}" for vhdl, verilog in renames), "cd .."]
    # 'expose' ignores selections that match nothing, so instances absent from this configuration are fine.
    # Not the default separator '.': GHDL already names some wires <instance>.<port>.
    commands.append(f"expose -evert -sep {CUT_SEPARATOR} "
                    + " ".join(f"{design}/c:{vhdl}" for vhdl, _ in test.blackbox_instances))
    return commands


def _yosys_script(test: EquivTest, silver: Path, script: Path, smt2: Path | None, vcd: Path | None,
                  present: set[str] | None = None) -> str:
    """Return the Yosys script that builds the miter of the VHDL and Verilog designs, and proves it
    with 'sat' or (smt2 given) exports it for yosys-smtbmc."""
    include = "".join(f"-I{d} " for d in test.include)
    # -show-ports (= -show-inputs -show-outputs) lists the ports of a counterexample in the log.
    # With a VCD dump, -show-all is added, because the dump is believed to contain only the shown
    # signals (not verified without it). Yosys prints and dumps the model only for a counterexample,
    # so this costs nothing on passing proofs.
    show_options = "-show-ports" + (f" -show-all -dump_vcd {vcd}" if vcd else "")
    verilog = " ".join(map(str, test.verilog))
    # e.g. { rst_n = [0, 1] } -> ' -set-at 1 rst_n 0 -set-at 2 rst_n 1'
    reset = "".join(f" -set-at {step} {signal} {value}"
                    for signal, values in test.reset.items()
                    for step, value in enumerate(values, start=1))
    lines = [
        f"# Equivalence check {test.module}/{test.id}, generated by verification/equivlib.",
        f"# Re-run by hand with: yosys -s {script}",
        "",
        "# Reference (gold): the original Verilog implementation",
        *(f"read_verilog -formal {f}" for f in test.blackbox),
        f"read_verilog -formal {include}{verilog}",
        f"rename {test.top} gold",
        *(f"chparam -set {test.generic_map.get(k, k)} {verilog_value(v)} gold" for k, v in test.generics.items()),
        "hierarchy -top gold",
        *_blackbox_commands(test, "gold", present),
        "proc; flatten; memory; async2sync",
        "",
        "# Implementation (silver): the VHDL design, synthesized to Verilog by GHDL",
        f"read_verilog -formal {silver}",
        f"rename {test.top} silver",
        *_blackbox_commands(test, "silver", present),
        "proc; flatten silver; memory; async2sync",
        "",
        "# Build the miter of gold and silver",
        "equiv_make -make_assert gold silver equiv",
        "prep -top equiv",
        "async2sync; opt",
    ]
    if smt2 is None:
        lines += [
            f"# Prove gold and silver equivalent over {test.sat_cycles} cycles",
            # Blackboxes have no definition, so the SAT solver must not fail on unknown cells
            "sat " + ("-ignore-unknown-cells " if test.blackbox else "")
            + f"-seq {test.sat_cycles} -verify -prove-asserts -set-init-zero {show_options}{reset}",
        ]
    else:
        lines += [
            f"# Export the miter for yosys-smtbmc ({test.solver}), which proves it over {test.sat_cycles} cycles",
            # Vendor blackboxes have no definition: their outputs become free values in every cycle,
            # as with 'sat -ignore-unknown-cells' (yosys-smtbmc fails on blackbox cells otherwise)
            *(["cutpoint -blackbox"] if test.blackbox else []),
            # All flip-flops start at zero (= 'sat -set-init-zero'), and constant x bits become 0, which
            # is how 'sat' treats them without -enable_undef
            "setundef -zero -init",
            "dffunmap",
            # -wires: all named wires end up in the counterexample VCD
            f"write_smt2 -wires {smt2}",
        ]
    return "\n".join(lines) + "\n"


def _entity_file_index(test: EquivTest) -> int:
    """Return the index of the VHDL file that declares the top-level entity of a test."""
    # Searched from the end, because the top-level file is usually listed last (after its dependencies)
    pattern = re.compile(rf"^\s*entity\s+{re.escape(test.top)}\s+is\b", re.IGNORECASE | re.MULTILINE)
    for index in reversed(range(len(test.vhdl))):
        if pattern.search(test.vhdl[index].read_text()):
            return index
    raise FlowError(f"entity '{test.top}' not found in the VHDL files of test '{test.name}'")


def _override_generic_default(source: str, entity: str, name: str, value: str) -> str:
    """Replace (or add) the default value of one generic in the declaration of an entity.

    E.g. 'IRQ_INPUTREG_BYPASS : boolean_vector(N - 1 downto 0) := (others => FALSE)' becomes
    'IRQ_INPUTREG_BYPASS : boolean_vector(N - 1 downto 0) := (1 => true, 0 => false)'.
    """
    # Only search after 'entity <name> is', so a component declaration elsewhere is not changed
    start = re.search(rf"^\s*entity\s+{re.escape(entity)}\s+is\b", source, re.IGNORECASE | re.MULTILINE).end()

    # Find 'NAME :' (but not 'NAME :='), skipping matches in comments ('--' earlier on the line).
    # 'declaration' becomes the position right after the colon.
    declaration = None
    for match in re.finditer(rf"\b{re.escape(name)}\s*:(?!=)", source[start:], re.IGNORECASE):
        line_start = source.rfind("\n", 0, start + match.start()) + 1
        if "--" not in source[line_start:start + match.start()]:
            declaration = start + match.end()
            break
    if declaration is None:
        raise FlowError(f"generic '{name}' not found in entity '{entity}'")

    # Scan the subtype indication and the default value up to the ';' or the ')' closing the
    # generic list, skipping over parentheses and comments. 'depth' counts open parentheses, so
    # the ')' of 'boolean_vector(N - 1 downto 0)' is not taken for the end; 'assign' is the
    # position of ':=' if the generic has a default value.
    position, depth, assign = declaration, 0, None
    while position < len(source):
        if source.startswith("--", position):
            position = source.find("\n", position)      # Skip the rest of the comment line
            continue
        char = source[position]
        if char == "(":
            depth += 1
        elif char == ")":
            if depth == 0:
                break
            depth -= 1
        elif char == ";" and depth == 0:
            break
        elif source.startswith(":=", position) and depth == 0 and assign is None:
            assign = position
        position += 1

    # Keep the whitespace (e.g. the newline before ');') between the value and the terminator
    end = position
    while source[end - 1].isspace():
        end -= 1
    # No default value yet: append one; otherwise replace everything from ':=' to the end
    if assign is None:
        return f"{source[:end]} := {value}{source[end:]}"
    return f"{source[:assign]}:= {value}{source[end:]}"
