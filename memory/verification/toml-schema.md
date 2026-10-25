# `equivalence.toml` schema (as implemented in `verification/equivlib/config.py`)

Location: `hdl/modules/<module>/verification/equivalence.toml`. The module name is the folder name.
Parsed with `tomllib` (TOML 1.0: inline tables must stay on one line, so use `[test.basic]`-style
sub-tables for long tables). Unknown keys anywhere are errors (typos are caught).

## Top level

Allowed top-level keys: `module`, `defaults`, `filesets`, `test`. At least one `[[test]]` is required.

```toml
[module]                      # optional
vhdl_dir    = "vhdl"          # base of all 'vhdl' entries (default "vhdl"), relative to the module folder
verilog_dir = "verilog"       # base of all 'verilog' entries (default "verilog")
include     = ["verilog"]     # Verilog include dirs (-I), relative to the module folder; must exist

[defaults]                    # optional; used by tests that don't set the key themselves
reset      = { rst_n = [0, 1] }
sat_cycles = 12               # default 12 if not given

[filesets.<name>]             # optional, any number
use     = ["other_fileset"]   # filesets this one depends on
vhdl    = ["..."]             # relative to vhdl_dir
verilog = ["..."]             # relative to verilog_dir
```

## `[[test]]` keys

| Key | Type | Default | Notes |
|---|---|---|---|
| `name` | string | required | prefix of the test IDs; also used by `-t` |
| `top` | string | `name` | top entity/module name (same name on both sides) |
| `use` | list of fileset names | `[]` | resolved recursively, used filesets' files first, duplicates removed, cycles are errors |
| `vhdl`, `verilog` | list of strings | `[]` | appended after the `use` files; analysis order = dependencies first |
| `blackbox` | list of strings | `[]` | Verilog stubs, relative to the **module folder**; adds `-ignore-unknown-cells` |
| `reset` | table signal -> list of int | `[defaults].reset` or `{}` | `{ rst = [1, 0] }` = `-set-at 1 rst 1 -set-at 2 rst 0`; `{}` = none (combinational) |
| `sat_cycles` | positive int | `[defaults].sat_cycles` or 12 | `sat -seq N` |
| `generic_map` | table VHDL name -> Verilog name | `{}` | for generics named differently, e.g. `NUMBER_OF_IRQs = "NUM_IRQS"` |
| `basic` | table GENERIC -> value | `{}` | the basic configuration; `{}` = entity/module defaults |
| `extensive.matrix` | table GENERIC -> list of values | none | full cartesian product |
| `extensive.exclude` | list of tables | none | drops matrix entries matching **all** keys of any listed table |
| `extensive.configs` | list of tables | none | hand-picked configurations (`[[test.extensive.configs]]`) |

After resolution a test must have at least one VHDL and one Verilog file.

## Levels

- `basic`: exactly one configuration, `basic`.
- `extensive`: `basic` + matrix product (minus `exclude`) + `configs`, deduplicated by
  `sorted((key, repr(value)))`. Matrix and configs entries do **not** inherit from `basic`;
  generics not listed keep the entity/module default.

## Generic values

| TOML | VHDL (GHDL) | Verilog (chparam) |
|---|---|---|
| `true` / `false` | `-gX=true` / `false` | `1` / `0` |
| integer | as is | as is |
| list of booleans | patched default `(N-1 => v0, ..., 0 => vN-1)` (first element = highest index) | `N'b...` (MSB first) |
| `{ vhdl = "...", verilog = "..." }` | `-gX=<vhdl string>` | `<verilog string>` |

Raw values are passed unchanged. For `std_logic_vector` generics GHDL accepts a plain bit string
without quotes, e.g. `PMP_HARDWIRED = { vhdl = "10", verilog = "2'b10" }` (used by `hazard3_pmp`).

## Test IDs

`<name>` followed by `_<KEY>_<value>` per generic in insertion order; booleans become `1`/`0`,
boolean lists a bit string, raw values their Verilog string; then every run of characters outside
`[A-Za-z0-9_]` becomes `_`. IDs longer than 200 characters are cut and get `_<8 hex sha1>` appended
(directory names are limited to 255 bytes). Example: `hazard3_alu_EXTENSION_A_1`. Duplicate IDs
within a module are an error ("give the test a different name").

Two `[[test]]` entries may share a `name` if their IDs differ, but `-t NAME` then selects both.

## Error messages

All validation errors raise `ConfigError("<manifest path>: <where>: <message>")`, e.g.
`.../equivalence.toml: test 'a': unknown key(s) generics (allowed: ...)`. CLI prints `error: ...`
and exits with 2. TOML syntax errors include line and column from `tomllib`.

## Conventions used in the existing files

- `debug`: no generics, each test has its own `reset`; filesets mirror the instantiation tree.
- `hazard4edu`: `[defaults] reset = { rst_n = [0, 1] }`; combinational tests set `reset = {}`;
  section comments explain what each extensive configuration covers (keep doing that);
  `basic` = `hazard3_config.vh` defaults, except `hazard3_triggers` (debug enabled, otherwise the
  unit is nearly empty) and `hazard3_mul_fast` (`MUL_FAST = true`, it only exists then);
  `hazard3_irq_ctrl`, `hazard3_csr`, `hazard3_frontend`, `hazard3_pmp` use entity defaults as basic.
- `hazard3_alu`, `hazard3_muldiv_seq`, `hazard3_mul_fast` **must** have `basic`: some of their
  VHDL generics have no default value.
