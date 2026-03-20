module rx232(rst, clk, rxck, rxsd, rxpd, rx_done);      //uart 수신 모듈  rx232    

input rst, clk, rxck, rxsd;
output reg [7:0] rxpd;    
output reg rx_done;       

reg [7:0] rpd;            
reg [3:0] bcnt;           

reg rc0, rc1;
wire rcenr; // 상승 에지만 사용합니다.

// 1. 통신 클럭(rxck) 에지 검출
always @(negedge rst, posedge clk) begin
    if(rst==0) {rc0, rc1} <= 2'b00;
    else {rc0, rc1} <= {rxck, rc0};
end

assign rcenr = (rc0 & ~rc1); // 상승 에지 (데이터가 가장 안정적인 지점)

// 2 & 3. 비트 카운터 및 데이터 조립 통합 로직 수정본
always @(negedge rst, posedge clk) begin
    if(rst==0) begin
        bcnt <= 4'hf;
        rpd <= 8'h00;
        rxpd <= 8'h00;
        rx_done <= 0;
    end
    else if(rcenr) begin
        if(bcnt == 4'hf) begin
            if(rxsd == 0) bcnt <= 4'h0; // Start Bit 감지
            rx_done <= 0;
        end
        else begin
            case(bcnt)
                // bcnt가 0인 시점(Start bit 확인 직후 박자)부터 
                // 바로 첫 번째 데이터(Bit 0)를 읽도록 수정합니다.
                4'h0: begin rpd[0] <= rxsd; bcnt <= 4'h1; end 
                4'h1: begin rpd[1] <= rxsd; bcnt <= 4'h2; end
                4'h2: begin rpd[2] <= rxsd; bcnt <= 4'h3; end
                4'h3: begin rpd[3] <= rxsd; bcnt <= 4'h4; end
                4'h4: begin rpd[4] <= rxsd; bcnt <= 4'h5; end
                4'h5: begin rpd[5] <= rxsd; bcnt <= 4'h6; end
                4'h6: begin rpd[6] <= rxsd; bcnt <= 4'h7; end
                4'h7: begin rpd[7] <= rxsd; bcnt <= 4'h8; end
                4'h8: begin // 마지막 비트를 읽고 데이터를 확정합니다.
                    rxpd <= rpd;
                    rx_done <= 1;
                    bcnt <= 4'hf; // 종료 후 대기상태로
                end
                default: bcnt <= 4'hf;
            endcase
        end
    end
    else if (rx_done) rx_done <= 0; // Done 신호는 한 클럭만 유지
end

endmodule