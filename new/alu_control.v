`timescale 1ns / 1ps
module alu_control(
    input wire ALUOp1,
    input wire ALUOp0,
    input wire [5:0] funct,
    input wire [5:0] opcode, 
    output reg [3:0] ALUCtrl,
    output reg shift_v 
);
    always @(*) begin
        ALUCtrl = 4'b0000;
        shift_v = 1'b0; 
        if (ALUOp1 == 0 && ALUOp0 == 0) begin
            ALUCtrl = 4'b0010;  //加法-用于lw/sw/addi
            $display("Setting ALUCtrl to 0010 for addition");
        end else if (ALUOp1 == 0 && ALUOp0 == 1) begin
            ALUCtrl = 4'b0110;  //减法用于beq/bne
        end else if (ALUOp1 == 1 && ALUOp0 == 0) begin
            case(funct)
                6'b100000: ALUCtrl = 4'b0010;  // add
                6'b100001: ALUCtrl = 4'b0010;  // addu
                6'b100010: ALUCtrl = 4'b0110;  // sub
                6'b100011: ALUCtrl = 4'b0110;  // subu
                6'b100100: ALUCtrl = 4'b0000;  // and
                6'b100101: ALUCtrl = 4'b0001;  // or
                6'b100110: ALUCtrl = 4'b0011;  // xor
                6'b100111: ALUCtrl = 4'b1100;  // nor
                6'b101010: ALUCtrl = 4'b0111;  // slt
                6'b101011: ALUCtrl = 4'b0111;  // sltu
                6'b000000: ALUCtrl = 4'b1000;  // sll
                6'b000010: ALUCtrl = 4'b1001;  // srl
                6'b000011: ALUCtrl = 4'b1010;  // sra
                6'b000100: begin               // sllv
                    ALUCtrl = 4'b1000; 
                    shift_v = 1'b1; 
                end
                6'b000110: begin               // srlv
                    ALUCtrl = 4'b1001; 
                    shift_v = 1'b1; 
                end
                6'b000111: begin               // srav
                    ALUCtrl = 4'b1010; 
                    shift_v = 1'b1; 
                end
                default: ALUCtrl = 4'b0000;
            endcase
        end else if (ALUOp1 == 1 && ALUOp0 == 1) begin
            //I指令处理
            case(opcode) 
                6'b001100: ALUCtrl = 4'b0000;  // andi
                6'b001101: ALUCtrl = 4'b0001;  // ori
                6'b001010: ALUCtrl = 4'b0111;  // slti
                6'b001111: ALUCtrl = 4'b1011;  // lui 
                default:   ALUCtrl = 4'b0000;
            endcase
        end

        $display("ALUOp = %b, opcode = %b, funct = %b, ALUCtrl = %b", 
                 {ALUOp1, ALUOp0}, opcode, funct, ALUCtrl);
    end
endmodule