`timescale 1ns / 1ps

module tb_watch_top();

    parameter P_COUNT_BIT = 30;
    
    // 입력을 주어야 하는 신호는 reg로 선언
    reg                     clk;      // 가상 클럭
    reg                     reset;    // 가상 리셋
    reg                     i_run_en; // 가상 활성화 신호
    reg [P_COUNT_BIT-1:0]   i_freq;   // 테스트용 주파수 설정
  
    // 출력 결과를 확인하는 신호는 wire로 선언
    wire [6-1:0]            o_sec;
    wire [6-1:0]            o_min;
    wire [5-1:0]            o_hour;

    // --- [1. 테스트 대상 모듈(UUT) 연결] ---
    watch_top #(
        .P_COUNT_BIT(P_COUNT_BIT)
    ) uut (
        .clk        (clk),
        .reset      (reset),
        .i_run_en   (i_run_en),
        .i_freq     (i_freq),
        .o_sec      (o_sec),
        .o_min      (o_min),
        .o_hour     (o_hour)
    );

    // --- [2. 클럭 생성] ---
    // 5ns마다 반전시키므로 주기는 10ns (100MHz 클럭 시뮬레이션)
    always #5 clk = ~clk;

    // --- [3. 테스트 시나리오] ---
    initial begin
        // 초기값 설정
        clk      = 0;
        reset    = 1; // 처음엔 리셋 상태
        i_run_en = 0;
        i_freq   = 2; // ★ 중요: 2클럭마다 1초가 지나도록 설정 (시뮬레이션 가속)
        
        #50 reset = 0;  // 50ns 후에 리셋 해제
        #20 i_run_en = 1; // 20ns 후에 시계 동작 시작
        
        $display("--- Simulation Start! ---");

        // 1분이 될 때까지 자동으로 기다림
        wait(o_min == 1);
        $display("[Time: %t] Success: 1 Minute passed!", $time);

        // 1시간이 될 때까지 자동으로 기다림
        wait(o_hour == 1);
        $display("[Time: %t] Success: 1 Hour passed!", $time);

        #1000; // 마지막으로 여유 있게 더 돌려봄
        $display("--- All checks passed! Simulation Finished. ---");
        $stop; // 시뮬레이션 종료
    end

endmodule