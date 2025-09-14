module uart2axi_sm #(parameter div_ratio=868)(
    input clk, rst, rx_line, axi_busy, rvalid,
    output tx_line, txn, rw,
    output [31:0]addr, wdata,
    input [31:0]rdata
    );
    
    //rx valid edge detect
    logic en, rx_valid;
    logic [1:0]edge_det1;
    always_ff@(posedge clk)begin
        if(rst)begin
            en<=0;
        end else begin
            edge_det1<={edge_det1[0],rx_valid};
            if(edge_det1==2'b01) en<=1;
            else en<=0;
        end
    end
    
    //axi rvalid edge detect
    logic axi_rvalid;
    logic [1:0]edge_det2;
    always_ff@(posedge clk)begin
        if(rst)begin
            axi_rvalid<=0;
        end else begin
            edge_det2<={edge_det2[0],rvalid};
            if(edge_det2==2'b01) axi_rvalid<=1;
            else axi_rvalid<=0;
        end
    end
    
    logic [5:0]len, len_cnt;    //max 64 burst
    logic [7:0]cnt, uart_rx_data, uart_tx_buffer;
    logic [2:0][7:0]uart_rx_buf;
    logic [31:0]axi_addr, axi_wdata;
    logic trans, rw_mode, tx_busy, act;    //axi transaction enable, write(0), read(1), uart tx busy, uart tx activate
    assign txn=trans;
    assign addr=axi_addr;
    assign wdata=axi_wdata;
    assign rw=rw_mode;
    assign uart_tx_buffer=(cnt==0)?rdata[7:0]:(cnt==1)?rdata[15:8]:(cnt==2)?rdata[23:16]:(cnt==3)?rdata[31:24]:0;
    enum logic [3:0] {IDLE,ADDR,WRITE_DATA,WRITE_TRANS,ADDR_INCR,READ_TRANS,READ_WAIT,SEND_DATA,SEND_WAIT1,SEND_WAIT2}state;
    always_ff@(posedge clk)begin
        if(rst)begin
            state<=IDLE;
        end else begin
            case(state)
                IDLE:begin
                    trans<=0;
                    act<=0;
                    if(en)begin
                        if(uart_rx_data[7:6]==2'b00)begin
                            state<=IDLE; //reset command
                        end else if(uart_rx_data[7:6]==2'b01)begin
                            state<=ADDR;  //write command
                            len<=uart_rx_data[5:0];
                            len_cnt<=0;
                            cnt<=0;
                            rw_mode<=0;
                        end else if(uart_rx_data[7:6]==2'b10)begin
                            state<=ADDR;  //read command
                            len<=uart_rx_data[5:0];
                            len_cnt<=0;
                            cnt<=0;
                            rw_mode<=1;
                        end else begin
                            state<=IDLE;
                        end
                    end
                end
                ADDR:begin
                    if(en)begin
                        if(cnt<3)begin
                            uart_rx_buf[cnt]<=uart_rx_data;
                            cnt<=cnt+1;
                        end else begin
                            axi_addr<={uart_rx_data,uart_rx_buf[2],uart_rx_buf[1],uart_rx_buf[0]};
                            cnt<=0;
                            if(rw_mode==0)state<=WRITE_DATA;
                            else if(rw_mode==1)state<=READ_TRANS;
                        end
                    end
                end
                WRITE_DATA:begin
                    if(en)begin
                        if(cnt<3)begin
                            uart_rx_buf[cnt]<=uart_rx_data;
                            cnt<=cnt+1;
                        end else begin
                            axi_wdata<={uart_rx_data,uart_rx_buf[2],uart_rx_buf[1],uart_rx_buf[0]};
                            cnt<=0;
                            state<=WRITE_TRANS;
                        end
                    end
                end
                WRITE_TRANS:begin
                    if(!axi_busy)begin
                        if(len_cnt<len)begin
                            len_cnt<=len_cnt+1;
                            trans<=1;
                            state<=ADDR_INCR;
                        end else begin
                            trans<=1;
                            state<=IDLE;
                        end
                    end
                end
                ADDR_INCR:begin
                    cnt<=cnt+1;
                    trans<=0;
                    if(cnt==2)begin
                        cnt<=0;
                        axi_addr<=axi_addr+4;
                        state<=WRITE_DATA;
                    end
                end
                READ_TRANS:begin
                    act<=0;
                    if(!axi_busy)begin
                        trans<=1;
                        act<=0;
                        state<=READ_WAIT;
                    end
                end
                READ_WAIT:begin
                    trans<=0;
                    if(axi_rvalid)begin  //axi read wait
                        state<=SEND_DATA;
                        cnt<=0;
                    end
                end
                SEND_DATA:begin
                    if(cnt<4)begin
                        act<=1; //uart tx send
                        state<=SEND_WAIT1;
                    end else begin
                        if(len_cnt<len)begin
                            len_cnt<=len_cnt+1;
                            state<=READ_TRANS;
                            axi_addr<=axi_addr+4;
                        end else begin
                            state<=IDLE;
                        end
                    end
                end
                SEND_WAIT1:begin
                    act<=0;
                    cnt<=cnt+1;
                    state<=SEND_WAIT2;
                end
                SEND_WAIT2:begin
                    if(!tx_busy) state<=SEND_DATA;
                end
                default:begin
                    state<=IDLE;
                end      
            endcase
        end
    end
    
    uart_tx #(.div_ratio(div_ratio)) tx(
        .clk(clk),
        .rst(rst),
        .act(act),
        .tx_data(uart_tx_buffer),
        .tx_line(tx_line),
        .busy(tx_busy)
        );
    uart_rx #(.div_ratio(div_ratio)) rx(
        .clk(clk),
        .rst(rst),
        .rx_line(rx_line),
        .rx_data(uart_rx_data),
        .busy(),
        .valid(rx_valid),
        .err()
        );
endmodule