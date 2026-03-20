`timescale 1ns / 1ps

module one_sec_gen #(
    parameter P_COUNT_BIT = 30   // 카운터의 비트 폭 (2^30까지 셀 수 있어 대략 1GHz 주파수까지 대응 가능)
)(
    input  wire                   clk,            // 시스템 클럭 (예: 100MHz)
    input  wire                   reset,          // 리셋 신호 (Active High)
    input  wire                   i_run_en,       // 동작 활성화 신호 (1일 때만 카운트)
    input  wire [P_COUNT_BIT-1:0] i_freq,         // 목표 주파수 값 (예: 100,000,000 이면 1초 생성)
    output reg                    o_one_sec_tick  // 1초가 되는 순간 1클럭 동안만 1이 됨
);


    // 내부 카운터 변수
    reg [P_COUNT_BIT-1:0] r_counter;        

    always @(posedge clk) begin
        if (reset) begin
            // 리셋 시 모든 상태 초기화
            r_counter      <= {P_COUNT_BIT{1'b0}};          
            o_one_sec_tick <= 1'b0;                
        end else if (i_run_en) begin
            // 동작 상태일 때 주파수 값(-1)까지 카운트
            if (r_counter == i_freq - 1) begin    
                r_counter      <= 0;                // 목표 도달 시 카운터 0으로 리셋
                o_one_sec_tick <= 1'b1;             // ★ 핵심: 1초가 되었음을 알리는 펄스 발생
            end else begin
                r_counter      <= r_counter + 1'b1; // 1씩 증가
                o_one_sec_tick <= 1'b0;             // 목표 도달 전에는 항상 0 유지
            end
        end else begin
            // i_run_en이 0이면 카운터는 멈추고 출력은 0으로 고정 (Pause 기능)
            o_one_sec_tick <= 1'b0;                
        end
    end

endmodule