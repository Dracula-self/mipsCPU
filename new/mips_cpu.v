`timescale 1ns / 1ps

module mips_cpu(
    input wire clk,
    input wire rst,
    output wire [31:0] inst_sram_addr,
    input wire [31:0] inst_sram_rdata,
    output wire inst_sram_en,
    output wire [31:0] data_sram_addr,
    input wire [31:0] data_sram_rdata,
    output wire [31:0] data_sram_wdata,
    output wire [3:0] data_sram_wen,//写1
    output wire data_sram_en //写或者读
);
    reg [31:0] pc;                    // 程序计数器
    reg [31:0] ir;                    // 指令寄存器
    reg [31:0] branch_inst_pc;        // 分支指令的PC值

    wire [5:0] opcode = ir[31:26];
    wire [5:0] funct = ir[5:0];
    wire [4:0] rs = ir[25:21];
    wire [4:0] rt = ir[20:16];
    wire [4:0] rd = ir[15:11];
    wire [4:0] shamt = ir[10:6];
    wire [15:0] imm = ir[15:0];
    wire [25:0] jump_addr = ir[25:0];

    wire [31:0] sign_ext_imm = {{16{imm[15]}}, imm};
    wire [31:0] zero_ext_imm = {16'b0, imm};

    wire RegDst, Branch, MemRead, MemtoReg;
    wire ALUOp1, ALUOp0, MemWrite, ALUSrc;
    wire RegWrite, Jump, ZeroExt, LinkReg;
    wire shift_v;

    wire [31:0] pc_plus_4 = pc + 32'd4;
    wire [31:0] branch_pc_plus_4 = branch_inst_pc + 32'd4;
    wire [31:0] pc_branch =pc + (sign_ext_imm << 2);
    wire [31:0] read_data1, read_data2;                       
    wire [31:0] shift_amount = shift_v ? read_data1 : {27'b0, shamt};
    wire [31:0] alu_in2 = ALUSrc ? (ZeroExt ? zero_ext_imm : sign_ext_imm) : read_data2;
    wire zero;
    wire [31:0] alu_result;

    wire [4:0] write_reg = LinkReg ? 5'd31 : (RegDst ? rd : rt);
    wire [31:0] write_data = LinkReg ? pc_plus_4 : 
                            (MemtoReg ? data_sram_rdata : alu_result);

    wire branch_taken = (opcode == 6'b000100) ? (Branch & zero) : 
                       (opcode == 6'b000101) ? (Branch & ~zero) : 1'b0;
    wire [31:0] pc_next = Jump ? {pc_plus_4[31:28], jump_addr, 2'b00} : 
                         branch_taken ? pc_branch : pc_plus_4;

    control_unit cu(
        .opcode(opcode),
        .RegDst(RegDst),
        .Branch(Branch),
        .MemRead(MemRead),
        .MemtoReg(MemtoReg),
        .ALUOp1(ALUOp1),
        .ALUOp0(ALUOp0),
        .MemWrite(MemWrite),
        .ALUSrc(ALUSrc),
        .RegWrite(RegWrite),
        .Jump(Jump),
        .ZeroExt(ZeroExt),
        .LinkReg(LinkReg)
    );

    wire [3:0] ALUCtrl_out;
    alu_control alu_ctrl_unit(
        .ALUOp1(ALUOp1),
        .ALUOp0(ALUOp0),
        .funct(funct),
        .opcode(opcode),
        .ALUCtrl(ALUCtrl_out),
        .shift_v(shift_v)
    );


    register_file regfile(
        .clk(clk),
        .rst(rst),
        .RegWrite(RegWrite),
        .read_reg1(rs),
        .read_reg2(rt),
        .write_reg(write_reg),
        .write_data(write_data),
        .read_data1(read_data1),
        .read_data2(read_data2)
    );

    alu alu_unit(
        .a(read_data1),
        .b(alu_in2),
        .ALUCtrl(ALUCtrl_out),
        .shift_amount(shift_amount[4:0]),
        .result(alu_result),
        .zero(zero)
    );

    assign inst_sram_addr = pc;
assign inst_sram_en = 1'b1;
assign data_sram_addr = alu_result;
assign data_sram_wdata = read_data2;
assign data_sram_wen = MemWrite ? 4'b1111 : 4'b0000;
assign data_sram_en = MemRead | MemWrite;  // 添加这一行！

    always @(posedge clk) begin
        if (rst) begin
            pc <= 32'h80000000;
            ir <= 32'h00000000;
            branch_inst_pc <= 32'h80000000;
        end else begin
//            pc <= pc_next;
//            ir <= inst_sram_rdata;
            // 当遇到分支指令时保存其PC
            if (opcode == 6'b000100 || opcode == 6'b000101) begin
                branch_inst_pc <= pc;
            end
            pc <= pc_next;
            ir <= inst_sram_rdata;
        end
    end

    always @(negedge clk) begin
        if (!rst) begin
            $display("PC=%h, Inst=%h, Op=%h, Func=%h", pc, ir, opcode, funct);
            $display("Regs: rs=%h(%h), rt=%h(%h), rd=%h", 
                     rs, read_data1, rt, read_data2, write_reg);
            $display("Ctrl: Branch=%b, MemRd=%b, MemWr=%b, RegWr=%b", 
                     Branch, MemRead, MemWrite, RegWrite);
            $display("Mem: Addr=%h, WData=%h, RData=%h, En=%b, WEn=%b", 
                     data_sram_addr, data_sram_wdata, data_sram_rdata, data_sram_en, data_sram_wen);
            $display("--------------------------------------------");
        end
    end

endmodule