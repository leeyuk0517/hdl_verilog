`timescale 1ns / 1ps

module tb_tx232();
    reg rst, clk, tstart, txck;
    reg [7:0] txpd;
    wire txsd;

    // 모듈 인스턴스화
          
    tx232 uut (
        .rst(rst), .clk(clk), .tstart(tstart), 
        .txck(txck), .txpd(txpd), .txsd(txsd)
    );

    // 100MHz 메인 클럭 생성 (10ns 주기)
    always #5 clk = ~clk;

    // 통신 클럭 생성 (txck 주기가 1000ns이므로 전송에 총 10us 이상 걸림)
    always #500 txck = ~txck;

    initial begin
        // 1. 초기화
        rst = 0; clk = 0; txck = 0; tstart = 0; txpd = 8'h00;
        #100 rst = 1; // 리셋 해제
        
        // 2. 첫 번째 데이터 전송 (8'hA5 = 1010 0101)     0 1010 0101 1     
        #1000 txpd = 8'hA5;
        tstart = 1;
        #1000 tstart = 0; 

        // 3. 충분히 대기 (첫 번째 전송이 끝날 때까지 기다려야 함)
        // txck 주기가 1000ns이고 10비트(Start+8Data+Stop)를 보내므로 최소 10,000ns 필요
        #12000; 

        // 4. 두 번째 데이터 전송 (8'h3C = 00111100)
        txpd = 8'h3C;                        0 00111100 1
        tstart = 1;
        #1000 tstart = 0;

        // 5. 전송 완료까지 대기 후 종료
        #15000 $stop;
    end
endmodule