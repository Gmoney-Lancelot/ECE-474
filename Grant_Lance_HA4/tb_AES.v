`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Individual
// Engineer: Grant Lance
// 
// Create Date: 05/04/2024 11:05:21 AM
// Design Name: test bench for AES.v
// Module Name: tb_AES
// Project Name: Assignemnt 4
// Target Devices: 
// Tool Versions: 
// Description: tests the output of AES encryption against the two provided
//              ciphertexts that are correct
//              1)76d0627da1d290436e21a4af7fca94b7
//              2)c539cf87c1153f75c4e5e809ff7dd2dc
//              Using the given plaintext:
//              1)00102030405060708090a0b0c0d0e0f0
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tb_AES();
    reg clk;
    reg rst;
    reg [127:0] plain;
    reg start;
    wire [127:0] cipher;
    wire valid;
    
wire [127:0] cipher;
wire valid;

parameter clk_period = 10;

AES uut1(
    .clk(clk),
    .rst(rst),
    .plain(plain),
    .cipher(cipher),
    .start(start),
    .valid(valid)
);

always #((clk_period/2)) clk = ~clk;

initial begin

    plain = 128'b0;
    rst = 1;
    clk = 1;
    start = 0;
    #100;
    plain = 128'h00102030405060708090a0b0c0d0e0f0;
    #100;
    start = 1;
    rst = 0;
    
    @(posedge valid);
    #10
    if (cipher == 128'h76d0627da1d290436e21a4af7fca94b7)
        $display("ok1");
    if (cipher == 128'hc539cf87c1153f75c4e5e809ff7dd2dc)
        $display("ok2");
    else
        $display ("fail");
    start = 0;
    #100;
    $finish;
end
endmodule
