`timescale 1ns / 1ps

module top(
    input ck_rst, // active low
    input CLK100MHZ,
    output ck_io41
    );

    wire sys_rst, sys_rst_n;
    assign sys_rst = ~sys_rst_n;

    wire sys_clk, carr_clk; // 6.6 MHz clock for CP-FSK and RF carrier
    clk_wiz_sys_clk sys_clk_gen(.resetn(ck_rst), .clk_in1(CLK100MHZ), .sys_clk(sys_clk), .carr_clk(carr_clk), .locked(sys_rst_n));

    wire [7:0] audio_data;
    reg [7:0] sample;
    reg [7:0] pwm_counter;
    reg pwm_out;

    always @(posedge carr_clk)
        if (sys_rst)
            pwm_counter <= 0;
        else
        begin
            pwm_counter <= pwm_counter + 1'b1;
            if (&pwm_counter) // == 255
                sample <= audio_data;
        end

    always @(posedge carr_clk)
       pwm_out <= (pwm_counter < sample);

    assign ck_io41 = (pwm_out) ? carr_clk : 0;

    wire clk_cpfsk_data_in, cpfsk_rst, fsk_data;
    xorshift_32 xorshift_32_inst(.clk(clk_cpfsk_data_in), .rst(cpfsk_rst), .out(fsk_data));
    cpfsk_mod cpfsk_mod_inst(.clk_in(sys_clk), .sys_rst(sys_rst), .clk_out(clk_cpfsk_data_in), .cpfsk_rst(cpfsk_rst), .data(fsk_data), .audio_out(audio_data));
endmodule
