`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/22/2024 05:54:59 PM
// Design Name: 
// Module Name: CLA_BEC_Unit
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


module CLA_BEC_Unit #(parameter WIDTH = 16) (
    input wire [WIDTH-1:0] A,          // Input operand A
    input wire [WIDTH-1:0] B,          // Input operand B
    input wire Cin,                    // Carry-in
    output wire [WIDTH:0] Sum          // Sum output (WIDTH+1 to account for carry-out)
);
    wire [WIDTH:0] CLA_Sum;            // Sum from Carry Lookahead Adder
    wire [WIDTH:0] BEC_Sum;            // Sum from Binary-to-Excess-1 Converter

    // Carry Lookahead Adder (CLA) computes sum for Cin = 0
    CLA #(WIDTH) cla_inst (
        .A(A),
        .B(B),
        .Cin(0),
        .Sum(CLA_Sum)
    );

    // Binary-to-Excess-1 Converter (BEC) computes sum for Cin = 1
    assign BEC_Sum = CLA_Sum + 1;

    // Select the correct sum based on Carry-in (Cin)
    assign Sum = (Cin) ? BEC_Sum : CLA_Sum;

endmodule