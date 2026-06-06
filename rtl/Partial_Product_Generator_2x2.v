`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/21/2024 03:02:37 PM
// Design Name: 
// Module Name: Partial_Product_Generator_2x2
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

module Partial_Product_Generator_2x2 (
    input wire [1:0] A,    // 2-bit multiplicand
    input wire [1:0] B,    // 2-bit multiplier
    output wire PP_0,      // Partial Product 0
    output wire PP_1,      // Partial Product 1
    output wire PP_2,      // Partial Product 2
    output wire PP_3       // Partial Product 3
);
    assign PP_0 = A[0] & B[0]; // LSB of both multiplicand and multiplier
    assign PP_1 = A[0] & B[1]; // LSB of A with MSB of B
    assign PP_2 = A[1] & B[0]; // MSB of A with LSB of B
    assign PP_3 = A[1] & B[1]; // MSB of both multiplicand and multiplier
endmodule