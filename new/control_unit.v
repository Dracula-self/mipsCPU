`timescale 1ns / 1ps
module control_unit(
    input wire [5:0] opcode,
    output reg RegDst,//0目的寄存器字段rt-I型指令
    output reg Branch,
    output reg MemRead,//从内存读数据
    output reg MemtoReg,//内存数据写会寄存器
    output reg ALUOp1,//00加法，01减法，10R指令
    output reg ALUOp0,
    output reg MemWrite,//写数据到内存
    output reg ALUSrc,//1-第二个操作数来自立即数
    output reg RegWrite,//写数据到寄存器
    output reg Jump,
    output reg ZeroExt,//1-零扩展，0-符号扩展
     output reg LinkReg // jal
);
    always @(*) begin
        RegDst = 0;
        Branch = 0;
        MemRead = 0;
        MemtoReg = 0;
        ALUOp1 = 0;
        ALUOp0 = 0;
        MemWrite = 0;
        ALUSrc = 0;
        RegWrite = 0;
        Jump = 0;
        ZeroExt = 0;
         LinkReg = 0;
        case(opcode)
            6'b000000: begin  //R型
                RegDst = 1;
                ALUOp1 = 1;
                RegWrite = 1;
            end
            6'b100011: begin//lw
                ALUSrc = 1;
                MemtoReg = 1;
                MemRead = 1;
                RegWrite = 1;
                MemWrite=0;
            end
            6'b101011: begin//sw
                ALUSrc = 1;
                MemWrite = 1;
                MemRead=0;
            end
            6'b000100: begin//beq
                Branch = 1;
                ALUOp0 = 1;
            end
            6'b000101: begin//bne
                Branch = 1;
                ALUOp0 = 1;

            end
            6'b001000: begin  //addi
                ALUSrc = 1;
                RegWrite = 1;
            end
            6'b001001: begin  //addiu (无溢出检查)
                ALUSrc = 1;
                RegWrite = 1;
            end
            6'b001100: begin  //andi
                ALUSrc = 1;
                RegWrite = 1;
                ZeroExt = 1;  //零扩展立即数
                ALUOp1 = 1;   //ALU的与
                ALUOp0 = 1;
            end
            6'b001101: begin  //ori
                ALUSrc = 1;
                RegWrite = 1;
                ZeroExt = 1;  //零扩展立即数
                ALUOp1 = 1;   //ALU的或
                ALUOp0 = 1;
            end
            6'b001010: begin  //slti
                ALUSrc = 1;
                RegWrite = 1;
                ALUOp1 = 1;   //ALU的slt
                ALUOp0 = 1;
            end
            6'b000010: begin  // j
                Jump = 1;
            end
            6'b000011: begin  //jal 
                Jump = 1;
                RegWrite = 1;
                LinkReg = 1; 
              end
            6'b001111: begin  // lui
                ALUSrc = 1;    // 使用立即数
                RegWrite = 1;  // 写寄存器
                ZeroExt = 1;   // 零扩展立即数
                ALUOp1 = 1;    // 设置ALUOp为11
                ALUOp0 = 1;    // 设置ALUOp为11
            end
            default: begin
            end
        endcase
    end
endmodule
