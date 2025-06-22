`timescale 1ns / 1ps
module register_file(
    input wire clk,
    input wire rst,
    input wire RegWrite,//是否允许写入数据到寄存器
    input wire [4:0] read_reg1,//要读取的第一个寄存器编号
    input wire [4:0] read_reg2,//要读取的第二个寄存器编号
    input wire [4:0] write_reg,//要写入的目标寄存器编号
    input wire [31:0] write_data,//要写入到目标寄存器的值
    output wire [31:0] read_data1,//从第rs读出的值
    output wire [31:0] read_data2//rt读出的值
);
    reg [31:0] registers [0:31];
     integer i; 
    initial begin
        for (i = 0; i < 32; i = i + 1) begin
            registers[i] = 32'h0;
        end
    end
    //读操作可以随时进行
    assign read_data1 = (read_reg1 == 0) ? 32'h0 : registers[read_reg1];
    assign read_data2 = (read_reg2 == 0) ? 32'h0 : registers[read_reg2];
    //写操作时候是时序逻辑单元，必须在时钟上升沿时候进行
    always @(posedge clk) begin
        if (rst) begin
            //复位所有寄存器
            for (i = 0; i < 32; i = i + 1) begin
                registers[i] <= 32'h0;
            end
        end 
        else if (RegWrite && write_reg != 0) begin //确保$0寄存器不被修改
            registers[write_reg] <= write_data;
        end
    end
endmodule