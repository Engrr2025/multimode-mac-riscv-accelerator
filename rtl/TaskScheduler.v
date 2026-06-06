`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/24/2024 06:57:01 PM
// Design Name: 
// Module Name: TaskScheduler
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

module TaskScheduler (
    input wire [15:0] A,          // Operand A (max 16-bit)
    input wire [15:0] B,          // Operand B (max 16-bit)
    input wire [1:0] Mode,        // Mode select: 00=2x2, 01=4x4, 10=8x8, 11=16x16
    output reg [31:0] Product,    // Final product (max 32-bit)
    output reg [31:0] Product_2x2_Out, // Output for 2x2 multiplier
    output reg [31:0] Product_4x4_Out, // Output for 4x4 multiplier
    output reg [31:0] Product_8x8_Out, // Output for 8x8 multiplier
    output reg [31:0] Product_16x16_Out, // Output for 16x16 multiplier
    output reg Error_Flag,        // Error flag for invalid mode
    output reg TS_Overflow_Flag      // Renamed overflow flag from TaskScheduler
);

    // Intermediate outputs for multipliers
    wire [3:0]  Product_2x2;
    wire [7:0]  Product_4x4;
    wire [15:0] Product_8x8;
    wire [31:0] Product_16x16;
    wire        Overflow_16x16; // extra overflow signal from 16x16 multiplier

    // Instantiate multipliers
    Multiplier_2x2 U2x2 (.A(A[1:0]), .B(B[1:0]), .Product(Product_2x2));
    Multiplier_4x4 U4x4 (.A(A[3:0]), .B(B[3:0]), .Product(Product_4x4));
    Multiplier_8x8 U8x8 (.A(A[7:0]), .B(B[7:0]), .Product(Product_8x8));
    Multiplier_16x16 U16x16 (
        .A(A),
        .B(B),
        .Product(Product_16x16),
        .Overflow(Overflow_16x16)
    );

    
    always @(*) begin
        Error_Flag = 1'b0;       // Default no error
        TS_Overflow_Flag = 1'b0; // Default no overflow from TaskScheduler
        Product = 32'b0;         // Default product value

        // Capture all results in parallel
        Product_2x2_Out = {28'b0, Product_2x2};
        Product_4x4_Out = {24'b0, Product_4x4};
        Product_8x8_Out = {16'b0, Product_8x8};
        Product_16x16_Out = Product_16x16;

        // Select product based on mode and check for overflow accordingly
        case (Mode)
            2'b00: begin 
                Product = Product_2x2_Out;   
                TS_Overflow_Flag = |Product_2x2_Out[31:4];
            end
            2'b01: begin 
                Product = Product_4x4_Out;   
                TS_Overflow_Flag = |Product_4x4_Out[31:8];
            end
            2'b10: begin 
                Product = Product_8x8_Out;   
                TS_Overflow_Flag = |Product_8x8_Out[31:16];
            end
            2'b11: begin 
                Product = Product_16x16_Out; 
                // Use the extra overflow signal from the 16x16 multiplier
                TS_Overflow_Flag = Overflow_16x16;
            end
            default: begin
                Product = 32'b0;
                Error_Flag = 1'b1;
            end
        endcase
    end

endmodule
