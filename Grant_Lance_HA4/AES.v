`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Individual
// Engineer: Grant Lance
// 
// Create Date: 05/04/2024 11:05:21 AM
// Design Name: AES rowswap and ttable implementation
// Module Name: AES.v
// Project Name: Assignment 4
// Target Devices: 
// Tool Versions: 
// Description: 
// this assignment is broken into pieces
// 1) utilize the IP catalogue to initialize 5 ttable in BRAM
//      a) one table for the roundKey
//      b) 4 tables for the diffrent chunks (32 bits) of plaintext (128 bits)
// 2) combine these tables with system verilog code to sucessfully create an AES encryption model
//      a) Create a conditionally looping system that 
//          1) on its first loop does the pre encryption operation (E ^ Key)
//          2) on its 2nd-9th loop that grabs the 8 bit chunks from the table outputs
//             and does the RowSwapping 
//          3) monitors for the final loop to pass the finalround
//             flag through the tables and output the encrypted plaintext.  
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments: Comments on looping, nested ifs, buffers AX/EX, and flags required for looping
//  In order to do the looping correctly roundCount, finalround, giveoutput, and waitforme flags 
//   will be used
//  Essentially, the idea of the waitforme flag is to raise a flag that on the next 
//  cycle the AES block can grab. If you nest if statements inside of another that   
//  looks for this flag you can shift between performing two operations. One operation 
//  when you meet your flag condition and another when the program goes to the else 
//  section of that if
//
//  The two operations that the block will shift between is checking for if cipher 
//  output is neccesary/normal round to round operation, and outputing the cipher 
//  when done encrypting
//
//  roundCount will be used to monitor the round number and make sure that the correct
//  amount of encryption cycles are ran and that the correct flags get raised so that the
//  ciphertex it output
//
//  giveoutput will be a flag to signal that the ciphertext will be expected as output   
//  that same round. as waitforme will be 0 at the start of round 10, the block will
//  attempt to execute everything nesteed under if(waitforme == 0). When none of the
//  statements pass, the block will then move on to check for the status of round 10.
//  Because this is in the else outside of these if statements, it will be able to
//  respond to this change.
//
//  finalround will be a flag that is used in conjunction with giveoutput. Becuase of this, the   
//  flag will be raised on round 9 (when roundCount ==9 ); so that when the ttables lookup the
//  the entries for this round, they grab the correct bits. To do this the finalround is concatonated
//  onto the head (the leftmost bit) of TXXin
//
//  the buffers Ax/Ex will contain 32 bit chunks of the 128 bit plaintext.
//  this follows the encryption operations outlined in the paper given.
//  more notes on the operations of encryption included in testing doc appendix
//////////////////////////////////////////////////////////////////////////////////
module AES(
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
        E0 <= 0;
        E1 <= 0;
        E2 <= 0;
        E3 <= 0;
        cipher <= 0;
        giveoutput <= 0;
        roundCount <= 0;
        finalround <= 0;
    end else begin
        //pre encryption operations
        if (roundCount == 0) begin
            E0 <= plain[127:96] ^ roundkey[127:96];
            E1 <= plain[95:64] ^ roundkey[95:64];
            E2 <= plain[63:32] ^ roundkey[63:32];
            E3 <= plain[31:0] ^ roundkey[31:0];
            //$display("made to E0,1,2,3 <=");
        end    
        //normal round operations, count the round, and check to see if output is ready
        if (waitforme == 0) begin
            roundCount <= roundCount + 1;
            waitforme <= 1;
            //$display("made to roundCount <= roundCount + 1");
            //$display("roundCount: ", roundCount);
            //$display("waitforme: ", roundCount);
             
            if (roundCount == 9) begin 
            //$display("made to finalround <= 1");
            finalround <= 1;
            end
            
            if (roundCount == 10) begin
                //$display("made to givepoutput <= 1 \n");
                //$display("made to roundCount <= 0 ");
                roundCount <= 0;
                giveoutput <= 1;
                finalround <= 0;
            end
            // for rounds 2-9 XOR Ex with the appropriate roundkey
            if (roundCount > 0 && ~giveoutput) begin
                //$display("E <= A ^ roundkey");
                E0 <= A0 ^ roundkey[127:96];
                E1 <= A1 ^ roundkey[95:64];
                E2 <= A2 ^ roundkey[63:32];
                E3 <= A3 ^ roundkey[31:0];
            end
      end else begin
            //else check for output flag, if true cipher <= E0,1,2,3
            if (giveoutput == 1) begin
            valid <= 1;
            cipher <= {E0, E1, E2, E3};
            giveoutput <= 0;
            //$display("made to valid");
            end
            //$display("made to waitforme <= 0");
            waitforme <= 0;
      
       end
    end
    //$display("using BRAM/Updating A0,1,2,3");  
end
//row shift magic
//operations done per given resources
//(Jun's slides and the paper)
//more notes on how I concluded/validated these values in 
//testing doc appendix

//the diagonal swap (iykyk) --> new E0
//highlighted in green in notes (doc appendix)
assign T00in = {finalround, E0[31:24]};
assign T10in = {finalround, E1[23:16]}; 
assign T20in = {finalround, E2[15:8]}; 
assign T30in = {finalround, E3[7:0]};
//one corner and three in a row --> new E1
//not highlighted in notes (doc appendix)
assign T01in = {finalround, E1[31:24]}; 
assign T11in = {finalround, E2[23:16]}; 
assign T21in = {finalround, E3[15:8]}; 
assign T31in = {finalround, E0[7:0]};
//two corners --> new E2
//pink highlight (dopc appendix)
assign T02in = {finalround, E2[31:24]}; 
assign T12in = {finalround, E3[23:16]}; 
assign T22in = {finalround, E0[15:8]}; 
assign T32in = {finalround, E1[7:0]};
//three in a row and upper right --> new E3
//yellow highlight (doc appendix)
assign T03in = {finalround, E3[31:24]}; 
assign T13in = {finalround, E0[23:16]}; 
assign T23in = {finalround, E1[15:8]}; 
assign T33in = {finalround, E2[7:0]};     
//assign the Ax buffers with the correct outputs from BRAM 
assign A0 = T00out ^ T10out ^ T20out ^ T30out;
assign A1 = T01out ^ T11out ^ T21out ^ T31out;
assign A2 = T02out ^ T12out ^ T22out ^ T32out;
assign A3 = T03out ^ T13out ^ T23out ^ T33out;

endmodule