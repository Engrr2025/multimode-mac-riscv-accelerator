`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/21/2024 03:17:36 PM
// Design Name: 
// Module Name: Multiplier_2x2
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


module Multiplier_2x2 (
    input wire [1:0] A,          // 2-bit multiplicand
    input wire [1:0] B,          // 2-bit multiplier
    output wire [3:0] Product    // 4-bit product
);
    wire PP_0, PP_1, PP_2, PP_3; // Partial products

    Partial_Product_Generator_2x2 PPG (
        .A(A),
        .B(B),
        .PP_0(PP_0),
        .PP_1(PP_1),
        .PP_2(PP_2),
        .PP_3(PP_3)
    );

    // Align and sum partial products
    assign Product = (PP_0) + (PP_1 << 1) + (PP_2 << 1) + (PP_3 << 2);

endmodule
