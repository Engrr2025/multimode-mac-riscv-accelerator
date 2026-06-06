`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/24/2024 06:44:09 PM
// Design Name: 
// Module Name: Multiplier_16x16
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

//-----------------------
// 16x16 Multiplier (Corrected)
//-----------------------
module Multiplier_16x16 (
    input  wire [15:0] A,            // 16-bit multiplicand
    input  wire [15:0] B,            // 16-bit multiplier
    output wire [31:0] Product,      // 32-bit product (lower part)
    output wire        Overflow      // Overflow flag (true if product exceeds 32 bits)
);
    wire [15:0] P_HH, P_HL, P_LH, P_LL;
    wire [16:0] Sum_HL_LH; // 17-bit result from adding two 8x8 products

    // Split A and B into high and low 8-bit parts
    wire [7:0] A_High = A[15:8];
    wire [7:0] A_Low  = A[7:0];
    wire [7:0] B_High = B[15:8];
    wire [7:0] B_Low  = B[7:0];

    // Instantiate four 8x8 multipliers
    Multiplier_8x8 M_HH (.A(A_High), .B(B_High), .Product(P_HH));
    Multiplier_8x8 M_HL (.A(A_High), .B(B_Low),  .Product(P_HL));
    Multiplier_8x8 M_LH (.A(A_Low),  .B(B_High), .Product(P_LH));
    Multiplier_8x8 M_LL (.A(A_Low),  .B(B_Low),  .Product(P_LL));

    // Add the two middle partial products using a CLA_BEC adder.
    CLA_BEC_Unit #(16) Adder1 (
        .A(P_HL),
        .B(P_LH),
        .Cin(1'b0),
        .Sum(Sum_HL_LH)
    );

    // Align partial products:
    // - High part shifted left by 16 bits.
    // - Middle term shifted left by 8 bits.
    // - Low part remains unshifted.
    wire [32:0] Aligned_HH = {P_HH, 16'b0}; // 33-bit: P_HH << 16
    wire [32:0] Aligned_LL = {16'b0, P_LL};    // 33-bit: P_LL
    // Extend Sum_HL_LH to 32-bits and shift left by 8.
    wire [32:0] Middle     = {15'b0, Sum_HL_LH} << 8; // (Sum_HL_LH * 256)

    wire [32:0] Final_Sum  = Aligned_HH + Middle + Aligned_LL;
    assign Product  = Final_Sum[31:0];
    assign Overflow = Final_Sum[32];
endmodule
