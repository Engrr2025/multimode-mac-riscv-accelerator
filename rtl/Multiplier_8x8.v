`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/24/2024 06:25:26 PM
// Design Name: 
// Module Name: Multiplier_8x8
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


module Multiplier_8x8 (
    input wire [7:0] A,
    input wire [7:0] B,
    output wire [15:0] Product
);
    wire [7:0] P_HH, P_HL, P_LH, P_LL; // Partial products from 4x4 multipliers
    wire [8:0] Sum_HL_LH;              // Sum of P_HL and P_LH using CLA_BEC_Unit
    wire [15:0] Aligned_HH, Aligned_HL_LH, Final_Sum;

    // Split inputs into high and low parts
    wire [3:0] A_High = A[7:4];
    wire [3:0] A_Low  = A[3:0];
    wire [3:0] B_High = B[7:4];
    wire [3:0] B_Low  = B[3:0];

    // Instantiate 4x4 multipliers
    Multiplier_4x4 M_HH (.A(A_High), .B(B_High), .Product(P_HH)); // High-High
    Multiplier_4x4 M_HL (.A(A_High), .B(B_Low),  .Product(P_HL)); // High-Low
    Multiplier_4x4 M_LH (.A(A_Low),  .B(B_High), .Product(P_LH)); // Low-High
    Multiplier_4x4 M_LL (.A(A_Low),  .B(B_Low),  .Product(P_LL)); // Low-Low

    // Sum partial products P_HL and P_LH using CLA_BEC_Unit
    CLA_BEC_Unit #(8) Adder1 (
        .A(P_HL),
        .B(P_LH),
        .Cin(0),
        .Sum(Sum_HL_LH)      // Output the 9-bit sum
    );

    // Align partial products
    assign Aligned_HH    = {P_HH, 8'b0000_0000};         // Shift P_HH by 8 bits
    assign Aligned_HL_LH = {Sum_HL_LH[7:0], 4'b0000};    // Shift P_HL + P_LH sum by 4 bits

    // Combine aligned partial products and include carry-out
    assign Final_Sum = Aligned_HH + Aligned_HL_LH + P_LL + (Sum_HL_LH[8] << 12); // Properly align carry-out

    // Output the final product
    assign Product = Final_Sum;
endmodule


