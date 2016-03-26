`timescale 1ns / 100ps
/*
*
	* Test bench for RLE.
	* 
	* $Author: ssop $
	* $Date: 2016-03-26 11:09:29 -0700 (Sat, 26 Mar 2016) $
	* $Rev: 52 $
*/
module runlength_tb (
    );
    reg [7:0] din;
    reg fast_ck;
    reg data_ck;
    wire cts, rdy;
    reg rts;
    wire [7:0] dout;
    //reg [2:0] count;
    wire [1:0] fast_state, slow_state;

    integer i;
    
    initial begin 
        fast_ck = 1'b0;
        forever #5 fast_ck = ~fast_ck;
    end

       
    initial begin
        fast_ck = 0;
        rts = 0;
        //count = 0;
        data_ck = 1'b0;
        /*
        $dumpfile("runlength.vcd");
        $dumpvars(2,test);  //dump vars in test and 1 level below
        $dumpon;
        */
        /*data sequence:
        00 01 02 02 esc esc 01 02 02 02 02 esc esc 02 esc 0 */
        @(posedge fast_ck) #10 rts = 1'b1;
        
        wait(cts)@(posedge fast_ck) begin
            #1 din = 8'hAD;
            #5 data_ck = 1'b1;
            end
        wait(cts)@(posedge fast_ck) begin
        #5 data_ck = 1'b0;
            #1 din = 8'h5E;
            #5 data_ck = 1'b1;
            end
        #5 data_ck = 1'b0;
        #5 din = 8'hz;
        wait(cts) @(posedge fast_ck) begin 
            #1 din = 8'h5E;
            #5 data_ck = 1'b1;
            end
        #5 data_ck = 1'b0;
        wait(cts) @(posedge fast_ck) begin 
             #1 din = 8'h1b;
            #5 data_ck = 1'b1;
            end
        #5 data_ck = 1'b0;
        #5 din =8'hz;
        wait(cts) @(posedge fast_ck) begin
             #1 din = 8'h1b;
            #5 data_ck = 1'b1;
            end
        #5 data_ck = 1'b0;
        @(posedge fast_ck) begin 
             #1 din = 8'h1b;
            #5 data_ck = 1'b1;
            end
        #5 data_ck = 1'b0;
        @(posedge fast_ck) begin 
             #1 din = 8'h88;
            #5 data_ck = 1'b1;
            end
        for (i = 0; i < 4; i = i+1 ) begin
            #5 data_ck = 1'b0;
            wait(cts) @(posedge fast_ck)  begin 
                #1 din = 8'hc6;
                #5 data_ck = 1'b1;
                end
            end
        for (i = 0; i < 258; i = i+1 ) begin
            #5 data_ck = 1'b0;
            wait(cts) @(posedge fast_ck) begin
                 #1 din = 8'h77;
                #5 data_ck = 1'b1;
                end
            end
        #5 data_ck = 1'b0;
        wait(cts) @(posedge fast_ck)  begin 
            #1 din = 8'h5a;
            #5 data_ck = 1'b1;
            end
        #5 data_ck = 1'b0;
        wait(cts) @(posedge fast_ck) begin
             #1 din = 8'h5a;
            #5 data_ck = 1'b1;
            end
        #5 data_ck = 1'b0;
        wait(cts) @(posedge fast_ck) begin
             #1 din = 8'hEE;
            #5 data_ck = 1'b1;
            end
        #5 data_ck = 1'b0;
        #10 din = 8'hz;
        #5 rts = 1'b0;
        #1000000 $finish;
        end

     
    wire [7:0] numbytes;

    always@(fast_ck) begin
        if (rdy) 
            #1 data_ck = ~data_ck;
        if (!cts ) #1 din = 8'hz;
        end

    //instantiate the design
    runlength tb (
    .clk(fast_ck),
    .den(data_ck),
    .rts(rts),
    .din(din),
    .drdy(rdy),
    .cts(cts),
    .dout(dout),
    .state(fast_state),
    .output_state(slow_state),
    .nbytes(numbytes)
    );
    
endmodule
