# Verification pitfalls and lessons learned

Each entry: what happens, why, and what to do.

## Tooling bugs found and fixed (2026-10-23)

- **Empty `matrix` produced one extra check.** `itertools.product()` with no iterables yields one
  empty tuple, so tests without a matrix got an extra no-generics configuration at the extensive
  level. Fixed in `config._configurations` (`... if matrix else ()`). Watch for this pattern.
- **Killed tools were reported as `equivalence-failed`.** `subprocess` returns a negative code for
  signals. Now `flow._killed` maps negative codes to status `killed` and logs the signal name.
- **Yosys internal nets looked like named signals in the diff.** The VCD writer turns `$` into `_`
  and names contain file paths with dots, so the dotted-name split put them in fake instances.
  `vcddiff._pairable` now rejects names where *any* dotted part starts with `_` or `$`.

## Tool behaviour

- `sat -show-ports` = `-show-inputs -show-outputs` (Yosys help). There is no separate option in
  the runner for more `-show-*` flags; the maintainer decided against it.
- `sat -dump_vcd` writes nothing for a passing proof.
- GHDL `-g` accepts scalars and plain bit strings for `std_logic_vector` (no quotes), but not
  aggregates for array generics such as `boolean_vector` -> the runner patches the default value
  in a copy of the top-level file (see `flow-and-toolchain.md`).
- VHDL and Verilog defaults can differ (and some VHDL generics have no default). An empty `basic`
  relies on both sides having the same defaults.
- `verilog/hazard3_config.vh` holds the Hazard3 parameter defaults; the VHDL entities declare their own.

## Coverage instead of products

- Generics that only switch independent parts of a design need each value once, not the full
  cartesian product. `hazard3_decode` (2026-10-23): the matrix covers only the interacting
  generics (`CSR_M_MANDATORY`/`CSR_M_TRAP`/`CSR_COUNTER` form `HAVE_CSR`, `U_MODE` matters only with
  it), three configs cover the rest (A/C/E/M off, debug, branch predictor, nonzero `RESET_VECTOR`,
  `EXTENSION_E` with and without A/M). Read the HDL for real interactions before adding a matrix.
- `basic` is not deduplicated against a matrix entry that sets fewer keys, even when the effective
  generics are the same (decode: basic equals one matrix entry), so expect one redundant check.

## Long-running checks

- Extensive `hazard3_csr` configurations 3 and 5 (with PMP) and several `hazard3_pmp`
  configurations needed more than 39 minutes each at the time; the maintainer terminated them
  because the legacy fish script already covers them. Don't start them casually.
- `hazard3_pmp` now uses `sat_cycles = 5`: enough to write pmpaddr/pmpcfg after reset and query;
  longer runs took minutes per configuration without reaching more state.
- `--timeout SECONDS` limits each check; such checks end with status `timeout`.

## Environment

- The assistant's shell tool may be **zsh**, not bash: unquoted `$var` is not word-split (pass
  options literally, not via a variable), and a word like `===` can fail. The user's shell is fish.
- The machine is the maintainer's workstation; the default `-j` already leaves threads free, but
  large runs still slow it down. Ask first.
- `verification/build/` is wiped per check directory only; `results.csv` describes only the last run.

## Legacy fish script

- `verification/run_equivalence.fish` is still the reference until the maintainer signs off the
  migration. Change it only when the maintainer asks (on 2026-10-23 they allowed replacing the
  decode loop and adding a `RESET_VECTOR` bit-string special case to its generic handling). It references `verification/ecp5_jtagg_blackbox.v` (a copy exists in
  `hdl/modules/debug/verification/`); delete both originals only when the fish script goes.
- The maintainer keeps adding checks to the fish script (e.g. `hazard3_pmp`, frontend moved from
  `default` to `full`); when porting, compare against its current content, not an old copy.
- The fish `default` mode was a scratch slot for current work; the replacement is `-t NAME` / `-k`.
