`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/13/2025 09:12:46 PM
// Design Name: 
// Module Name: axi_mm_mac_if
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
module axi_mm_mac_if #(
    parameter integer C_S_AXI_ADDR_WIDTH = 32,
    parameter integer C_S_AXI_DATA_WIDTH = 64,
    parameter integer C_S_AXI_ID_WIDTH   = 6
)(
    // Global Signals
    input  wire                          S_AXI_ACLK,
    input  wire                          S_AXI_ARESETN,

    //=====================================
    // AXI4-Full Slave Interface
    //=====================================
    // Write Address Channel
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
    output reg                           S_AXI_AWREADY,

    // Write Data Channel
    input  wire [C_S_AXI_DATA_WIDTH-1:0] S_AXI_WDATA,
    input  wire [(C_S_AXI_DATA_WIDTH/8)-1:0] S_AXI_WSTRB,
    input  wire                          S_AXI_WLAST,
    input  wire                          S_AXI_WVALID,
    output reg                           S_AXI_WREADY,

    // Write Response Channel
    output reg  [C_S_AXI_ID_WIDTH-1:0]   S_AXI_BID,
    output reg  [1:0]                    S_AXI_BRESP,
    output reg                           S_AXI_BVALID,
    input  wire                          S_AXI_BREADY,

    // Read Address Channel
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
    output reg                           S_AXI_ARREADY,

    // Read Data Channel
    output reg  [C_S_AXI_ID_WIDTH-1:0]   S_AXI_RID,
    output reg  [C_S_AXI_DATA_WIDTH-1:0] S_AXI_RDATA,
    output reg  [1:0]                    S_AXI_RRESP,
    output reg                           S_AXI_RLAST,
    output reg                           S_AXI_RVALID,
    input  wire                          S_AXI_RREADY,

    //=====================================
    // Connection to MultiMode_MAC
    //=====================================
    output reg  [15:0]                   mac_A,
    output reg  [15:0]                   mac_B,
    output reg  [1:0]                    mac_Mode,
    output reg                           mac_Accumulate_Enable,
    output reg                           mac_Clear,

    input  wire [31:0]                   mac_Product,
    input  wire [31:0]                   mac_Accumulator_Out,
    input  wire                          mac_Error_Flag,
    input  wire                          mac_Overflow_Flag
);

    //-------------------------------------------------------------------------
    // 1) Internal Address Offsets and Registers
    //-------------------------------------------------------------------------
    localparam REG_CONTROL      = 8'h00;
    localparam REG_STATUS       = 8'h04;
    localparam REG_OPERAND_A    = 8'h08;
    localparam REG_OPERAND_B    = 8'h0C;
    localparam REG_MODE         = 8'h10;
    localparam REG_ACCUM_EN     = 8'h14;
    localparam REG_CLEAR_ACC    = 8'h18;
    localparam REG_PRODUCT      = 8'h1C;
    localparam REG_ACC_VALUE    = 8'h20;

    // Internal registers to mirror writes
    reg [31:0] r_control;
    reg [31:0] r_operand_a;
    reg [31:0] r_operand_b;
    reg [31:0] r_mode;
    reg [31:0] r_accum_en;
    reg [31:0] r_clear_acc;

    //-------------------------------------------------------------------------
    // 2) Write FSM and Pipelined Write Data Path
    //-------------------------------------------------------------------------
    reg [1:0] wstate;
    localparam W_IDLE = 2'd0,
               W_DATA = 2'd1,
               W_RESP = 2'd2;

    // Latch AW signals and beat counter
    reg [C_S_AXI_ADDR_WIDTH-1:0] awaddr_latched;
    reg [C_S_AXI_ID_WIDTH-1:0]   awid_latched;
    reg [7:0] awlen_latched;
    reg [7:0] write_counter;

    // Pipeline register for next address
    reg [C_S_AXI_ADDR_WIDTH-1:0] awaddr_next;

    // Pipeline registers for write data
    reg [31:0] pipe_wdata;
    reg [7:0]  pipe_addr;
    reg [3:0]  pipe_wstrb;
    reg        write_pipe_valid;

    wire write_fsm_enable = S_AXI_AWVALID || S_AXI_WVALID || (wstate != W_IDLE);

    // ---------------------- Write-FSM ----------------------
    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            wstate         <= W_IDLE;
            S_AXI_AWREADY  <= 1'b0;
            S_AXI_WREADY   <= 1'b0;
            S_AXI_BVALID   <= 1'b0;
            S_AXI_BRESP    <= 2'b00;
            S_AXI_BID      <= {C_S_AXI_ID_WIDTH{1'b0}};
            write_counter  <= 8'd0;
            awaddr_latched <= {C_S_AXI_ADDR_WIDTH{1'b0}};
            awlen_latched  <= 8'd0;
            awid_latched   <= {C_S_AXI_ID_WIDTH{1'b0}};
            awaddr_next    <= {C_S_AXI_ADDR_WIDTH{1'b0}};
        end else if (write_fsm_enable) begin
            case (wstate)
            // ------------------------------------------------
            W_IDLE: begin
                S_AXI_WREADY <= 1'b0;
                S_AXI_BVALID <= 1'b0;
                if (S_AXI_AWVALID) begin
                    S_AXI_AWREADY  <= 1'b1;
                    awaddr_latched <= S_AXI_AWADDR;
                    awid_latched   <= S_AXI_AWID;
                    awlen_latched  <= S_AXI_AWLEN;
                    write_counter  <= 8'd0;
                    awaddr_next    <= S_AXI_AWADDR + (1 << S_AXI_AWSIZE);
                    wstate         <= W_DATA;
                end else
                    S_AXI_AWREADY <= 1'b0;
            end
            // ------------------------------------------------
            W_DATA: begin
                S_AXI_AWREADY <= 1'b0;
                if (S_AXI_WVALID && !write_pipe_valid) begin
                    S_AXI_WREADY <= 1'b1;

                    

                    if (S_AXI_WLAST || (write_counter == awlen_latched)) begin
                        wstate <= W_RESP;
                    end else begin
                        write_counter  <= write_counter + 1;
                        awaddr_latched <= awaddr_next;
                        awaddr_next    <= awaddr_next + (1 << S_AXI_AWSIZE);
                    end
                end else
                    S_AXI_WREADY <= 1'b0;
            end
            // ------------------------------------------------
            W_RESP: begin
                S_AXI_WREADY <= 1'b0;
                S_AXI_BVALID <= 1'b1;
                S_AXI_BRESP  <= 2'b00; 
                S_AXI_BID    <= awid_latched;
                if (S_AXI_BREADY && S_AXI_BVALID) begin
                    S_AXI_BVALID <= 1'b0;
                    wstate       <= W_IDLE;
                end
            end
            // ------------------------------------------------
            default: wstate <= W_IDLE;
            endcase
        end
    end

    // ---------------------- Pipeline stage ----------------------
    wire pipe_data_valid = S_AXI_WVALID && !write_pipe_valid;

    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            write_pipe_valid <= 1'b0;
        end else if (pipe_data_valid) begin
            pipe_wdata       <= S_AXI_WDATA;
            pipe_addr        <= awaddr_latched[7:0];
            pipe_wstrb       <= S_AXI_WSTRB;
            write_pipe_valid <= 1'b1;
        end else if (write_pipe_valid) begin
            case (pipe_addr)
                REG_CONTROL: begin
                    if (pipe_wstrb[0]) r_control[7:0]   <= pipe_wdata[7:0];
                    if (pipe_wstrb[1]) r_control[15:8]  <= pipe_wdata[15:8];
                    if (pipe_wstrb[2]) r_control[23:16] <= pipe_wdata[23:16];
                    if (pipe_wstrb[3]) r_control[31:24] <= pipe_wdata[31:24];
                end
                REG_OPERAND_A: begin
                    if (pipe_wstrb[0]) r_operand_a[7:0]   <= pipe_wdata[7:0];
                    if (pipe_wstrb[1]) r_operand_a[15:8]  <= pipe_wdata[15:8];
                    if (pipe_wstrb[2]) r_operand_a[23:16] <= pipe_wdata[23:16];
                    if (pipe_wstrb[3]) r_operand_a[31:24] <= pipe_wdata[31:24];
                end
                REG_OPERAND_B: begin
                    if (pipe_wstrb[0]) r_operand_b[7:0]   <= pipe_wdata[7:0];
                    if (pipe_wstrb[1]) r_operand_b[15:8]  <= pipe_wdata[15:8];
                    if (pipe_wstrb[2]) r_operand_b[23:16] <= pipe_wdata[23:16];
                    if (pipe_wstrb[3]) r_operand_b[31:24] <= pipe_wdata[31:24];
                end
                REG_MODE: begin
                    if (pipe_wstrb[0]) r_mode[7:0]   <= pipe_wdata[7:0];
                    if (pipe_wstrb[1]) r_mode[15:8]  <= pipe_wdata[15:8];
                    if (pipe_wstrb[2]) r_mode[23:16] <= pipe_wdata[23:16];
                    if (pipe_wstrb[3]) r_mode[31:24] <= pipe_wdata[31:24];
                end
                REG_ACCUM_EN: begin
                    if (pipe_wstrb[0]) r_accum_en[7:0]   <= pipe_wdata[7:0];
                    if (pipe_wstrb[1]) r_accum_en[15:8]  <= pipe_wdata[15:8];
                    if (pipe_wstrb[2]) r_accum_en[23:16] <= pipe_wdata[23:16];
                    if (pipe_wstrb[3]) r_accum_en[31:24] <= pipe_wdata[31:24];
                end
                REG_CLEAR_ACC: begin
                    if (pipe_wstrb[0]) r_clear_acc[7:0]   <= pipe_wdata[7:0];
                    if (pipe_wstrb[1]) r_clear_acc[15:8]  <= pipe_wdata[15:8];
                    if (pipe_wstrb[2]) r_clear_acc[23:16] <= pipe_wdata[23:16];
                    if (pipe_wstrb[3]) r_clear_acc[31:24] <= pipe_wdata[31:24];
                end
                default: ;
            endcase
            write_pipe_valid <= 1'b0;
        end
    end

    //-------------------------------------------------------------------------
    // 3) Read-side FSM 
    //-------------------------------------------------------------------------
    reg [1:0] rstate;
    localparam R_IDLE = 2'd0,
               R_DATA = 2'd1;

    reg [C_S_AXI_ADDR_WIDTH-1:0] araddr_latched;
    reg [C_S_AXI_ID_WIDTH-1:0]   arid_latched;
    reg [7:0] arlen_latched;
    reg [7:0] read_counter;
    reg [C_S_AXI_ADDR_WIDTH-1:0] current_araddr;
    reg [C_S_AXI_ADDR_WIDTH-1:0] araddr_next;

    wire read_fsm_enable = S_AXI_ARVALID || (rstate != R_IDLE);

    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            rstate         <= R_IDLE;
            S_AXI_ARREADY  <= 1'b0;
            S_AXI_RVALID   <= 1'b0;
            S_AXI_RRESP    <= 2'b00;
            S_AXI_RDATA    <= {C_S_AXI_DATA_WIDTH{1'b0}};
            S_AXI_RID      <= {C_S_AXI_ID_WIDTH{1'b0}};
            S_AXI_RLAST    <= 1'b0;
            read_counter   <= 8'd0;
            araddr_latched <= {C_S_AXI_ADDR_WIDTH{1'b0}};
            current_araddr <= {C_S_AXI_ADDR_WIDTH{1'b0}};
            araddr_next    <= {C_S_AXI_ADDR_WIDTH{1'b0}};
        end else if (read_fsm_enable) begin
            case (rstate)
            R_IDLE: begin
                S_AXI_RVALID <= 1'b0;
                S_AXI_RLAST  <= 1'b0;
                if (S_AXI_ARVALID) begin
                    S_AXI_ARREADY  <= 1'b1;
                    araddr_latched <= S_AXI_ARADDR;
                    arid_latched   <= S_AXI_ARID;
                    arlen_latched  <= S_AXI_ARLEN;
                    read_counter   <= 8'd0;
                    current_araddr <= S_AXI_ARADDR;
                    araddr_next    <= S_AXI_ARADDR + (1 << S_AXI_ARSIZE);
                    rstate         <= R_DATA;
                end else
                    S_AXI_ARREADY <= 1'b0;
            end
            R_DATA: begin
                S_AXI_ARREADY <= 1'b0;
                S_AXI_RVALID  <= 1'b1;
                S_AXI_RID     <= arid_latched;
                S_AXI_RDATA   <= axi_read(current_araddr[7:0]);
                S_AXI_RRESP   <= 2'b00;
                if (read_counter == arlen_latched) begin
                    S_AXI_RLAST <= 1'b1;
                    if (S_AXI_RREADY && S_AXI_RVALID) begin
                        S_AXI_RVALID <= 1'b0;
                        S_AXI_RLAST  <= 1'b0;
                        rstate       <= R_IDLE;
                    end
                end else begin
                    S_AXI_RLAST <= 1'b0;
                    if (S_AXI_RREADY && S_AXI_RVALID) begin
                        read_counter   <= read_counter + 1;
                        current_araddr <= araddr_next;
                        araddr_next    <= araddr_next + (1 << S_AXI_ARSIZE);
                    end
                end
            end
            default: rstate <= R_IDLE;
            endcase
        end
    end

    //-------------------------------------------------------------------------
    // 4) Register Read Logic
    //-------------------------------------------------------------------------
    function [31:0] axi_read;
        input [7:0] addr;
        reg [31:0] rdata;
    begin
        case(addr)
            REG_CONTROL:      rdata = r_control;
            REG_STATUS:       rdata = {30'b0, mac_Overflow_Flag, mac_Error_Flag};
            REG_OPERAND_A:    rdata = r_operand_a;
            REG_OPERAND_B:    rdata = r_operand_b;
            REG_MODE:         rdata = r_mode;
            REG_ACCUM_EN:     rdata = r_accum_en;
            REG_CLEAR_ACC:    rdata = r_clear_acc;
            REG_PRODUCT:      rdata = mac_Product;
            REG_ACC_VALUE:    rdata = mac_Accumulator_Out;
            default:          rdata = 32'hDEADBEEF;
        endcase
        axi_read = rdata;
    end
    endfunction

    //-------------------------------------------------------------------------
    // 5) Drive MAC Inputs from Registers
    //-------------------------------------------------------------------------
    reg prev_accum_en;

    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
             mac_A                 <= 16'd0;
             mac_B                 <= 16'd0;
             mac_Mode              <= 2'b00;
             mac_Accumulate_Enable <= 1'b0;
             mac_Clear             <= 1'b0;
             prev_accum_en         <= 1'b0;
             r_control             <= 32'd0;
             r_operand_a           <= 32'd0;
             r_operand_b           <= 32'd0;
             r_mode                <= 32'd0;
             r_accum_en            <= 32'd0;
             r_clear_acc           <= 32'd0;
        end else begin
             mac_A    <= r_operand_a[15:0];
             mac_B    <= r_operand_b[15:0];
             mac_Mode <= r_mode[1:0];

             mac_Accumulate_Enable <= r_accum_en[0] & (~prev_accum_en);
             prev_accum_en <= r_accum_en[0];

             if (r_clear_acc[0]) begin
                  mac_Clear   <= 1'b1;
                  r_clear_acc <= 32'd0;
             end else
                  mac_Clear   <= 1'b0;
        end
    end

endmodule

