# Counterexample analysis (`--vcd`, `vcddiff.py`, `vcd_diff.py`)

When a proof fails and `--vcd` was given, Yosys dumps the counterexample to
`<top>_counterexample.vcd`. `flow._analyze_counterexample` then runs
`vcddiff.analyze()` + `vcddiff.report()` and writes the report to the log and to
`<top>_divergence.txt`. Any exception inside the analysis is caught and written to the log as
"Counterexample analysis failed: ..." so it can never hide the check result.
Standalone: `verification/vcd_diff.py <vcd> [--step N] [--netlist <top>.v]`.

## Facts about the Yosys VCD (verified 2026-10-23 with Yosys 0.63)

- `-dump_vcd` writes a file **only when the proof fails** (it dumps the SAT model = counterexample).
- One flat scope `\equiv`. `equiv_make` merged both designs: every gold signal ends in `_gold`,
  every silver signal in `_gate`. Hierarchy below the top survives only as dotted names after
  `flatten`, e.g. `sync_req.sync_flops_gold`.
- Ports exist on **both** sides (`clk_dst_gold` and `clk_dst_gate`, `dst_prdata_gold` and `_gate`).
  Input copies are always equal.
- Names may carry a slice suffix after the side: `\n125_gate [32_1]` = bits 32..1 of `n125`.
- Yosys-internal nets have `$` and `:` replaced by `_`: `$auto$async2sync.cc:234:execute$129`
  appears as `_auto_async2sync.cc_234_execute_129_gold`; names can contain source paths with dots
  (`_logic_and_/home/.../file.v_119_4_Y`).
- GHDL's anonymous nets are named `n<number>` (gate side only).
- Time axis: `#0` holds the initial values **and** SAT step 1, `#n` is step n for n >= 2, the last
  timestamp has no values and only marks the end. Every timestamp lists all signals.
- With `-show-all` the dump contained all signals (gold, gate and internal). The current code
  always adds `-show-all` together with `-dump_vcd`, because (from memory of the Yosys source,
  **not verified**) the VCD only contains the signals on the `sat` show list. The extra table in
  the log only appears for failing proofs, so passing proofs are not slowed down.

## Naming conventions of the two implementations (survey 2026-10-23)

- VHDL ports: registers mostly end in `_reg` (166 signals); `_next` (17) are next-state signals,
  not registers. Descriptive names are common (`sum_of_a_and_b`, `arithmetic_shift`).
- Hazard3 Verilog: registers often end in `_r` (29), many have no suffix at all (`dst_ack`).
- Instance labels: mostly identical, sometimes only different case (`EIRQ_PRIORITY_U` vs
  `eirq_priority_u`), sometimes different names (`barrel_shifter_instance` vs `shifter`,
  `priority_select_layer` vs `prisel_layer`).

## Pairing algorithm (`vcddiff._pair`)

Only sided signals that are "pairable" take part: no part of the dotted name starts with `_` or
`$` (Yosys internals) and the leaf is not `n<number>` (GHDL anonymous). Paths and leaves are
lower-cased. Key = (instance path, leaf, slice lsb). Within one stage a key that several signals
map to is ambiguous and skipped (`_keyed`). Widths must match.

1. **same name**: identical key.
2. **register naming**: leaf with one trailing `_reg` or `_r` removed (`REGISTER_SUFFIX`).
3. **renamed instance**: `_align_instances` maps every instance path that exists only on the gold
   side to the gate-only path of the same depth sharing the most (suffix-stripped) leaf names,
   greedily, requiring at least `MIN_SHARED_NAMES = 2`. Stages 1 and 2 are then repeated with gold
   paths mapped. Pairs found here are labelled "renamed instance".

Not pairable: descriptive renames (`sum` vs `sum_of_a_and_b`), GHDL anonymous nets, Yosys nets.
The report lists the named unpaired signals of each side so a human can match them.

## Report content (`vcddiff.report`)

1. Header: steps, number of pairs per stage, gold-only/gate-only counts, renamed instances.
2. "First divergence at step S" (or "Differences at step N" with `--step`): table with gold name,
   gate name, values (1 bit as `0/1`, vectors as zero-padded hex, `0b...` if x/z) and differing
   bit indices as ranges (`31:18, 3`, slice offset applied).
3. "First divergence at an output": uses the output ports parsed from GHDL's netlist
   (`module <top>` header up to the first `);`; the netlist file name stem must equal the top name).
4. Timeline: first differing step of every pair, sorted; tags `register naming`,
   `renamed instance`, `output`.
5. Named gold-only / gate-only signals.

The earliest diverging pair is usually closest to the bug; outputs typically diverge later.

## Validated examples (scratch copies, repository untouched)

- `hazard3_apb_async_bridge` with `dst_prdata & dst_pslverr` changed to `dst_prdata & '0'`:
  first divergence step 9 at `dst_prdata_pslverr <-> dst_prdata_pslverr_reg` bit 0, output
  `src_pslverr` at step 12. Also listed the real rename `src_waiting_for_downstream` (gold) vs
  `src_waiting_for_downstream_eg` (gate).
- `hazard3_alu` with `arithmetic_shift` decoded from `SRL` instead of `SRA`: mapped instance
  `shifter` = `barrel_shifter_instance`, first divergence step 6 at `result`, `shifter.dout` (bits
  31:18) and `shifter.arith`.

## Ideas not implemented yet

- Optional per-test `signal_map` in `equivalence.toml` (gold name -> gate name) for descriptive renames.
- GTKWave save file (`.gtkw`) placing each diverging gold/gate pair next to each other.
