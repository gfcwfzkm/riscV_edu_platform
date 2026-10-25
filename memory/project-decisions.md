# Maintainer decisions and working preferences

Decisions taken with the maintainer on 2026-10-23 while replacing `verification/run_equivalence.fish`
with the Python tooling. Follow them unless the maintainer says otherwise.

## Technical decisions

| Decision | Why |
|---|---|
| Python 3.14 or newer, standard library only (no pytest, no pip packages) | Runs anywhere the OSS CAD Suite runs; nothing to install for students |
| Tests are declared in TOML (`equivalence.toml`), not in Python | Students can add configurations without programming |
| Each verified module has its own `hdl/modules/<module>/verification/` folder | Tests live next to the design they verify |
| Shared code, entry point and build artifacts stay in `/verification` | One implementation, one place for results |
| Module launchers (`run.py`) test only their module; `verification/equiv.py MODULE... / --all` tests several or all | Fast feedback while developing, full run for sign-off and CI |
| Two levels: `basic` (one configuration per test) and `extensive` (all listed configurations) | Quick check vs. sign-off |
| `basic` uses explicit generics where sensible (mostly the defaults of `verilog/hazard3_config.vh`); entity defaults are acceptable but considered a bit risky | VHDL and Verilog defaults can drift apart; some VHDL generics have no default at all |
| The fish script stays the reference until the migration is finished; edit it only when asked (2026-10-23: decode loop reduced on request) | It is the reference for the parity check and still used |
| Docker (`--env docker`) runs the whole runner in a `python:3.14-slim` + OSS CAD Suite image; the suite version is `latest` or a pinned date (`--oss-cad-suite`, `$OSS_CAD_SUITE_VERSION`); `--env auto` never falls back to Docker | Machines without a local suite and CI; pinning gives reproducible sign-off; a missing toolchain should give a clear error, not an unexpected 750 MB download |
| Default parallelism leaves CPU threads free: `threads - max(1, threads // 6)` (24 -> 20, 8 -> 7) | The workstation must stay usable during runs |
| No `--show` option for Yosys `-show-*` flags; instead `--vcd` dumps the counterexample (with all signals) and runs the gold/gate diff automatically | A waveform plus a diff report is more useful than huge text logs |

## How to work with this maintainer

- **Plan before applying** when asked for analysis or proposals: propose, list open decisions, don't edit files until told to.
- **Don't make assumptions**: ask about real decisions; state uncertainty explicitly (e.g. "I believe Yosys does X, not verified").
- **The machine is the maintainer's workstation.** Don't start large check runs (especially `--level extensive`) without being asked, and never while another run is going. Validate with `--list` / `--check` instead; for real runs prefer `-t NAME` with the basic level.
- Some extensive checks run for 40+ minutes (csr and pmp configurations). The maintainer may terminate them; such checks end with status `killed`, which is not an equivalence failure.
- To test the tooling against a failing design, copy the VHDL file to a scratch location, break the copy, and point an `EquivTest` at it (see [verification/howto.md](verification/howto.md)). Never break files in the repository.
- Code style: match the surrounding code; short docstrings, comments only where the *why* is not obvious.
