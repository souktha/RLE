`timescale 1ns / 100ps

/*
Data compression by run length encoding. It replaces continuously repeated occurrence of a byte
by a repeat count and the byte value.
 - If any char 'c' repeats n times in the input stream with n > 2, we output 'nc', for example,
a2a201c2c23a3a3a3a -> 02a2010102c2043a. Worst case being non-repeat char
 Circuit is supplied by two external clocks, datclk (25MHZ), and the primary clock (100MHZ).
 Data strobe on rising edge of dataclk so it can be latched safely on pos edge.
 Fresh byte of data arrive at every data clock (dataclk).
 Data output is signaled by drdy on rising edge of primary clock. Count is strobed on rising
 edge of drdry, and byte value on its falling edge.

$Author: ssop $
$Date: 2016-03-26 11:06:02 -0700 (Sat, 26 Mar 2016) $
$Rev: 50 $
*/
module runlength (
    input clk, //main clock (sys clock)
    input den,  //data input enable use as data clock.
    input rts,
    input [7:0] din,
    output reg [7:0] dout,
    output reg drdy,
    output reg cts,
    output [1:0] state, //for debug
    output [1:0] output_state, //for debug
    output [7:0] nbytes //for debug
    );

    reg [7:0] temp, prev, count;
    localparam RCV_IDLE=0, s1=1, s2=2, FLUSH_DATA=3;
    reg [1:0] current_state, next_state;
    wire dataclk;
    reg [7:0] sent_count;
    localparam IDLE=0, SEND_COUNT=1, SEND_DATA=2, DATA_SENT=3, SEND_FINAL_COUNT=4, SEND_FINAL_DATA=5; //output state
    reg [2:0] current_output_state;
    reg [1:0] next_output_state;

    assign dataclk = den;

    initial begin      //for simulation
        #0 count = 8'h00;
        #0 drdy = 1'b0;
        #0 cts = 1'b0;
        #0 current_state = RCV_IDLE;
        #0 next_state = RCV_IDLE;
        #0 dout = 8'hx;
        sent_count = 8'h0;
    end

    initial begin 
     current_output_state = IDLE;
     next_output_state = IDLE;
     temp = 7'h0;
    end
    /* cts active high to signal sender as clear-to-send. Sender shall not send
    input data if cts is deasserted.
    rts is active high from sender as request-to-send. rts shall remain asserted
    while data being sent. Sender is to drive data by dataclk on cts.
    Sender shall signal end of transmission by deassering rts and remove dataclk.
    cts is a respond to rts from this module.  */
    always@(posedge clk)  current_state <= next_state;
    always@(posedge clk) current_output_state <= next_output_state;

    assign state = current_state; //debug

    always@(current_state, count, rts, current_output_state, prev,temp) begin
        case(current_state)
            RCV_IDLE: begin
                if (rts) begin
                    #2 cts = 1'b1;
                    if (count > 0 )
                        next_state = s1; //normal transition
                end
                else if (count > 0)
                      next_state = FLUSH_DATA;    //final end sequence.
                end
            s1: begin
                if ((count > 1) && (prev != temp)) begin
                    #2 cts = 1'b0;
                    next_state = FLUSH_DATA; //flush this data set if non-repeated byte is detected.
                    end
                else if ( count == 'd255 ) begin
                   #2 cts = 1'b0; 
                   next_state = s2;
                   end
                end
            s2: begin
                //flush all data, final until next rts.
                next_state = FLUSH_DATA;
                end
            FLUSH_DATA: begin
                if (current_output_state == DATA_SENT) 
                    next_state = RCV_IDLE;
                end
        endcase
    end
    /*****************************************************/


    assign nbytes = count; //num of bytes received so far (debug)

    always@(posedge dataclk) begin //slow clock
        if (cts) begin
            prev <= temp;
            temp <= din;
            sent_count <= count;
            count <= count + 1'b1;
        end
        /* update if transmitting data */
        if (current_output_state == SEND_COUNT) begin
            count <= count - sent_count ;
            end
        if (!rts) begin
          sent_count <= count;
          end
    end

    assign output_state = current_output_state; //debug

    always@(current_output_state,rts, current_state) begin
        case (current_output_state)
            IDLE: begin 
                dout = 8'hx;
                if (current_state == FLUSH_DATA)
                    next_output_state  = SEND_COUNT;
                end
            SEND_COUNT: begin
                dout = sent_count; //previous count
                #3 drdy = 1'b1;
                next_output_state = SEND_DATA;
                end
            SEND_DATA: begin 
                if (sent_count == 1 && !rts) dout = temp;
                else
                dout = prev;
                next_output_state = DATA_SENT;
                end
            DATA_SENT: begin 
                #3 drdy = 1'b0;
                next_output_state = IDLE;
                end
            default: next_output_state = IDLE;
        endcase
        end
endmodule
