module hazard3_sbus_to_ahb_formal (
    input wire clk,
    input wire rst_n,
    input wire [31:0] sbus_addr,
    input wire sbus_write,
    input wire [1:0] sbus_size,
    input wire sbus_vld,
    input wire [31:0] sbus_wdata,
    input wire ahblm_hready,
    input wire ahblm_hresp,
    input wire [31:0] ahblm_hrdata,
    output wire mismatch
);
    wire sbus_rdy_gold;
    wire sbus_err_gold;
    wire [31:0] sbus_rdata_gold;
    wire [31:0] ahblm_haddr_gold;
    wire ahblm_hwrite_gold;
    wire [1:0] ahblm_htrans_gold;
    wire [2:0] ahblm_hsize_gold;
    wire [2:0] ahblm_hburst_gold;
    wire [3:0] ahblm_hprot_gold;
    wire ahblm_hmastlock_gold;
    wire [31:0] ahblm_hwdata_gold;

    wire sbus_rdy_gate;
    wire sbus_err_gate;
    wire [31:0] sbus_rdata_gate;
    wire [31:0] ahblm_haddr_gate;
    wire ahblm_hwrite_gate;
    wire [1:0] ahblm_htrans_gate;
    wire [2:0] ahblm_hsize_gate;
    wire [2:0] ahblm_hburst_gate;
    wire [3:0] ahblm_hprot_gate;
    wire ahblm_hmastlock_gate;
    wire [31:0] ahblm_hwdata_gate;

    assign mismatch = rst_n && (
        (sbus_rdy_gold != sbus_rdy_gate) ||
        (sbus_err_gold != sbus_err_gate) ||
        (sbus_rdata_gold != sbus_rdata_gate) ||
        (ahblm_haddr_gold != ahblm_haddr_gate) ||
        (ahblm_hwrite_gold != ahblm_hwrite_gate) ||
        (ahblm_htrans_gold != ahblm_htrans_gate) ||
        (ahblm_hsize_gold != ahblm_hsize_gate) ||
        (ahblm_hburst_gold != ahblm_hburst_gate) ||
        (ahblm_hprot_gold != ahblm_hprot_gate) ||
        (ahblm_hmastlock_gold != ahblm_hmastlock_gate) ||
        (ahblm_hwdata_gold != ahblm_hwdata_gate));

    hazard3_sbus_to_ahb_gold gold (
        .clk(clk), .rst_n(rst_n), .sbus_addr(sbus_addr), .sbus_write(sbus_write),
        .sbus_size(sbus_size), .sbus_vld(sbus_vld), .sbus_rdy(sbus_rdy_gold),
        .sbus_err(sbus_err_gold), .sbus_wdata(sbus_wdata), .sbus_rdata(sbus_rdata_gold),
        .ahblm_haddr(ahblm_haddr_gold), .ahblm_hwrite(ahblm_hwrite_gold),
        .ahblm_htrans(ahblm_htrans_gold), .ahblm_hsize(ahblm_hsize_gold),
        .ahblm_hburst(ahblm_hburst_gold), .ahblm_hprot(ahblm_hprot_gold),
        .ahblm_hmastlock(ahblm_hmastlock_gold), .ahblm_hready(ahblm_hready),
        .ahblm_hresp(ahblm_hresp), .ahblm_hwdata(ahblm_hwdata_gold),
        .ahblm_hrdata(ahblm_hrdata)
    );

    hazard3_sbus_to_ahb_gate gate (
        .clk(clk), .rst_n(rst_n), .sbus_addr(sbus_addr), .sbus_write(sbus_write),
        .sbus_size(sbus_size), .sbus_vld(sbus_vld), .sbus_rdy(sbus_rdy_gate),
        .sbus_err(sbus_err_gate), .sbus_wdata(sbus_wdata), .sbus_rdata(sbus_rdata_gate),
        .ahblm_haddr(ahblm_haddr_gate), .ahblm_hwrite(ahblm_hwrite_gate),
        .ahblm_htrans(ahblm_htrans_gate), .ahblm_hsize(ahblm_hsize_gate),
        .ahblm_hburst(ahblm_hburst_gate), .ahblm_hprot(ahblm_hprot_gate),
        .ahblm_hmastlock(ahblm_hmastlock_gate), .ahblm_hready(ahblm_hready),
        .ahblm_hresp(ahblm_hresp), .ahblm_hwdata(ahblm_hwdata_gate),
        .ahblm_hrdata(ahblm_hrdata)
    );

endmodule