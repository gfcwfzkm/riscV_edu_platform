# Verification recipes

All commands run from the repository root. They need the OSS CAD Suite (or ghdl/yosys on PATH)
only when checks are actually executed; `--list` and `--check` never run the tools.

## Run checks

```sh
verification/equiv.py --all                                   # every module, basic level
verification/equiv.py debug hazard4edu --level extensive      # sign-off for selected modules
hdl/modules/hazard4edu/verification/run.py -t hazard3_csr     # one test of one module, basic
hdl/modules/hazard4edu/verification/run.py -t hazard3_decode -k U_MODE_1 --level extensive
verification/equiv.py --all --list --level extensive          # what would run, nothing executed
verification/equiv.py --all --check                           # validate TOML + print all commands
```

Before starting anything big, ask the maintainer (see `memory/project-decisions.md`).
`-t` matches the exact `name`; `-k` is a substring of `module/id` (so `-k hazard3_onehot_priority`
also matches `hazard3_onehot_priority_dynamic`; use `-t` for one entity).

## Add a test to an existing module

1. Edit `hdl/modules/<module>/verification/equivalence.toml` (schema: `toml-schema.md`).
2. Add files via an existing fileset (`use = [...]`) or new `vhdl` / `verilog` entries.
3. Set `reset` (or rely on `[defaults]`), `sat_cycles` if 12 is too slow or too short.
4. Give it a `[test.basic]` if the entity has generics without defaults or defaults that may
   differ from the Verilog reference. Add `[test.extensive.matrix]` and/or
   `[[test.extensive.configs]]` with a comment per configuration explaining what it covers.
5. If generics have different names in VHDL and Verilog, add `generic_map`.
6. Validate: `run.py -t <name> --level extensive --list`, then `run.py -t <name> --check`.
7. Run the basic level for that test only: `run.py -t <name>`.

## Add verification to a new module

1. `mkdir hdl/modules/<module>/verification`
2. Copy `hdl/modules/debug/verification/run.py` unchanged (it derives the module from its folder).
   Keep it executable (`chmod +x`).
3. Write `equivalence.toml` (paths are relative to the module folder; `vhdl/` and `verilog/` are the defaults).
4. Vendor primitives (e.g. ECP5 `JTAGG`) need an empty Verilog blackbox module with `(* blackbox *)`,
   stored in the module's `verification/` folder and listed under `blackbox`.
5. `verification/equiv.py --all --list` must now show the module.

## Debug a failing check

1. Rerun only that check with `--vcd`: `run.py -t <name> -k <config part> --vcd`.
2. Read the printed divergence report (also at the end of the log and in `<top>_divergence.txt`):
   the earliest diverging pair points at the bug.
3. Look at another step: `verification/vcd_diff.py <...>_counterexample.vcd --step N`.
4. Open the VCD in GTKWave: compare `<signal>_gold` and `<signal>_gate`.
5. Status `ghdl-synth-failed`: read the GHDL messages at the top of the log.
   Status `killed`: the tool was terminated (by a person or the OOM killer); rerun, nothing was disproven.
   Status `equivalence-failed` without a counterexample: Yosys error, read the end of the log.
6. Rerun the proof by hand: `yosys -s verification/build/<module>/<id>/equivalence.ys`.

## Test the tooling with a deliberately failing design (without touching the repo)

Copy the VHDL file to a scratch directory, break the copy, and run the test object against it:

```python
import sys; sys.path.insert(0, "verification")
from pathlib import Path
from equivlib import config, runner, toolchain
from equivlib.cli import REPO_ROOT
SCRATCH = Path("/path/to/scratch")
test = next(t for t in config.load_module(
    "debug", REPO_ROOT / "hdl/modules/debug/verification/equivalence.toml", "basic")
    if t.name == "hazard3_apb_async_bridge")
test.vhdl[-1] = SCRATCH / "hazard3_apb_async_bridge.vhdl"      # the broken copy
runner.run_tests([test], toolchain.resolve("auto"), SCRATCH / "build", REPO_ROOT,
                 jobs=1, timeout=120, fail_fast=False, dump_vcd=True)
```

Use a separate build root (as above) so `verification/build/results.csv` is not overwritten.
To fake a killed tool: `dataclasses.replace(toolchain, yosys="<script that runs: kill -TERM $$>")`.

## Check parity with the legacy fish script

Used during the migration; the extensive level must contain every check of fish `full` + `default`.
1. Copy `run_equivalence.fish` **into `verification/`** (it resolves paths relative to itself),
   replace the body of `check_assert_reset_pair` with
   `printf "%s|%s|%s\n" $argv[2] "$argv[9]" "$argv[8]"` (top | generics | sat cycles) and remove
   the `source .../environment.fish`, `rm -rf $build_dir`, `deactivate` and `cat $results_file` lines.
2. Run the copy with `full` and `default`, `sort -u` (frontend/pmp appeared in both modes).
3. Normalise both sides to `top|sorted NAME=vhdl_value|cycles` (fish `IRQ_INPUT_BYPASS` is the VHDL
   `IRQ_INPUTREG_BYPASS`; fish `(true,false)` becomes the named aggregate) and compare as multisets.
4. Delete the copy. On 2026-10-23 the only difference was the pmp baseline cycle count.

## Change the tooling

| Change | Where |
|---|---|
| New CLI option | `cli._parser` + pass it through `cli.main`; document in `verification/README.md` |
| New TOML key | add to the `*_KEYS` sets in `config.py`, validate in `_Module`, store in `EquivTest`, document in README + `toml-schema.md` |
| Yosys script / sat flags | `flow._yosys_script` (keep it equivalent to the fish script unless agreed otherwise) |
| New status | `flow.execute`; non-`proven` statuses automatically count as failures in `cli`/`runner` |
| Pairing rules | `vcddiff` constants `REGISTER_SUFFIX`, `MIN_SHARED_NAMES`, `_pairable`, `_pair` |
| Docker | `equivlib/container.py` (run command, `prompt_docker` for auto-fallback, image handling) + `verification/docker/` (Dockerfile, installer) |

After changing code: `python3 verification/equiv.py --all --list --level extensive` (counts),
`--all --check` (plans), and one small real check (e.g. `debug -t hazard3_sync_1bit`, < 1 s).
