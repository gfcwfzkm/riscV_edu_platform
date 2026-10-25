# Project memory: index

Notes for AI assistants (and humans) working on this repository. Read this index first, then
only the files relevant to your task. Each file is self-contained.

Repository: an educational RISC-V platform. `hdl/modules/<module>/` holds hardware modules; many
are VHDL ports (`vhdl/`) of Verilog reference designs (`verilog/`), mostly the Hazard3 core.
The VHDL ports are proven equivalent to the Verilog references with formal equivalence checks.

## Files

| File | Read it when you need to |
|---|---|
| [project-decisions.md](project-decisions.md) | know what the maintainer decided and prefers (language, style, how to work). **Read first.** |
| [verification/architecture.md](verification/architecture.md) | understand the equivalence-check tooling: folders, Python modules, data flow |
| [verification/howto.md](verification/howto.md) | run checks, add a test or module, debug a failure, change the tooling (step-by-step recipes) |
| [verification/toml-schema.md](verification/toml-schema.md) | write or review an `equivalence.toml` (every key, value type and rule) |
| [verification/flow-and-toolchain.md](verification/flow-and-toolchain.md) | know the exact GHDL/Yosys commands, generated script, statuses, exit codes, environments |
| [verification/counterexample-analysis.md](verification/counterexample-analysis.md) | work on `--vcd` / `vcd_diff.py`: VCD structure, gold/gate pairing, naming conventions |
| [verification/gotchas.md](verification/gotchas.md) | avoid known pitfalls (bugs found before, tool quirks, long-running tests) |

## Quick facts

- Main entry point: `verification/equiv.py --all` (basic level). Per module: `hdl/modules/<m>/verification/run.py`.
- Python 3.14+, **standard library only**. No pip packages.
- Tests are declared in `hdl/modules/<m>/verification/equivalence.toml` (students edit these).
- Artifacts: `verification/build/<module>/<test id>/`, summary `verification/build/results.csv`.
- Validate without running anything: `--list` (show checks) and `--check` (validate + print commands).
- The legacy script `verification/run_equivalence.fish` still exists and is the reference until the migration is signed off; change it only when the maintainer asks.

## Adding to this memory

- One topic per file; keep files factual and current. Prefer facts, paths and commands over prose.
- Add a row to the table above for every new file.
- When code changes make a note wrong, fix or delete the note in the same change.
- Record *why* for decisions and pitfalls, not only *what*, so later readers can judge edge cases.
- Write dates as absolute dates (e.g. 2026-10-23), never "yesterday" or "last week".
- Don't duplicate what the code or `verification/README.md` already says in detail; link to it and
  record what is non-obvious instead.
