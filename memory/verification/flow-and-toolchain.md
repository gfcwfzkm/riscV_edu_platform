# Verification flow, toolchain, statuses and exit codes

Code: `verification/equivlib/flow.py`, `toolchain.py`, `cli.py`.

## Commands of one check (`flow.plan` / `flow.execute`)

1. `rm -rf <workdir>`, create `<workdir>/ghdl-work/`, write the patched VHDL copy (if any) and `equivalence.ys`.
2. GHDL (stdout = netlist, stderr -> log):
   ```
   ghdl --synth --std=08 --out=verilog --workdir=<workdir>/ghdl-work -gNAME=VALUE... <vhdl files...> -e <top> > <top>.v
   ```
3. Yosys (stdout + stderr -> log): `yosys -s <workdir>/equivalence.ys`
4. Both run with `cwd=<workdir>`, `stdin=DEVNULL`, the toolchain's `env`, and the remaining part of `--timeout`.

## Generated Yosys script (`flow._yosys_script`)

```
read_verilog -formal <blackbox>                      # one line per blackbox file
read_verilog -formal -I<include>... <verilog files>
rename <top> gold
chparam -set <verilog name> <verilog value> gold     # one line per generic
hierarchy -top gold
proc; flatten; memory; async2sync
read_verilog -formal <workdir>/<top>.v
rename <top> silver
proc; flatten silver; memory; async2sync
equiv_make -make_assert gold silver equiv
prep -top equiv
async2sync; opt
sat [-ignore-unknown-cells] -seq <N> -verify -prove-asserts -set-init-zero -show-ports [-show-all -dump_vcd <vcd>] -set-at <step> <signal> <value>...
```

This is the exact sequence of the legacy fish script (only reformatted), so results are comparable.
`-show-ports` is the same as the fish script's `-show-inputs -show-outputs` (Yosys documents them as
equivalent). `-show-all -dump_vcd` is only added with `--vcd`.

## Array generics (GHDL limitation)

GHDL can't set array generics (e.g. `boolean_vector`) with `-g`. `flow.plan` therefore:
1. finds the VHDL file declaring `entity <top> is` (searching the file list from the end),
2. copies it to `ghdl-work/<stem>.generic.vhdl`, replacing the **default value of that one
   generic** in the entity's generic clause (`_override_generic_default`: skips comments, tracks
   parentheses, stops at `;` or the `)` closing the generic list; adds `:= value` if there was none),
3. uses the copy instead of the original in the GHDL file list.

The value is a named aggregate, e.g. `[false, true, false]` -> `(2 => false, 1 => true, 0 => false)`,
which is also valid for one-element vectors. Scalars and raw `{vhdl, verilog}` values use `-g`.

## Statuses (`flow.execute`, `runner`)

| Status | Meaning |
|---|---|
| `proven` | Yosys exited 0: equivalent for N cycles |
| `ghdl-synth-failed` | GHDL exited > 0 (syntax/elaboration error, unsupported construct, bad generic) |
| `equivalence-failed` | Yosys exited > 0: counterexample found **or** a Yosys error (read the log) |
| `timeout` | `--timeout` exceeded; the process was killed by `subprocess.run` |
| `killed` | GHDL or Yosys ended by a signal (negative return code), e.g. killed by hand or by the OOM killer; nothing was disproven |
| `error` | the plan could not be built (`FlowError`, e.g. top entity not found) or an `OSError` |
| `skipped` | not started because of `--fail-fast` |

## Exit codes (`cli.main`)

`0` all checks `proven` · `1` any other status · `2` usage error, invalid TOML, unknown module or
test name, no tests selected, invalid `--oss-cad-suite` version · `3` toolchain unavailable, Docker
missing, image build or `docker run` failed · `130` Ctrl-C. With `--env docker` the container's exit code is passed on.

## Toolchain selection (`toolchain.resolve`)

| `--env` | Behaviour |
|---|---|
| `native` | `$OSS_CAD_SUITE` or `/opt/oss-cad-suite` must contain `bin/ghdl` and `bin/yosys`. Child env = copy of `os.environ` with `PATH=<root>/bin:<root>/py3bin:$PATH`, `GHDL_PREFIX=<root>/lib/ghdl`, `VERILATOR_ROOT=<root>/share/verilator`, `PYTHONHOME` removed (what `environment.fish` does) |
| `path` | `shutil.which("ghdl")` and `shutil.which("yosys")`, unchanged environment |
| `docker` | not a toolchain: `cli.main` hands over to `container.run` before `resolve` (see below); `resolve("docker")` raises |
| `auto` (default) | `native`, then `path`; if neither is found and the user is running tests (not `--list`/`--check`), prompts to fall back to Docker via `container.prompt_docker()` |

The tools are called by absolute path. The OSS CAD Suite `bin/ghdl` and `bin/yosys` are bash
wrapper scripts that start the real binaries with the suite's own `ld-linux`; that is fine.
Versions (`ghdl --version` first line, `yosys -V`) are printed and written to `build/toolchain.txt`.
Versions in use on 2026-10-23: GHDL 6.0.0, Yosys 0.63+87.

### Docker (`--env docker`, `equivlib/container.py`, implemented 2026-10-23)

- The **whole runner** runs once inside the container (not one container per tool call). `cli.main`
  does the module/test selection (and `--list`/`--check`) on the host first, then calls
  `container.run(argv, module, REPO_ROOT, version, rebuild)`.
- `auto` fallback: when `resolve("auto")` finds no local tools, it calls
  `container.prompt_docker()` before `--list`/`--check` have already exited. If the user accepts,
  `resolve()` returns `None`, and `cli.main()` calls `container.run()` with the same args.
  `--list`/`--check` are handled before `resolve()` is called, so they never trigger the prompt.
- Image `riscv-edu-equiv:oss-cad-suite-<version>`, version = `latest` or `YYYY-MM-DD` (`YYYYMMDD`
  accepted; `--oss-cad-suite`, default `$OSS_CAD_SUITE_VERSION` or `latest`). Built from
  `verification/docker/` if `docker image inspect` fails, or always with `--rebuild-image`
  (`--pull --no-cache`, needed because the build cache can't see that `latest` moved).
- Command: `docker run --rm --init --env TINI_KILL_PROCESS_GROUP=1 --user <uid>:<gid> --volume
  <repo>:<repo> --workdir <repo> <image> python3 <same entry script> <original argv> --env native`.
  The appended `--env native` wins because argparse keeps the last value. No `--tty`: docker's
  signal proxy only works without one. Ctrl-C on the host is caught and ignored while waiting for
  the docker client, which forwards it (killing the client would leave the container running).
- `docker run` exit code 125 (container not started) -> `ContainerError` -> exit 3.
- Image: `python:3.14-slim` (the suite's bundled Python 3.11 is too old: `os.process_cpu_count`
  needs 3.13) + `install_oss_cad_suite.py` unpacking the release to `/opt/oss-cad-suite`, writing
  `RELEASE`; `ENV OSS_CAD_SUITE`, suite `bin/` *appended* to PATH, `PYTHONDONTWRITEBYTECODE`, `PYTHONUNBUFFERED`.
- Releases (checked 2026-10-23): tag `YYYY-MM-DD`, daily; asset
  `oss-cad-suite-linux-{x64,arm64}-YYYYMMDD.tgz`, ~750 MB, 2.4 GB unpacked. `latest` is resolved via
  the redirect of `https://github.com/YosysHQ/oss-cad-suite-build/releases/latest` (HEAD request, no API rate limit).
- Tested with a fake `docker` script on PATH (commands, build-if-missing, rebuild flags, errors);
  the TINI_KILL_PROCESS_GROUP behaviour is taken from tini's documentation, not tested here.

## CLI options (`cli._parser`)

`MODULE...` / `--all` (top-level only), `--level basic|extensive` (default basic),
`-j/--jobs N` (default `threads - max(1, threads // 6)` with `os.process_cpu_count()`),
`-t/--test NAME` (exact test name, repeatable; unknown name -> exit 2), `-k PATTERN` (substring,
or glob if it contains `*?[`, matched against `module/id`, repeatable = OR), `--list`, `--check`,
`--vcd`, `--fail-fast`, `--timeout SECONDS`, `--env`, `--oss-cad-suite VERSION` and
`--rebuild-image` (both only with `--env docker`). `-t` is applied before `-k`.
`--list` and `--check` never start GHDL or Yosys and need no toolchain.

## Console output on failure (`runner._report_failure`)

Status and log path, then either the first 25 lines of `<top>_divergence.txt` (if it exists) or
the last 15 lines of the log, then the VCD path (if it exists).

## Typical run times (24-thread workstation, 2026-10-23)

- `--all` basic, 23 checks: about 35 s wall time; slowest is `hazard3_frontend` (~35 s), then `hazard3_csr` (~19 s).
- `--all --level extensive` at the time had 1085 checks and took 3148 s (~52 min) on 24 workers:
  1078 proven; seven csr/pmp configurations were still solving after ~39 minutes and were killed
  by the maintainer (they are covered by the legacy fish script; pmp then ran with
  `sat_cycles = 8`, it has since been reduced to 5).
- `hazard3_decode`: 12-16 s per configuration when run in parallel. Its extensive level was reduced
  from the full 2^10 = 1024 product to 20 checks on 2026-10-23 (see `gotchas.md`, "Coverage instead
  of products"); all 20 proven in 16 s wall time (~4.7 min CPU) on 24 threads.
