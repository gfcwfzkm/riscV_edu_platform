# Verification tooling: architecture

Formal equivalence checking of VHDL ports against their Verilog references. Per check:
GHDL synthesizes the VHDL into a Verilog netlist (*silver*, called *gate* by Yosys), Yosys reads
the reference Verilog (*gold*), builds a miter with `equiv_make` and proves with `sat -seq N` that
all outputs are equal for N clock cycles after a reset sequence.

User documentation: `verification/README.md`. This file explains the code.

## Folder layout

```
verification/
  equiv.py                 entry point: all/several modules (imports equivlib.cli.main)
  vcd_diff.py              standalone counterexample analysis (imports equivlib.vcddiff)
  equivlib/                the implementation (package)
    __init__.py            docstring only
    cli.py                 argument parsing, module/test selection, --list/--check, exit codes
    config.py              discovery + loading/validation/expansion of equivalence.toml -> EquivTest
    flow.py                one check: Plan (paths, GHDL args, Yosys script) and execute()
    runner.py              parallel execution, progress output, failure reports, results.csv
    toolchain.py           where ghdl/yosys come from (native OSS CAD Suite, PATH)
    container.py           --env docker: build the image if needed, rerun the runner inside it
    vcddiff.py             VCD parser, gold/gate pairing, divergence report
  docker/                  Dockerfile, install_oss_cad_suite.py, README (image for --env docker)
  build/                   gitignored artifacts (see below)
  run_equivalence.fish     LEGACY, keep unchanged until migration sign-off
  ecp5_jtagg_blackbox.v    used by the fish script; a copy lives in hdl/modules/debug/verification/
  README.md                user documentation (options, TOML format, debugging)

hdl/modules/<module>/verification/
  equivalence.toml         the module's tests (see toml-schema.md)
  run.py                   identical 13-line launcher in every module
  (optional support files, e.g. debug/verification/ecp5_jtagg_blackbox.v)
```

Modules with checks (2026-10-23): `debug` (7 tests) and `hazard4edu` (16 tests). Count:
`verification/equiv.py --all --list` (basic) / `--level extensive --list`.

## Entry points

- `verification/equiv.py`: `sys.exit(main())`. Python puts the script's directory on `sys.path`,
  so `import equivlib` works from any working directory.
- `hdl/modules/<m>/verification/run.py`: inserts `HERE.parents[3] / "verification"` into
  `sys.path` (HERE = the module's verification folder, parents[3] = repo root) and calls
  `main(module=HERE.parent.name)`. With `module` set, the parser has no MODULE/--all arguments.
- `verification/vcd_diff.py <vcd> [--step N] [--netlist FILE]`: report for an existing VCD.

`cli.REPO_ROOT = Path(cli.py).resolve().parents[2]`, `cli.BUILD_ROOT = REPO_ROOT / "verification/build"`.

## Data flow

```
cli.main(argv, module)
  ├─ config.discover(REPO_ROOT)            glob hdl/modules/*/verification/equivalence.toml -> {module: path}
  ├─ config.load_module(name, path, level) -> list[EquivTest]   (raises ConfigError -> exit 2)
  ├─ filter: -t NAME (exact test name), then -k PATTERN (substring/glob on "module/id")
  ├─ --list -> print ids;  --check -> flow.plan() per test, print commands  (no toolchain needed)
  ├─ --env docker -> container.run() (reruns this program inside container with --env native)
  ├─ toolchain.resolve(--env)              -> Toolchain | None (auto: may return None if user accepts docker fallback)
  ├─ if None -> container.run() (same as --env docker block)
  └─ runner.run_tests(tests, toolchain, BUILD_ROOT, REPO_ROOT, jobs, timeout, fail_fast, dump_vcd)
       └─ per test, in a worker thread:
            flow.plan(test, build_root, dump_vcd) -> Plan
            flow.execute(plan, toolchain, timeout) -> status string
              ├─ ghdl --synth ... > <top>.v
              ├─ yosys -s equivalence.ys >> <top>.log
              └─ on failure with --vcd: vcddiff.analyze() + report() -> log and <top>_divergence.txt
```

## Key types

- `config.EquivTest` (dataclass): `module, id, name, top, vhdl, verilog, include, blackbox,
  reset, sat_cycles, generics, generic_map`. One instance = one design in one generic
  configuration. All paths are absolute and resolved; files are checked to exist at load time.
- `flow.Plan`: `test, workdir, ghdl_args, vhdl_override, silver, script, script_text, log, vcd, divergence`.
  `vcd`/`divergence` are `None` unless `--vcd`.
- `runner.Result`: `test, status, seconds, plan`.
- `toolchain.Toolchain`: `name, description, ghdl, yosys (absolute paths), env (dict)`.
- `toolchain.resolve()`: returns `Toolchain` for `native`/`path`, `None` for `auto` with accepted
  docker fallback (signals `cli.main` to call `container.run()`), raises `ToolchainError` for
  `docker` (guard) or when no toolchain is found.
- `vcddiff.Signal`, `vcddiff.Pair`, `vcddiff.Analysis`.

## Build artifacts

`verification/build/<module>/<test id>/`:

| File | Content |
|---|---|
| `ghdl-work/` | GHDL work library; also `<file>.generic.vhdl` if array generics were patched |
| `<top>.v` | GHDL's Verilog netlist of the VHDL design (silver) |
| `equivalence.ys` | generated Yosys script; rerun by hand with `yosys -s equivalence.ys` |
| `<top>.log` | commands, GHDL stderr, full Yosys output, kill/timeout notes, divergence report |
| `<top>_counterexample.vcd` | only with `--vcd` and only if the proof failed |
| `<top>_divergence.txt` | only with `--vcd` and only if the proof failed |

`verification/build/results.csv` (columns `module,test,status,seconds,log`) and
`verification/build/toolchain.txt` describe the last run only. A run deletes only the directories
of the checks it runs (`shutil.rmtree(plan.workdir)` in `flow.execute`).

## Concurrency model

`ThreadPoolExecutor(max_workers=jobs)`; threads only wait on `subprocess.run`, so the GIL is not a
bottleneck. Every check has its own work directory, so checks can't interfere. Only the main
thread prints and writes `results.csv` (no locks needed). `--fail-fast` sets a `threading.Event`;
queued checks then return status `skipped` (not printed per check). Ctrl-C cancels queued futures,
running tools receive SIGINT from the terminal, `main` returns 130.
