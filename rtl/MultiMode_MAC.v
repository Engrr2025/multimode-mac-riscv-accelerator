`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/24/2024 07:15:39 PM
// Design Name: 
// Module Name: MultiMode_MAC
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

module MultiMode_MAC (
    input  wire       clk,
    input  wire       rst,
    input  wire [1:0] Mode,
    input  wire [15:0] A,
    input  wire [15:0] B,
    input  wire       Accumulate_Enable,
    input  wire       Clear,
    output wire [31:0] Product,
    output wire [31:0] Accumulator_Out,
    output wire [31:0] Product_2x2_Out,
    output wire [31:0] Product_4x4_Out,
    output wire [31:0] Product_8x8_Out,
    output wire [31:0] Product_16x16_Out,
    output wire       Error_Flag,
    output wire       Overflow_Flag  // Combined overflow flag
);
    wire TS_Overflow_Flag;
    wire Acc_Overflow_Flag;
    
    TaskScheduler ts (
        .A(A),
        .B(B),
        .Mode(Mode),
        .Product(Product),
        .Product_2x2_Out(Product_2x2_Out),
        .Product_4x4_Out(Product_4x4_Out),
        .Product_8x8_Out(Product_8x8_Out),
        .Product_16x16_Out(Product_16x16_Out),
        .Error_Flag(Error_Flag),
        .TS_Overflow_Flag(TS_Overflow_Flag)
    );
    
    Accumulator acc (
        .clk(clk),
        .rst(rst),
        .Clear(Clear),
        .Accumulate_Enable(Accumulate_Enable),
        .Data_In(Product),
        .Accumulator_Out(Accumulator_Out),
        .Acc_Overflow_Flag(Acc_Overflow_Flag)
    );
    
    // Final Overflow flag is asserted if either stage overflows
    assign Overflow_Flag = TS_Overflow_Flag | Acc_Overflow_Flag;
endmodule