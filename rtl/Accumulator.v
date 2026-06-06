`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/06/2025 09:13:02 PM
// Design Name: 
// Module Name: Accumulator
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

module Accumulator (
    input  wire       clk,
    input  wire       rst,
    input  wire       Clear,
    input  wire       Accumulate_Enable,
    input  wire [31:0] Data_In,
    output wire [31:0] Accumulator_Out,
    output reg        Acc_Overflow_Flag   // Overflow from accumulation
);
    reg [31:0] acc_reg;
    
    always @(posedge clk or posedge rst) begin
        if (rst || Clear) begin
            acc_reg <= 32'b0;
            Acc_Overflow_Flag <= 1'b0;
        end else if (Accumulate_Enable) begin
            if (acc_reg + Data_In < acc_reg) begin
                acc_reg <= 32'hFFFF_FFFF; // Saturate
                Acc_Overflow_Flag <= 1'b1;
            end else begin
                acc_reg <= acc_reg + Data_In;
                Acc_Overflow_Flag <= 1'b0;
            end
        end
    end
    assign Accumulator_Out = acc_reg;
endmodule
