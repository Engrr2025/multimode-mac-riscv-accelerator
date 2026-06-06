`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/21/2024 03:52:34 PM
// Design Name: 
// Module Name: Multiplier_4x4
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
module Multiplier_4x4 (
    input wire [3:0] A,          // 4-bit multiplicand
    input wire [3:0] B,          // 4-bit multiplier
    output wire [7:0] Product    // 8-bit product
);
    wire [3:0] P_HH, P_HL, P_LH, P_LL; // Partial products from 2x2 multipliers
    wire [4:0] RCA_Sum_HL_LH;          // Sum of P_HL and P_LH using RCA_BEC_Adder
    wire Carry_Out_HL_LH;              // Carry-out from RCA_BEC_Adder
    wire [7:0] Aligned_HH, Aligned_HL_LH, Final_Sum; // Aligned partial sums

    // Split inputs into high and low parts
    wire [1:0] A_High = A[3:2];
    wire [1:0] A_Low  = A[1:0];
    wire [1:0] B_High = B[3:2];
    wire [1:0] B_Low  = B[1:0];

    // Instantiate 2x2 multipliers
    Multiplier_2x2 M_HH (.A(A_High), .B(B_High), .Product(P_HH)); // High-High
    Multiplier_2x2 M_HL (.A(A_High), .B(B_Low),  .Product(P_HL)); // High-Low
    Multiplier_2x2 M_LH (.A(A_Low),  .B(B_High), .Product(P_LH)); // Low-High
    Multiplier_2x2 M_LL (.A(A_Low),  .B(B_Low),  .Product(P_LL)); // Low-Low

    // Sum partial products P_HL and P_LH using RCA_BEC_Adder
    RCA_BEC_Adder Adder1 (
        .A(P_HL),
        .B(P_LH),
        .CarryIn(0),
        .Sum(RCA_Sum_HL_LH)     // Output the 5-bit sum
    );

    // Extract the carry-out from the summation
    assign Carry_Out_HL_LH = RCA_Sum_HL_LH[4];

    // Align partial products
    assign Aligned_HH    = {P_HH, 4'b0000};               // Shift P_HH by 4 bits
    assign Aligned_HL_LH = {RCA_Sum_HL_LH[3:0], 2'b00};   // Shift P_HL + P_LH sum by 2 bits

    // Combine aligned partial products and include carry-out
    assign Final_Sum = Aligned_HH + Aligned_HL_LH + P_LL + (Carry_Out_HL_LH << 6); // Properly align carry-out

    // Output the final product
    assign Product = Final_Sum;

endmodule
