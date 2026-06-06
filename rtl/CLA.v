`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/22/2024 05:55:12 PM
// Design Name: 
// Module Name: CLA
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


module CLA #(parameter WIDTH = 16) (
    input wire [WIDTH-1:0] A,
    input wire [WIDTH-1:0] B,
    input wire Cin,
    output wire [WIDTH:0] Sum
);
    wire [WIDTH-1:0] P, G;  // Propagate and Generate signals
    wire [WIDTH:0] C;       // Carry signals

    // Generate Propagate and Generate signals
    assign P = A ^ B;  // Propagate
    assign G = A & B;  // Generate

    // Compute carry signals
    assign C[0] = Cin;
    genvar i;
    generate
        for (i = 1; i <= WIDTH; i = i + 1) begin : carry_gen
            assign C[i] = G[i-1] | (P[i-1] & C[i-1]);
        end
    endgenerate

    // Compute Sum
    assign Sum = {C[WIDTH], P ^ C[WIDTH-1:0]};  // Sum includes carry-out

endmodule
