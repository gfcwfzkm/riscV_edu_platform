#!/usr/bin/env fish

set script_dir (dirname (status filename))
set repo_root (realpath "$script_dir/..")
set build_dir "$repo_root/verification/build"
set results_file "$build_dir/results.txt"

source /opt/oss-cad-suite/environment.fish

rm -rf $build_dir
mkdir -p $build_dir
printf 'module,status\n' > $results_file

function check_pair
    set -l name $argv[1]
    set -l top $argv[2]
    set -l vhdl_files $argv[3]
    set -l verilog_files $argv[4]
    set -l work_dir "$build_dir/$name/ghdl-work"
    set -l gate_file "$build_dir/$name/$top.v"
    set -l log_file "$build_dir/$name/$top.log"
    set -l vhdl_args (string split ' ' -- $vhdl_files)
    set -l verilog_args (string split ' ' -- $verilog_files)

    mkdir -p "$build_dir/$name"
    mkdir -p $work_dir
    printf '\n=== %s ===\n' $name | tee $log_file

    if not ghdl --synth --std=08 --out=verilog --workdir=$work_dir $vhdl_args -e $top >$gate_file 2>>$log_file
        printf '%s,ghdl-synth-failed\n' $name >> $results_file
        printf 'GHDL synthesis failed: %s\n' $name | tee -a $log_file
        return 1
    end

    set -l yosys_script "read_verilog -sv $verilog_args; rename $top gold; read_verilog -sv $gate_file; rename $top gate; proc; memory; async2sync; equiv_make gold gate equiv; prep -top equiv; equiv_simple -seq 8; equiv_status -assert"
    if not yosys -q -p "$yosys_script" >>$log_file 2>&1
        printf '%s,equivalence-failed\n' $name >> $results_file
        printf 'Equivalence failed: %s\n' $name | tee -a $log_file
        return 1
    end

    printf '%s,proven\n' $name >> $results_file
    printf 'Proven: %s\n' $name | tee -a $log_file
    return 0
end

function check_reset_constrained_pair
    set -l name $argv[1]
    set -l top $argv[2]
    set -l vhdl_file $argv[3]
    set -l verilog_file $argv[4]
    set -l pair_dir "$build_dir/$name"
    set -l work_dir "$pair_dir/ghdl-work"
    set -l gate_file "$pair_dir/$top.v"
    set -l gold_file "$pair_dir/original_named.v"
    set -l gate_named_file "$pair_dir/vhdl_named.v"
    set -l log_file "$pair_dir/$top.log"
    set -l gold_top "$top"_gold
    set -l gate_top "$top"_gate

    mkdir -p $pair_dir $work_dir
    printf '\n=== %s (reset-constrained) ===\n' $name | tee $log_file

    if not ghdl --synth --std=08 --out=verilog --workdir=$work_dir $vhdl_file -e $top >$gate_file 2>>$log_file
        printf '%s,ghdl-synth-failed\n' $name >> $results_file
        printf 'GHDL synthesis failed: %s\n' $name | tee -a $log_file
        return 1
    end

    sed "s/module $top/module $gold_top/" $verilog_file >$gold_file
    sed "s/module $top/module $gate_top/" $gate_file >$gate_named_file
    set -l yosys_script "read_verilog -formal $gold_file $gate_named_file $repo_root/verification/hazard3_sbus_to_ahb_formal.v; prep -top hazard3_sbus_to_ahb_formal; flatten; async2sync; opt; sat -seq 12 -prove mismatch 0 -set-init-zero -set-at 1 rst_n 0 -set-at 2 rst_n 1"
    if not yosys -q -p "$yosys_script" >>$log_file 2>&1
        printf '%s,equivalence-failed\n' $name >> $results_file
        printf 'Reset-constrained equivalence failed: %s\n' $name | tee -a $log_file
        return 1
    end

    printf '%s,proven\n' $name >> $results_file
    printf 'Reset-constrained proof: %s\n' $name | tee -a $log_file
    return 0
end

function check_assert_reset_pair
    set -l name $argv[1]
    set -l top $argv[2]
    set -l vhdl_files $argv[3]
    set -l verilog_files $argv[4]
    set -l reset_constraints $argv[5]
    set -l blackbox_file $argv[6]
    set -l work_dir "$build_dir/$name/ghdl-work"
    set -l gate_file "$build_dir/$name/$top.v"
    set -l log_file "$build_dir/$name/$top.log"
    set -l vhdl_args (string split ' ' -- $vhdl_files)
    set -l verilog_args (string split ' ' -- $verilog_files)

    mkdir -p "$build_dir/$name" $work_dir
    printf '\n=== %s (reset-constrained assertions) ===\n' $name | tee $log_file

    if not ghdl --synth --std=08 --out=verilog --workdir=$work_dir $vhdl_args -e $top >$gate_file 2>>$log_file
        printf '%s,ghdl-synth-failed\n' $name >> $results_file
        printf 'GHDL synthesis failed: %s\n' $name | tee -a $log_file
        return 1
    end

    set -l blackbox_command ''
    set -l sat_options ''
    if test -n "$blackbox_file"
        set blackbox_command "read_verilog -formal $blackbox_file;"
        set sat_options '-ignore-unknown-cells'
    end
    set -l yosys_script "$blackbox_command read_verilog -formal $verilog_args; rename $top gold; read_verilog -formal $gate_file; rename $top gate; proc; memory; async2sync; equiv_make -make_assert gold gate equiv; prep -top equiv; flatten; async2sync; opt; sat $sat_options -seq 12 -prove-asserts -set-init-zero $reset_constraints"
    if not yosys -q -p "$yosys_script" >>$log_file 2>&1
        printf '%s,equivalence-failed\n' $name >> $results_file
        printf 'Reset-constrained equivalence failed: %s\n' $name | tee -a $log_file
        return 1
    end

    printf '%s,proven\n' $name >> $results_file
    printf 'Reset-constrained proof: %s\n' $name | tee -a $log_file
    return 0
end

set failed 0

check_assert_reset_pair hazard3_sync_1bit hazard3_sync_1bit \
    "$repo_root/hdl/modules/debug/vhdl/cdc/hazard3_sync_1bit.vhdl" \
    "$repo_root/hdl/modules/debug/verilog/cdc/hazard3_sync_1bit.v" \
    "-set-at 1 rst_n 0 -set-at 2 rst_n 1"
or set failed 1

check_assert_reset_pair hazard3_reset_sync hazard3_reset_sync \
    "$repo_root/hdl/modules/debug/vhdl/cdc/hazard3_reset_sync.vhdl" \
    "$repo_root/hdl/modules/debug/verilog/cdc/hazard3_reset_sync.v" \
    "-set-at 1 rst_n_in 0 -set-at 2 rst_n_in 1"
or set failed 1

check_assert_reset_pair hazard3_apb_async_bridge hazard3_apb_async_bridge \
    "$repo_root/hdl/modules/debug/vhdl/cdc/hazard3_sync_1bit.vhdl $repo_root/hdl/modules/debug/vhdl/cdc/hazard3_apb_async_bridge.vhdl" \
    "$repo_root/hdl/modules/debug/verilog/cdc/hazard3_sync_1bit.v $repo_root/hdl/modules/debug/verilog/cdc/hazard3_apb_async_bridge.v" \
    "-set-at 1 rst_n_src 0 -set-at 1 rst_n_dst 0 -set-at 2 rst_n_src 1 -set-at 2 rst_n_dst 1"
or set failed 1

# check_reset_constrained_pair hazard3_sbus_to_ahb hazard3_sbus_to_ahb \
check_assert_reset_pair hazard3_sbus_to_ahb hazard3_sbus_to_ahb \
    "$repo_root/hdl/modules/debug/vhdl/dm/hazard3_sbus_to_ahb.vhdl" \
    "$repo_root/hdl/modules/debug/verilog/dm/hazard3_sbus_to_ahb.v"
or set failed 1

check_assert_reset_pair hazard3_dm hazard3_dm \
    "$repo_root/hdl/modules/debug/vhdl/dm/hazard3_dm.vhdl" \
    "$repo_root/hdl/modules/debug/verilog/dm/hazard3_dm.v" \
    "-set-at 1 rst_n 0 -set-at 2 rst_n 1"
or set failed 1

set -l dtm_vhdl "$repo_root/hdl/modules/debug/vhdl/cdc/hazard3_sync_1bit.vhdl $repo_root/hdl/modules/debug/vhdl/cdc/hazard3_apb_async_bridge.vhdl $repo_root/hdl/modules/debug/vhdl/dtm/hazard3_jtag_dtm_core.vhdl"
set -l dtm_verilog "$repo_root/hdl/modules/debug/verilog/cdc/hazard3_sync_1bit.v $repo_root/hdl/modules/debug/verilog/cdc/hazard3_apb_async_bridge.v $repo_root/hdl/modules/debug/verilog/dtm/hazard3_jtag_dtm_core.v"

check_assert_reset_pair hazard3_jtag_dtm_core hazard3_jtag_dtm_core "$dtm_vhdl" "$dtm_verilog" \
    "-set-at 1 trst_n 0 -set-at 1 rst_n_dmi 0 -set-at 2 trst_n 1 -set-at 2 rst_n_dmi 1"
or set failed 1

check_assert_reset_pair hazard3_jtag_dtm hazard3_jtag_dtm \
    "$dtm_vhdl $repo_root/hdl/modules/debug/vhdl/dtm/hazard3_jtag_dtm.vhdl" \
    "$dtm_verilog $repo_root/hdl/modules/debug/verilog/dtm/hazard3_jtag_dtm.v" \
    "-set-at 1 trst_n 0 -set-at 1 rst_n_dmi 0 -set-at 2 trst_n 1 -set-at 2 rst_n_dmi 1"
or set failed 1

check_assert_reset_pair hazard3_ecp5_jtag_dtm hazard3_ecp5_jtag_dtm \
    "$dtm_vhdl $repo_root/hdl/modules/debug/vhdl/dtm/hazard3_ecp5_jtag_dtm.vhdl" \
    "$dtm_verilog $repo_root/hdl/modules/debug/verilog/dtm/hazard3_ecp5_jtag_dtm.v" \
    "-set-at 1 rst_n_dmi 0 -set-at 2 rst_n_dmi 1" \
    "$repo_root/verification/ecp5_jtagg_blackbox.v"
or set failed 1

#check_pair hazard3_xilinx7_jtag_dtm hazard3_xilinx7_jtag_dtm \
#    "$dtm_vhdl $repo_root/hdl/modules/debug/vhdl/dtm/hazard3_xilinx7_jtag_dtm.vhdl" \
#    "$dtm_verilog $repo_root/hdl/modules/debug/verilog/dtm/hazard3_xilinx7_jtag_dtm.v"
#or set failed 1

printf '\nResults: %s\n' $results_file
cat $results_file
exit $failed