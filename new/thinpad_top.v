`default_nettype none
module thinpad_top(
    input wire clk_50M,           //50MHz ʱ������
    input wire clk_11M0592,       //11.0592MHz ʱ�����루���ã��ɲ��ã�
    input wire clock_btn,         //BTN5�ֶ�ʱ�Ӱ�ť���أ���������·������ʱΪ1
    input wire reset_btn,         //BTN6�ֶ���λ��ť���أ���������·������ʱΪ1
    input  wire[3:0]  touch_btn,  //BTN1~BTN4����ť���أ�����ʱΪ1
    input  wire[31:0] dip_sw,     //32λ���뿪�أ�������ON��ʱΪ1
    output wire[15:0] leds,       //16λLED�����ʱ1����
    output wire[7:0]  dpy0,       //����ܵ�λ�źţ�����С���㣬���1����
    output wire[7:0]  dpy1,       //����ܸ�λ�źţ�����С���㣬���1����
    //BaseRAM�ź�
    inout wire[31:0] base_ram_data,  //BaseRAM���ݣ���8λ��CPLD���ڿ���������
    output wire[19:0] base_ram_addr, //BaseRAM��ַ
    output wire[3:0] base_ram_be_n,  //BaseRAM�ֽ�ʹ�ܣ�����Ч�������ʹ���ֽ�ʹ�ܣ��뱣��Ϊ0
    output wire base_ram_ce_n,       //BaseRAMƬѡ������Ч
    output wire base_ram_oe_n,       //BaseRAM��ʹ�ܣ�����Ч
    output wire base_ram_we_n,       //BaseRAMдʹ�ܣ�����Ч
    //ExtRAM�ź�
    inout wire[31:0] ext_ram_data,  //ExtRAM����
    output wire[19:0] ext_ram_addr, //ExtRAM��ַ
    output wire[3:0] ext_ram_be_n,  //ExtRAM�ֽ�ʹ�ܣ�����Ч�������ʹ���ֽ�ʹ�ܣ��뱣��Ϊ0
    output wire ext_ram_ce_n,       //ExtRAMƬѡ������Ч
    output wire ext_ram_oe_n,       //ExtRAM��ʹ�ܣ�����Ч
    output wire ext_ram_we_n,       //ExtRAMдʹ�ܣ�����Ч
    //ֱ�������ź�
    output wire txd,  //ֱ�����ڷ��Ͷ�
    input  wire rxd,  //ֱ�����ڽ��ն�
    //Flash�洢���źţ��ο� JS28F640 оƬ�ֲ�
    output wire [22:0]flash_a,      //Flash��ַ��a0����8bitģʽ��Ч��16bitģʽ������
    inout  wire [15:0]flash_d,      //Flash����
    output wire flash_rp_n,         //Flash��λ�źţ�����Ч
    output wire flash_vpen,         //Flashд�����źţ��͵�ƽʱ���ܲ�������д
    output wire flash_ce_n,         //FlashƬѡ�źţ�����Ч
    output wire flash_oe_n,         //Flash��ʹ���źţ�����Ч
    output wire flash_we_n,         //Flashдʹ���źţ�����Ч
    output wire flash_byte_n,       //Flash 8bitģʽѡ�񣬵���Ч����ʹ��flash��16λģʽʱ����Ϊ1
    //ͼ������ź�
    output wire[2:0] video_red,    //��ɫ���أ�3λ
    output wire[2:0] video_green,  //��ɫ���أ�3λ
    output wire[1:0] video_blue,   //��ɫ���أ�2λ
    output wire video_hsync,       //��ͬ����ˮƽͬ�����ź�
    output wire video_vsync,       //��ͬ������ֱͬ�����ź�
    output wire video_clk,         //����ʱ�����
    output wire video_de           //��������Ч�źţ���������������
);

/* =========== Demo code begin =========== */

// PLL��Ƶʾ��
wire locked, clk_10M, clk_20M;
pll_example clock_gen 
 (
  .clk_in1(clk_50M),  // �ⲿʱ������
  .clk_out1(clk_10M), // ʱ�����1��Ƶ����IP���ý���������
  .clk_out2(clk_20M), // ʱ�����2��Ƶ����IP���ý���������
  .reset(reset_btn), // PLL��λ����
  .locked(locked)    // PLL����ָʾ�����"1"��ʾʱ���ȶ���
                     // �󼶵�·��λ�ź�Ӧ���������ɣ����£�
 );


reg reset_of_clk10M;
//�첽��λ��ͬ���ͷţ���locked�ź�תΪ�󼶵�·�ĸ�λreset_of_clk10M
always@(posedge clk_10M or negedge locked) begin
    if(~locked) reset_of_clk10M <= 1'b1;
    else        reset_of_clk10M <= 1'b0;
end


//�ҵ�-CPU����ź�����---------------------------
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

//�ҵ�-CPUʵ����-------------------------------------------------------------------------------
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
//����ֻ�ܷ���ext_ram (0x80400000-0x807FFFFF)
wire is_data_ext_ram = (data_sram_addr[31:22] == 10'b1000000001);   //0x80400000-0x807FFFFF
//base_ram �����ź� - ֻ��Ӧָ�����
assign base_ram_addr = inst_sram_en?inst_sram_addr[21:2]:20'h0;
assign base_ram_ce_n = ~(inst_sram_en && is_inst_base_ram);
assign base_ram_oe_n = ~(inst_sram_en && is_inst_base_ram);
assign base_ram_we_n = 1'b1;  //base_ram ��Զ��д��
assign base_ram_data = 32'bz;  //base_ram ֻ���ڶ�ȡ
assign base_ram_be_n = 4'b0000;  //�������������ֽ�ʹ��
//ͬ��д�첽�������߼�
//ͬ��д���� - ����д����ź�
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
            //��ʼд���� - ���������ź�
            ext_ram_data_reg <= data_sram_wdata;
            ext_ram_be_n_reg <= ~data_sram_wen;
            ext_ram_we_n_reg <= 1'b0;
            ext_ram_ce_n_reg <= 1'b0;
            ext_ram_addr_reg <= data_sram_addr[21:2];  //�����ַ
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
assign ext_ram_oe_n = (ext_ram_we_n_reg == 1'b0) ? 1'b1 :  // д����ʱ�ر�OE
                      ~(data_sram_en && is_data_ext_ram && data_sram_wen == 4'b0000);
assign ext_ram_be_n = (data_sram_en && is_data_ext_ram) ? 
                      ((data_sram_wen == 4'b0000) ? 4'b0000 : ext_ram_be_n_reg) : 4'b1111;


assign data_sram_rdata = (data_sram_en && is_data_ext_ram && data_sram_wen == 4'b0000) ? 
                         ext_ram_data : 32'h0;
assign inst_sram_rdata = base_ram_data; 
//// ----------- ��ַ�����߼� ----------- 



// ��������ӹ�ϵʾ��ͼ��dpy1ͬ��
// p=dpy0[0] // ---a---
// c=dpy0[1] // |     |
// d=dpy0[2] // f     b
// e=dpy0[3] // |     |
// b=dpy0[4] // ---g---
// a=dpy0[5] // |     |
// f=dpy0[6] // e     c
// g=dpy0[7] // |     |
//           // ---d---  p

// 7���������������ʾ����number��16������ʾ�����������
wire[7:0] number;
SEG7_LUT segL(.oSEG1(dpy0), .iDIG(number[3:0])); //dpy0�ǵ�λ�����
SEG7_LUT segH(.oSEG1(dpy1), .iDIG(number[7:4])); //dpy1�Ǹ�λ�����
//assign leds = data_sram_rdata[15:0] !== 16'bz ? data_sram_rdata[15:0] : 16'h0000;//��ʾLED����
//assign leds=16'b0000;
reg[15:0] led_bits;
assign leds = led_bits;//---ģ���Դ�����ע��
always@(posedge clock_btn or posedge reset_btn) begin
    if(reset_btn)begin //��λ���£�����LEDΪ��ʼֵ
        led_bits <= 16'h1;
    end
    else begin //ÿ�ΰ���ʱ�Ӱ�ť��LEDѭ������
        led_bits <= {led_bits[14:0],led_bits[15]};
    end
end

//ֱ�����ڽ��շ�����ʾ����ֱ�������յ��������ٷ��ͳ�ȥ
wire [7:0] ext_uart_rx;
reg  [7:0] ext_uart_buffer, ext_uart_tx;
wire ext_uart_ready, ext_uart_clear, ext_uart_busy;
reg ext_uart_start, ext_uart_avai;
    
//assign number = ext_uart_buffer;//ģ���Դ�����ע��
assign number = inst_sram_addr[7:0];  //��ʾPC��8λ
async_receiver #(.ClkFrequency(50000000),.Baud(9600)) //����ģ�飬9600�޼���λ
    ext_uart_r(
        .clk(clk_50M),                       //�ⲿʱ���ź�
        .RxD(rxd),                           //�ⲿ�����ź�����
        .RxD_data_ready(ext_uart_ready),  //���ݽ��յ���־
        .RxD_clear(ext_uart_clear),       //������ձ�־
        .RxD_data(ext_uart_rx)             //���յ���һ�ֽ�����
    );

assign ext_uart_clear = ext_uart_ready; //�յ����ݵ�ͬʱ�������־����Ϊ������ȡ��ext_uart_buffer��
always @(posedge clk_50M) begin //���յ�������ext_uart_buffer
    if(ext_uart_ready)begin
        ext_uart_buffer <= ext_uart_rx;
        ext_uart_avai <= 1;
    end else if(!ext_uart_busy && ext_uart_avai)begin 
        ext_uart_avai <= 0;
    end
end
always @(posedge clk_50M) begin //��������ext_uart_buffer���ͳ�ȥ
    if(!ext_uart_busy && ext_uart_avai)begin 
        ext_uart_tx <= ext_uart_buffer;
        ext_uart_start <= 1;
    end else begin 
        ext_uart_start <= 0;
    end
end

async_transmitter #(.ClkFrequency(50000000),.Baud(9600)) //����ģ�飬9600�޼���λ
    ext_uart_t(
        .clk(clk_50M),                  //�ⲿʱ���ź�
        .TxD(txd),                      //�����ź����
        .TxD_busy(ext_uart_busy),       //������æ״ָ̬ʾ
        .TxD_start(ext_uart_start),    //��ʼ�����ź�
        .TxD_data(ext_uart_tx)        //�����͵�����
    );

//ͼ�������ʾ���ֱ���800x600@75Hz������ʱ��Ϊ50MHz
wire [11:0] hdata;
assign video_red = hdata < 266 ? 3'b111 : 0; //��ɫ����
assign video_green = hdata < 532 && hdata >= 266 ? 3'b111 : 0; //��ɫ����
assign video_blue = hdata >= 532 ? 2'b11 : 0; //��ɫ����
assign video_clk = clk_50M;
vga #(12, 800, 856, 976, 1040, 600, 637, 643, 666, 1, 1) vga800x600at75 (
    .clk(clk_50M), 
    .hdata(hdata), //������
    .vdata(),      //������
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
