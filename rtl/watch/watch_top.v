`timescale 1ns / 1ps

module watch_top #(
    parameter P_COUNT_BIT = 30, 
    parameter P_SEC_BIT   = 6,  // 0~59초 (6비트면 63까지 표현 가능)
    parameter P_MIN_BIT   = 6,  // 0~59분
    parameter P_HOUR_BIT  = 5   // 0~23시 (5비트면 31까지 표현 가능)
)(
    input  wire                   clk,      
    input  wire                   reset,    
    input  wire                   i_run_en, 
    input  wire [P_COUNT_BIT-1:0] i_freq,   // 1초를 만들기 위한 클럭 개수
    output reg  [P_SEC_BIT-1:0]   o_sec,    // 현재 초
    output reg  [P_MIN_BIT-1:0]   o_min,    // 현재 분
    output reg  [P_HOUR_BIT-1:0]  o_hour    // 현재 시
);

    wire w_one_sec_tick; // 1초 마다 발생하는 펄스
    reg  [P_MIN_BIT-1:0]  r_min_cnt;  // 분을 계산하기 위해 초를 세는 카운터 (0~59)
    reg  [12-1:0]         r_hour_cnt; // 시를 계산하기 위해 초를 세는 카운터 (0~3599)

    // 각 단위가 끝에 도달했는지 체크하는 신호 (Tick 신호들)
    wire sec_tick  = (o_sec  == 60-1);
    wire min_tick  = (o_min  == 60-1);
    wire hour_tick = (o_hour == 24-1);

    // 1. [모듈 호출] 주파수를 입력받아 1초 틱을 생성하는 하위 모듈
    one_sec_gen #(
        .P_COUNT_BIT(P_COUNT_BIT)
    ) u_one_sec_gen (
        .clk            (clk),
        .reset          (reset),
        .i_run_en       (i_run_en),
        .i_freq         (i_freq),
        .o_one_sec_tick (w_one_sec_tick)
    );



    // 2. [초(Second) 로직] 1초 틱이 올 때마다 1씩 증가
    always @(posedge clk) begin
        if (reset) begin
            o_sec <= 0;
        end else if (w_one_sec_tick) begin
            if (sec_tick) o_sec <= 0; // 59초 다음엔 0
            else          o_sec <= o_sec + 1'b1;
        end
    end

    // 3. [분(Minute) 로직] 60초가 쌓이면 1분 증가
    always @(posedge clk) begin
        if (reset) begin
            r_min_cnt <= 0;
            o_min     <= 0;
        end else if (w_one_sec_tick) begin
            if (sec_tick & min_tick) begin      
                o_min     <= 0; // 59분 59초가 되면 분 초기화
                r_min_cnt <= 0;
            end else if (r_min_cnt == 60-1) begin   // 60초가 쌓였을 때 1분 증가
                o_min     <= o_min + 1'b1;
                r_min_cnt <= 0;
            end else begin
                r_min_cnt <= r_min_cnt + 1'b1; 
            end
        end
    end

    // 4. [시(Hour) 로직] 3600초(1시간)가 쌓이면 1시간 증가
    always @(posedge clk) begin
        if (reset) begin
            r_hour_cnt <= 0;
            o_hour     <= 0;
        end else if (w_one_sec_tick) begin
            if (sec_tick & min_tick & hour_tick) begin   
                o_hour     <= 0; // 23시 59분 59초가 되면 시 초기화
                r_hour_cnt <= 0;
            end else if (r_hour_cnt == 3600-1) begin   // 3600초가 쌓였을 때 1시간 증가
                o_hour     <= o_hour + 1'b1;
                r_hour_cnt <= 0;
            end else begin
                r_hour_cnt <= r_hour_cnt + 1'b1;    
            end
        end
    end

endmodule



/*
타이밍 검사  신호 즉각 검사
tcl , consol을 통해 신호 바뀐 타이밍 그 지점 찾기   
디바운싱, 클럭 동기화, ILA       



*/
