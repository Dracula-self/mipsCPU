module alu(
    input wire [31:0] a,
    input wire [31:0] b,
    input wire [3:0] ALUCtrl,
    input wire [4:0] shift_amount,
    output reg [31:0] result,
    output reg zero    
);
    always @(*) begin
        $display("ALU输入: a=%h, b=%h, ALUCtrl=%h, shift_amount=%h", a, b, ALUCtrl, shift_amount);
        case(ALUCtrl)
            4'b0000: result = a & b;       // AND
            4'b0001: result = a | b;       // OR
            4'b0010: result = a + b;       // ADD
            4'b0011: result = a ^ b;       // XOR
            4'b0110: result = a - b;       // SUB
            4'b0111: result = (a < b) ? 32'd1 : 32'd0;  // SLT
            4'b1000: result = b << shift_amount; // SLL/SLLV
            4'b1001: result = b >> shift_amount;
            4'b1010: result = $signed(b) >>> shift_amount; // SRA/SRAV
            4'b1100: result = ~(a | b);   
            4'b1011: result = {b[15:0], 16'b0};
            default: result = 32'h0;
        endcase
        zero = (result == 32'd0);
    end
endmodule