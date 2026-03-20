module tx232(rst, clk, tstart, txck, txpd, txsd);      //  uart 송신 모듈 tx232       

input rst, clk, tstart, txck;
input [7:0] txpd;       // 전송할 8비트 병렬 데이터 입력

output reg txsd;        // 전송되는 1비트 직렬 데이터 출력         

reg[7:0] tpd;           // 입력 데이터를 안정적으로 보관하기 위한 내부 래치 레지스터
reg[3:0] bcnt;          // 현재 몇 번째 비트를 보내는지 세는 비트 카운터 (0~8, f)

reg tc0, tc1;           // 통신 클럭(txck)의 에지 검출을 위한 2단 플립플롭
wire tcenr, tcenf;      // txck의 상승 에지(Rising) 및 하강 에지(Falling) 감지 신호

reg st0, st1;           // 전송 시작 신호(tstart)의 에지 검출용 레지스터
wire sten;              // tstart의 상승 에지(시작 시점) 감지 신호



// 1. 통신 클럭(txck) 에지 검출 로직
always @(negedge rst, posedge clk)
begin
    if(rst==0) begin
        tc0 <= 0;
        tc1 <= 0;
    end
    else begin
        tc0 <= txck;    // 현재 txck 상태 샘플링
        tc1 <= tc0;     // 이전 txck 상태 저장
    end
end

// tc0(현재)는 1이고 tc1(이전)은 0일 때 = 상승 에지(r)   
assign tcenr = ((tc0 & ~tc1) == 1) ? 1 : 0;
// tc0(현재)는 0이고 tc1(이전)은 1일 때 = 하강 에지(f)
assign tcenf = ((~tc0 & tc1) == 1) ? 1 : 0;




// 2. 전송 시작 신호(tstart) 동기화 및 에지 검출

always @(negedge rst, posedge clk)
begin
    if(rst==0) begin
        st0 <= 0;
        st1 <= 0;
    end
    else if (tcenf == 1) begin // txck의 하강 에지 타이밍에 맞춰 tstart 샘플링
        st0 <= tstart;
        st1 <= st0;
    end
end

// tstart가 0에서 1로 변하는 순간(시작 명령) 포착
assign sten = ((st0 & ~st1) == 1) ? 1 : 0;




// 3. 데이터 래치 (전송 시작 시점에 입력 데이터를 내부로 복사)
always @(negedge rst, posedge clk)
begin
    if(rst==0)
        tpd <= 8'hff;   // 초기값은 Idle 상태인 High(ff)    
    else if ((tcenr & sten) == 1) // 전송 시작 시점의 상승 에지에서
        tpd <= txpd;              // 외부 입력(txpd)을 내부 변수(tpd)에 저장
end




// 4. 비트 카운터 제어 (0:Start Bit, 1~8:Data Bits, f:Idle)
always @(negedge rst, posedge clk)
begin
    if(rst==0)
        bcnt <= 4'hf;   // 초기값은 대기 상태(f)
    else if(tcenr == 1) // txck의 상승 에지마다 동작
    begin
        if(sten == 1)   // 전송 시작 신호가 들어오면
            bcnt <= 0;  // 카운터를 0(Start Bit)으로 초기화    0  데이터 8  1   
        else if(bcnt < 9) // 0~8까지 비트 전송 중이라면
            bcnt <= bcnt + 1; // 다음 비트로 카운트 업
        else 
            bcnt <= 4'hf; // 9비트(Start+8Data) 전송이 끝나면 대기 상태로
    end
end 




// 5. 직렬 데이터 출력 (Parallel to Serial Conversion)
always @(negedge rst, posedge clk)
begin
    if(rst==0)
        txsd <= 1;      // UART 대기 상태는 항상 High(1)
    else if(tcenf == 1) // txck의 하강 에지에서 실제 데이터를 선에 실어 보냄
    begin
        case(bcnt)
            4'h0: txsd <= 0;      // Start Bit: 항상 0을 출력하여 전송 시작을 알림
            4'h1: txsd <= tpd[0]; // 데이터 비트 0 (LSB부터 전송)
            4'h2: txsd <= tpd[1];
            4'h3: txsd <= tpd[2];
            4'h4: txsd <= tpd[3];
            4'h5: txsd <= tpd[4];
            4'h6: txsd <= tpd[5];
            4'h7: txsd <= tpd[6];
            4'h8: txsd <= tpd[7]; // 데이터 비트 7 (마지막 비트)
            default: txsd <= 1;   // 그 외 상태(대기/Stop Bit)는 High 유지
        endcase
    end
end

endmodule