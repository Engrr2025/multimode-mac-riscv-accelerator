`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/21/2024 05:42:45 PM
// Design Name: 
// Module Name: RCA_BEC_Adder
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

module RCA_BEC_Adder (
    input wire [3:0] A,           // 4-bit input A
    input wire [3:0] B,           // 4-bit input B
    input wire CarryIn,           // Carry-in signal
    output wire [4:0] Sum         // 5-bit sum output
);
    wire [4:0] RCA_Sum;           // Sum from Ripple Carry Adder
    wire [4:0] BEC_Sum;           // Sum from BEC logic

    // Ripple Carry Adder (RCA) computes sum without CarryIn
    assign RCA_Sum = {1'b0, A} + {1'b0, B} + {4'b0000, CarryIn}; 

    // Binary-to-Excess-1 Converter (BEC) computes sum with CarryIn = 1
    assign BEC_Sum = RCA_Sum + 5'b00001;

    // Select the correct sum based on CarryIn
    assign Sum = (CarryIn) ? BEC_Sum : RCA_Sum;

endmodule
