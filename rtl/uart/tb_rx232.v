`timescale 1ns / 1ps

module tb_rx232();
    reg rst, clk, rxck;
    reg rxsd;           // reg로 선언 완료!
    wire [7:0] rxpd;
    wire rx_done;

    // 수신기 모듈 인스턴스화
    rx232 uut (
        .rst(rst), 
        .clk(clk), 
        .rxck(rxck), 
        .rxsd(rxsd),    // .rsxd -> .rxsd로 수정
        .rxpd(rxpd), 
        .rx_done(rx_done)
    );

    // 100MHz 메인 클럭 (10ns 주기)
    always #5 clk = ~clk;

    // 통신 클럭 (1000ns 주기 = 1MHz)
    always #500 rxck = ~rxck;

    initial begin
        // 1. 초기화
        rst = 0; clk = 0; rxck = 0; rxsd = 1; // rsxd -> rxsd로 수정
        #100 rst = 1;

        // 2. 데이터 '8'hA5' 수신 시뮬레이션
        #1000;
        rxsd = 0; #1000; // Start Bit
        rxsd = 1; #1000; // Bit 0
        rxsd = 0; #1000; // Bit 1
        rxsd = 1; #1000; // Bit 2
        rxsd = 0; #1000; // Bit 3          0 1010  0101 1     
        rxsd = 0; #1000; // Bit 4             1010  0101     => a5
        rxsd = 1; #1000; // Bit 5
        rxsd = 0; #1000; // Bit 6
        rxsd = 1; #1000; // Bit 7
        rxsd = 1; #1000; // Stop Bit
        
        #5000;
        
        // 3. 데이터 '8'h3C' 수신 시뮬레이션
        rxsd = 0; #1000; // Start
        rxsd = 0; #1000; // Bit 0
        rxsd = 0; #1000; // Bit 1
        rxsd = 1; #1000; // Bit 2
        rxsd = 1; #1000; // Bit 3
        rxsd = 1; #1000; // Bit 4
        rxsd = 1; #1000; // Bit 5
        rxsd = 0; #1000; // Bit 6
        rxsd = 0; #1000; // Bit 7
        rxsd = 1; #1000; // Stop
        
        #10000 $stop;
    end
endmodule