`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/05/2024 10:54:00 PM
// Design Name: 
// Module Name: AES_2_0
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


module AES_2_0(
    input wire clk,
    input wire rst,
    input wire [127:0] plain,
    input wire start,
    output reg [127:0] cipher,
    output reg valid
    ); 
    
wire [8:0] T00in, T01in, T02in, T03in;
wire [8:0] T10in, T11in, T12in, T13in;
wire [8:0] T20in, T21in, T22in, T23in;
wire [8:0] T30in, T31in, T32in, T33in;

wire [31:0] T00out, T01out, T02out, T03out;
wire [31:0] T10out, T11out, T12out, T13out;
wire [31:0] T20out, T21out, T22out, T23out;
wire [31:0] T30out, T31out, T32out, T33out;

wire [31:0] A0, A1, A2, A3;
reg [31:0] E0, E1, E2, E3;    

reg [3:0] roundCount;
wire [127:0] roundkey;
reg finalround;
reg giveoutput;
reg waitforme;
reg waitforkey;

fixedKeySchedule C_fixedKeySchedule (
    .clka(clk),
    .addra(roundCount),
    .douta(roundkey)
);

TableT0 C_TableT0_0 (
    .clka(clk),
    .addra(T00in),
    .douta(T00out),
    .clkb(clk),
    .addrb(T01in),
    .doutb(T01out)
);

TableT0 C_TableT0_1 (
    .clka(clk),
    .addra(T02in),
    .douta(T02out),
    .clkb(clk),
    .addrb(T03in),
    .doutb(T03out)
);

TableT1 C_TableT1_0 (
    .clka(clk),
    .addra(T10in),
    .douta(T10out),
    .clkb(clk),
    .addrb(T11in),
    .doutb(T11out)
);

TableT1 C_TableT1_1 (
    .clka(clk),
    .addra(T12in),
    .douta(T12out),
    .clkb(clk),
    .addrb(T13in),
    .doutb(T13out)
);

TableT2 C_TableT2_0 (
    .clka(clk),
    .addra(T20in),
    .douta(T20out),
    .clkb(clk),
    .addrb(T21in),
    .doutb(T21out)
);

TableT2 C_TableT2_1 (
    .clka(clk),
    .addra(T22in),
    .douta(T22out),
    .clkb(clk),
    .addrb(T23in),
    .doutb(T23out)
);

TableT3 C_TableT3_0 (
    .clka(clk),
    .addra(T30in),
    .douta(T30out),
    .clkb(clk),
    .addrb(T31in),
    .doutb(T31out)
);

TableT3 C_TableT3_1 (
    .clka(clk),
    .addra(T32in),
    .douta(T32out),
    .clkb(clk),
    .addrb(T33in),
    .doutb(T33out)
);

always @(posedge clk or posedge rst) begin
    if (rst) begin
        roundCount <=0;
        valid <= 0;
        finalround <= 0;
        waitforme <= 0;
        waitforkey <= 0;
        E0 <= 0;
        E1 <= 0;
        E2 <= 0;
        E3 <= 0;
        cipher <= 0;
        giveoutput <= 0;
        roundCount <= 0;
        finalround <= 0;
    end else begin
    
        if (roundCount == 0 && waitforme == 0) begin
            E0 <= plain[127:96] ^ roundkey[127:96];
            E1 <= plain[95:64] ^ roundkey[95:64];
            E2 <= plain[63:32] ^ roundkey[63:32];
            E3 <= plain[31:0] ^ roundkey[31:0];
            $display("made to E0,1,2,3 <=");
            $display("roundCount: ", roundCount);
        end
        if (waitforme == 1) begin
            roundCount <= roundCount + 1;
            waitforme <= 1;
            $display("roundCount: ", roundCount);
        end 
        if (roundCount > 10) begin
            roundCount <= 0;
        end  
        if (roundCount > 0 && waitforkey == 1) begin 
            
            $display("E <= A ^ roundkey");
            E0 <= A0 ^ roundkey[127:96];
            E1 <= A1 ^ roundkey[95:64];
            E2 <= A2 ^ roundkey[63:32];
            E3 <= A3 ^ roundkey[31:0];
            waitforkey <= 0;
            //cipher <= {E0, E1, E2, E3};
           
         end else begin
            waitforme <= 0;
            end
        
        $display("waitforme: ", waitforme, "\nwaitforkey: ", waitforkey);
        waitforkey <= 1;
        
    end
   end 



assign T00in = {finalround, E0[31:24]};
assign T10in = {finalround, E1[23:16]}; 
assign T20in = {finalround, E2[15:8]}; 
assign T30in = {finalround, E3[7:0]};
 
assign T01in = {finalround, E1[31:24]}; 
assign T11in = {finalround, E2[23:16]}; 
assign T21in = {finalround, E3[15:8]}; 
assign T31in = {finalround, E0[7:0]};
 
assign T02in = {finalround, E2[31:24]}; 
assign T12in = {finalround, E3[23:16]}; 
assign T22in = {finalround, E0[15:8]}; 
assign T32in = {finalround, E1[7:0]};
 
assign T03in = {finalround, E3[31:24]}; 
assign T13in = {finalround, E0[23:16]}; 
assign T23in = {finalround, E1[15:8]}; 
assign T33in = {finalround, E2[7:0]};     

  
assign A0 = T00out ^ T10out ^ T20out ^ T30out;
assign A1 = T01out ^ T11out ^ T21out ^ T31out;
assign A2 = T02out ^ T12out ^ T22out ^ T32out;
assign A3 = T03out ^ T13out ^ T23out ^ T33out;

endmodule
