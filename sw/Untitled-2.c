#include <stdio.h>
#include "xparameters.h"  // IP의 주소 정보가 들어있는 헤더
#include "xil_io.h"       // Xil_Out32, Xil_In32 함수 사용
#include "sleep.h"        // usleep 함수 사용

// 1. IP의 베이스 주소 정의 (xparameters.h에서 이름을 꼭 확인하세요!)
// 보통 XPAR_MY_WATCH_AXI_V1_1_0_BASEADDR 형태입니다.
#define XPAR_MY_WATCH_AXI_V1_1_0_S00_AXI_BASEADDR 0x43C00000

// AXI 4바이트 단위 오프셋
#define REG0_OFFSET 0
#define REG1_OFFSET 4
#define REG2_OFFSET 8

int main() {
    unsigned int input_freq;
    unsigned int read_data;
    int sec, min, hour;

    printf("======= Matbi Watch Project Start! =======\n");

    while (1) {
        printf("\nInput Clock Freq (e.g., 100,000,000 for 100MHz): ");
        // 1. slv_reg0에 주파수 설정값 쓰기
        if (scanf("%u", &input_freq) == 1) {
            Xil_Out32(WATCH_BASEADDR + REG0_OFFSET, (u32)input_freq);
            
            printf("Watch is running... (HH:MM:SS)\n");

            while(1) {
                // 2. slv_reg2에서 시계 데이터 읽기 (사용자 설정 반영)
                read_data = Xil_In32(WATCH_BASEADDR + REG2_OFFSET);

                // 3. 비트 슬라이싱 (초: 6비트, 분: 6비트, 시: 5비트)
                sec  =  read_data & 0x3F;          // Bit [5:0]
                min  = (read_data >> 6) & 0x3F;    // Bit [11:6]
                hour = (read_data >> 12) & 0x1F;   // Bit [16:12]

                // 화면에 출력 (\r로 덮어쓰기)
                printf("\r   Time => %02d:%02d:%02d ", hour, min, sec);
                fflush(stdout);

                // 0.01초 대기 (UART 부하 방지)
                usleep(10000);
            }
        }
    }
    return 0;
}