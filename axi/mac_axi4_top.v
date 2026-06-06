`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/13/2025 08:51:52 PM
// Design Name: 
// Module Name: mac_axi4_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`default_nettype none
module mac_axi4_top #(
    parameter integer C_S_AXI_ADDR_WIDTH = 32,
    parameter integer C_S_AXI_DATA_WIDTH = 64,
    parameter integer C_S_AXI_ID_WIDTH   = 6
)(
    // Global AXI signals
    input  wire                          S_AXI_ACLK,
    input  wire                          S_AXI_ARESETN,

    // AXI4-Full Slave Interface
    input  wire [C_S_AXI_ID_WIDTH-1:0]   S_AXI_AWID,
    input  wire [C_S_AXI_ADDR_WIDTH-1:0] S_AXI_AWADDR,
    input  wire [7:0]                    S_AXI_AWLEN,
    input  wire [2:0]                    S_AXI_AWSIZE,
    input  wire [1:0]                    S_AXI_AWBURST,
    input  wire                          S_AXI_AWLOCK,
    input  wire [3:0]                    S_AXI_AWCACHE,
    input  wire [2:0]                    S_AXI_AWPROT,
    input  wire [3:0]                    S_AXI_AWQOS,
    input  wire                          S_AXI_AWVALID,
    output wire                          S_AXI_AWREADY,

    input  wire [C_S_AXI_DATA_WIDTH-1:0] S_AXI_WDATA,
    input  wire [(C_S_AXI_DATA_WIDTH/8)-1:0] S_AXI_WSTRB,
    input  wire                          S_AXI_WLAST,
    input  wire                          S_AXI_WVALID,
    output wire                          S_AXI_WREADY,

    output wire [C_S_AXI_ID_WIDTH-1:0]   S_AXI_BID,
    output wire [1:0]                    S_AXI_BRESP,
    output wire                          S_AXI_BVALID,
    input  wire                          S_AXI_BREADY,

    input  wire [C_S_AXI_ID_WIDTH-1:0]   S_AXI_ARID,
    input  wire [C_S_AXI_ADDR_WIDTH-1:0] S_AXI_ARADDR,
    input  wire [7:0]                    S_AXI_ARLEN,
    input  wire [2:0]                    S_AXI_ARSIZE,
    input  wire [1:0]                    S_AXI_ARBURST,
    input  wire                          S_AXI_ARLOCK,
    input  wire [3:0]                    S_AXI_ARCACHE,
    input  wire [2:0]                    S_AXI_ARPROT,
    input  wire [3:0]                    S_AXI_ARQOS,
    input  wire                          S_AXI_ARVALID,
    output wire                          S_AXI_ARREADY,

    output wire [C_S_AXI_ID_WIDTH-1:0]   S_AXI_RID,
    output wire [C_S_AXI_DATA_WIDTH-1:0] S_AXI_RDATA,
    output wire [1:0]                    S_AXI_RRESP,
    output wire                          S_AXI_RLAST,
    output wire                          S_AXI_RVALID,
    input  wire                          S_AXI_RREADY
);

    // -------------------------------------------------------------------
    // Interconnect signals between AXI wrapper and MultiMode_MAC
    // -------------------------------------------------------------------
    wire [15:0] mac_A;
    wire [15:0] mac_B;
    wire [1:0]  mac_Mode;
    wire        mac_Accumulate_Enable;
    wire        mac_Clear;
    wire [31:0] mac_Product;
    wire [31:0] mac_Accumulator_Out;
    wire        mac_Error_Flag;
    wire        mac_Overflow_Flag;

    // -------------------------------------------------------------------
    //  AXI-slave wrapper for the MAC
    // -------------------------------------------------------------------
    axi_mm_mac_if #(
        .C_S_AXI_ADDR_WIDTH (C_S_AXI_ADDR_WIDTH),
        .C_S_AXI_DATA_WIDTH (C_S_AXI_DATA_WIDTH),
        .C_S_AXI_ID_WIDTH   (C_S_AXI_ID_WIDTH)
    ) u_axi_if (
        .S_AXI_ACLK         (S_AXI_ACLK),
        .S_AXI_ARESETN      (S_AXI_ARESETN),

        // Write Address
        .S_AXI_AWID         (S_AXI_AWID),
        .S_AXI_AWADDR       (S_AXI_AWADDR),
        .S_AXI_AWLEN        (S_AXI_AWLEN),
        .S_AXI_AWSIZE       (S_AXI_AWSIZE),
        .S_AXI_AWBURST      (S_AXI_AWBURST),
        .S_AXI_AWLOCK       (S_AXI_AWLOCK),
        .S_AXI_AWCACHE      (S_AXI_AWCACHE),
        .S_AXI_AWPROT       (S_AXI_AWPROT),
        .S_AXI_AWQOS        (S_AXI_AWQOS),
        .S_AXI_AWVALID      (S_AXI_AWVALID),
        .S_AXI_AWREADY      (S_AXI_AWREADY),

        // Write Data
        .S_AXI_WDATA        (S_AXI_WDATA),
        .S_AXI_WSTRB        (S_AXI_WSTRB),
        .S_AXI_WLAST        (S_AXI_WLAST),
        .S_AXI_WVALID       (S_AXI_WVALID),
        .S_AXI_WREADY       (S_AXI_WREADY),

        // Write Response
        .S_AXI_BID          (S_AXI_BID),
        .S_AXI_BRESP        (S_AXI_BRESP),
        .S_AXI_BVALID       (S_AXI_BVALID),
        .S_AXI_BREADY       (S_AXI_BREADY),

        // Read Address
        .S_AXI_ARID         (S_AXI_ARID),
        .S_AXI_ARADDR       (S_AXI_ARADDR),
        .S_AXI_ARLEN        (S_AXI_ARLEN),
        .S_AXI_ARSIZE       (S_AXI_ARSIZE),
        .S_AXI_ARBURST      (S_AXI_ARBURST),
        .S_AXI_ARLOCK       (S_AXI_ARLOCK),
        .S_AXI_ARCACHE      (S_AXI_ARCACHE),
        .S_AXI_ARPROT       (S_AXI_ARPROT),
        .S_AXI_ARQOS        (S_AXI_ARQOS),
        .S_AXI_ARVALID      (S_AXI_ARVALID),
        .S_AXI_ARREADY      (S_AXI_ARREADY),

        // Read Data
        .S_AXI_RID          (S_AXI_RID),
        .S_AXI_RDATA        (S_AXI_RDATA),
        .S_AXI_RRESP        (S_AXI_RRESP),
        .S_AXI_RLAST        (S_AXI_RLAST),
        .S_AXI_RVALID       (S_AXI_RVALID),
        .S_AXI_RREADY       (S_AXI_RREADY),

        // MAC-side connections
        .mac_A              (mac_A),
        .mac_B              (mac_B),
        .mac_Mode           (mac_Mode),
        .mac_Accumulate_Enable (mac_Accumulate_Enable),
        .mac_Clear          (mac_Clear),
        .mac_Product        (mac_Product),
        .mac_Accumulator_Out(mac_Accumulator_Out),
        .mac_Error_Flag     (mac_Error_Flag),
        .mac_Overflow_Flag  (mac_Overflow_Flag)
    );

    // -------------------------------------------------------------------
    // MultiMode_MAC core 
    // -------------------------------------------------------------------
    MultiMode_MAC u_multimode_mac (
        .clk                (S_AXI_ACLK),
        .rst                (~S_AXI_ARESETN),

        .Mode               (mac_Mode),
        .A                  (mac_A),
        .B                  (mac_B),
        .Accumulate_Enable  (mac_Accumulate_Enable),
        .Clear              (mac_Clear),

        .Product            (mac_Product),
        .Accumulator_Out    (mac_Accumulator_Out),
        .Product_2x2_Out    (/* unused */),
        .Product_4x4_Out    (/* unused */),
        .Product_8x8_Out    (/* unused */),
        .Product_16x16_Out  (/* unused */),

        .Error_Flag         (mac_Error_Flag),
        .Overflow_Flag      (mac_Overflow_Flag)
    );

endmodule
