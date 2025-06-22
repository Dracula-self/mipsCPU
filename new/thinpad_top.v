`default_nettype none
module thinpad_top(
    input wire clk_50M,           //50MHz 时钟输入
    input wire clk_11M0592,       //11.0592MHz 时钟输入（备用，可不用）
    input wire clock_btn,         //BTN5手动时钟按钮开关，带消抖电路，按下时为1
    input wire reset_btn,         //BTN6手动复位按钮开关，带消抖电路，按下时为1
    input  wire[3:0]  touch_btn,  //BTN1~BTN4，按钮开关，按下时为1
    input  wire[31:0] dip_sw,     //32位拨码开关，拨到“ON”时为1
    output wire[15:0] leds,       //16位LED，输出时1点亮
    output wire[7:0]  dpy0,       //数码管低位信号，包括小数点，输出1点亮
    output wire[7:0]  dpy1,       //数码管高位信号，包括小数点，输出1点亮
    //BaseRAM信号
    inout wire[31:0] base_ram_data,  //BaseRAM数据，低8位与CPLD串口控制器共享
    output wire[19:0] base_ram_addr, //BaseRAM地址
    output wire[3:0] base_ram_be_n,  //BaseRAM字节使能，低有效。如果不使用字节使能，请保持为0
    output wire base_ram_ce_n,       //BaseRAM片选，低有效
    output wire base_ram_oe_n,       //BaseRAM读使能，低有效
    output wire base_ram_we_n,       //BaseRAM写使能，低有效
    //ExtRAM信号
    inout wire[31:0] ext_ram_data,  //ExtRAM数据
    output wire[19:0] ext_ram_addr, //ExtRAM地址
    output wire[3:0] ext_ram_be_n,  //ExtRAM字节使能，低有效。如果不使用字节使能，请保持为0
    output wire ext_ram_ce_n,       //ExtRAM片选，低有效
    output wire ext_ram_oe_n,       //ExtRAM读使能，低有效
    output wire ext_ram_we_n,       //ExtRAM写使能，低有效
    //直连串口信号
    output wire txd,  //直连串口发送端
    input  wire rxd,  //直连串口接收端
    //Flash存储器信号，参考 JS28F640 芯片手册
    output wire [22:0]flash_a,      //Flash地址，a0仅在8bit模式有效，16bit模式无意义
    inout  wire [15:0]flash_d,      //Flash数据
    output wire flash_rp_n,         //Flash复位信号，低有效
    output wire flash_vpen,         //Flash写保护信号，低电平时不能擦除、烧写
    output wire flash_ce_n,         //Flash片选信号，低有效
    output wire flash_oe_n,         //Flash读使能信号，低有效
    output wire flash_we_n,         //Flash写使能信号，低有效
    output wire flash_byte_n,       //Flash 8bit模式选择，低有效。在使用flash的16位模式时请设为1
    //图像输出信号
    output wire[2:0] video_red,    //红色像素，3位
    output wire[2:0] video_green,  //绿色像素，3位
    output wire[1:0] video_blue,   //蓝色像素，2位
    output wire video_hsync,       //行同步（水平同步）信号
    output wire video_vsync,       //场同步（垂直同步）信号
    output wire video_clk,         //像素时钟输出
    output wire video_de           //行数据有效信号，用于区分消隐区
);

/* =========== Demo code begin =========== */

// PLL分频示例
wire locked, clk_10M, clk_20M;
pll_example clock_gen 
 (
  .clk_in1(clk_50M),  // 外部时钟输入
  .clk_out1(clk_10M), // 时钟输出1，频率在IP配置界面中设置
  .clk_out2(clk_20M), // 时钟输出2，频率在IP配置界面中设置
  .reset(reset_btn), // PLL复位输入
  .locked(locked)    // PLL锁定指示输出，"1"表示时钟稳定，
                     // 后级电路复位信号应当由它生成（见下）
 );


reg reset_of_clk10M;
//异步复位，同步释放，将locked信号转为后级电路的复位reset_of_clk10M
always@(posedge clk_10M or negedge locked) begin
    if(~locked) reset_of_clk10M <= 1'b1;
    else        reset_of_clk10M <= 1'b0;
end


//我的-CPU相关信号声明---------------------------
wire [31:0] inst_sram_addr;
wire [31:0] inst_sram_rdata;
wire inst_sram_en;
wire [31:0] data_sram_addr;
wire [31:0] data_sram_rdata;
wire [31:0] data_sram_wdata;
wire [3:0] data_sram_wen;
wire data_sram_en;
//-----------------------------------------------------------------------
reg [31:0] ext_ram_data_reg;
reg ext_ram_we_n_reg;
reg [3:0] ext_ram_be_n_reg;
//-----------------------------------------------------------------------
reg rst;
always@(posedge clk_10M or posedge reset_of_clk10M) begin
    if(reset_of_clk10M)begin
        rst<=1'b1;
    end
    else begin
        rst<=1'b0;
    end
end

//我的-CPU实例化-------------------------------------------------------------------------------
mips_cpu cpu(
    .clk(clk_10M),
    //.rst(reset_of_clk10M),
    .rst(rst),
    .inst_sram_addr(inst_sram_addr),
    .inst_sram_rdata(inst_sram_rdata),
    .inst_sram_en(inst_sram_en),
    .data_sram_addr(data_sram_addr),
    .data_sram_rdata(data_sram_rdata),
    .data_sram_wdata(data_sram_wdata),
    .data_sram_wen(data_sram_wen),
    .data_sram_en(data_sram_en)
);
//-----------------------------------------------------------------------------
wire is_inst_base_ram = (inst_sram_addr[31:22] == 10'b1000000000);  //0x80000000-0x803FFFFF
//数据只能访问ext_ram (0x80400000-0x807FFFFF)
wire is_data_ext_ram = (data_sram_addr[31:22] == 10'b1000000001);   //0x80400000-0x807FFFFF
//base_ram 控制信号 - 只响应指令访问
assign base_ram_addr = inst_sram_en?inst_sram_addr[21:2]:20'h0;
assign base_ram_ce_n = ~(inst_sram_en && is_inst_base_ram);
assign base_ram_oe_n = ~(inst_sram_en && is_inst_base_ram);
assign base_ram_we_n = 1'b1;  //base_ram 永远不写入
assign base_ram_data = 32'bz;  //base_ram 只用于读取
assign base_ram_be_n = 4'b0000;  //总是允许所有字节使能
//同步写异步读控制逻辑
//同步写操作 - 锁存写相关信号
reg write_pending;
reg ext_ram_ce_n_reg;
reg [19:0] ext_ram_addr_reg;

always @(posedge clk_10M) begin
    if (rst) begin
        ext_ram_data_reg <= 32'h0;
        ext_ram_we_n_reg <= 1'b1;
        ext_ram_be_n_reg <= 4'b1111;
        ext_ram_ce_n_reg <= 1'b1;
        ext_ram_addr_reg <= 20'h0;  
        write_pending <= 1'b0;
    end else begin
        if (data_sram_en && is_data_ext_ram && data_sram_wen != 4'b0000) begin
            //开始写操作 - 锁存所有信号
            ext_ram_data_reg <= data_sram_wdata;
            ext_ram_be_n_reg <= ~data_sram_wen;
            ext_ram_we_n_reg <= 1'b0;
            ext_ram_ce_n_reg <= 1'b0;
            ext_ram_addr_reg <= data_sram_addr[21:2];  //锁存地址
            write_pending <= 1'b1;
        end else if (write_pending) begin
            ext_ram_we_n_reg <= 1'b0;
            ext_ram_ce_n_reg <= 1'b0;
            write_pending <= 1'b0;
        end else begin
            ext_ram_we_n_reg <= 1'b1;
            ext_ram_ce_n_reg <= 1'b1;
            ext_ram_be_n_reg <= 4'b1111;
        end
    end
end


assign ext_ram_addr = (ext_ram_we_n_reg == 1'b0) ? ext_ram_addr_reg : 
                      ((data_sram_en && is_data_ext_ram) ? data_sram_addr[21:2] : 20'h0);  

assign ext_ram_data = (ext_ram_we_n_reg == 1'b0) ? ext_ram_data_reg : 32'bz;
assign ext_ram_we_n = ext_ram_we_n_reg;
assign ext_ram_ce_n = (ext_ram_we_n_reg == 1'b0) ? ext_ram_ce_n_reg : 
                      ~(data_sram_en && is_data_ext_ram);
assign ext_ram_oe_n = (ext_ram_we_n_reg == 1'b0) ? 1'b1 :  // 写操作时关闭OE
                      ~(data_sram_en && is_data_ext_ram && data_sram_wen == 4'b0000);
assign ext_ram_be_n = (data_sram_en && is_data_ext_ram) ? 
                      ((data_sram_wen == 4'b0000) ? 4'b0000 : ext_ram_be_n_reg) : 4'b1111;


assign data_sram_rdata = (data_sram_en && is_data_ext_ram && data_sram_wen == 4'b0000) ? 
                         ext_ram_data : 32'h0;
assign inst_sram_rdata = base_ram_data; 
//// ----------- 地址解码逻辑 ----------- 



// 数码管连接关系示意图，dpy1同理
// p=dpy0[0] // ---a---
// c=dpy0[1] // |     |
// d=dpy0[2] // f     b
// e=dpy0[3] // |     |
// b=dpy0[4] // ---g---
// a=dpy0[5] // |     |
// f=dpy0[6] // e     c
// g=dpy0[7] // |     |
//           // ---d---  p

// 7段数码管译码器演示，将number用16进制显示在数码管上面
wire[7:0] number;
SEG7_LUT segL(.oSEG1(dpy0), .iDIG(number[3:0])); //dpy0是低位数码管
SEG7_LUT segH(.oSEG1(dpy1), .iDIG(number[7:4])); //dpy1是高位数码管
//assign leds = data_sram_rdata[15:0] !== 16'bz ? data_sram_rdata[15:0] : 16'h0000;//显示LED数据
//assign leds=16'b0000;
reg[15:0] led_bits;
assign leds = led_bits;//---模板自带被我注释
always@(posedge clock_btn or posedge reset_btn) begin
    if(reset_btn)begin //复位按下，设置LED为初始值
        led_bits <= 16'h1;
    end
    else begin //每次按下时钟按钮，LED循环左移
        led_bits <= {led_bits[14:0],led_bits[15]};
    end
end

//直连串口接收发送演示，从直连串口收到的数据再发送出去
wire [7:0] ext_uart_rx;
reg  [7:0] ext_uart_buffer, ext_uart_tx;
wire ext_uart_ready, ext_uart_clear, ext_uart_busy;
reg ext_uart_start, ext_uart_avai;
    
//assign number = ext_uart_buffer;//模板自带被我注释
assign number = inst_sram_addr[7:0];  //显示PC的8位
async_receiver #(.ClkFrequency(50000000),.Baud(9600)) //接收模块，9600无检验位
    ext_uart_r(
        .clk(clk_50M),                       //外部时钟信号
        .RxD(rxd),                           //外部串行信号输入
        .RxD_data_ready(ext_uart_ready),  //数据接收到标志
        .RxD_clear(ext_uart_clear),       //清除接收标志
        .RxD_data(ext_uart_rx)             //接收到的一字节数据
    );

assign ext_uart_clear = ext_uart_ready; //收到数据的同时，清除标志，因为数据已取到ext_uart_buffer中
always @(posedge clk_50M) begin //接收到缓冲区ext_uart_buffer
    if(ext_uart_ready)begin
        ext_uart_buffer <= ext_uart_rx;
        ext_uart_avai <= 1;
    end else if(!ext_uart_busy && ext_uart_avai)begin 
        ext_uart_avai <= 0;
    end
end
always @(posedge clk_50M) begin //将缓冲区ext_uart_buffer发送出去
    if(!ext_uart_busy && ext_uart_avai)begin 
        ext_uart_tx <= ext_uart_buffer;
        ext_uart_start <= 1;
    end else begin 
        ext_uart_start <= 0;
    end
end

async_transmitter #(.ClkFrequency(50000000),.Baud(9600)) //发送模块，9600无检验位
    ext_uart_t(
        .clk(clk_50M),                  //外部时钟信号
        .TxD(txd),                      //串行信号输出
        .TxD_busy(ext_uart_busy),       //发送器忙状态指示
        .TxD_start(ext_uart_start),    //开始发送信号
        .TxD_data(ext_uart_tx)        //待发送的数据
    );

//图像输出演示，分辨率800x600@75Hz，像素时钟为50MHz
wire [11:0] hdata;
assign video_red = hdata < 266 ? 3'b111 : 0; //红色竖条
assign video_green = hdata < 532 && hdata >= 266 ? 3'b111 : 0; //绿色竖条
assign video_blue = hdata >= 532 ? 2'b11 : 0; //蓝色竖条
assign video_clk = clk_50M;
vga #(12, 800, 856, 976, 1040, 600, 637, 643, 666, 1, 1) vga800x600at75 (
    .clk(clk_50M), 
    .hdata(hdata), //横坐标
    .vdata(),      //纵坐标
    .hsync(video_hsync),
    .vsync(video_vsync),
    .data_enable(video_de)
);
always @(posedge clk_10M) begin
    if (data_sram_en && data_sram_wen != 4'b0000) begin
        $display("CPU Store: addr=0x%h -> ext_ram_addr=0x%h, data=0x%h, time=%t", 
                 data_sram_addr, ext_ram_addr, data_sram_wdata, $time);
    end
end 



/* =========== Demo code end =========== */

endmodule
