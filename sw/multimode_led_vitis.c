#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "xparameters.h"
#include "xuartps.h"    // Zynq UART용 라이브러리
#include "xil_io.h"     // AXI 읽기/쓰기용

// IP의 베이스 주소 (xparameters.h에서 정의된 이름 확인 필요)
#define XPAR_MULTIMODE_LED_0_S00_AXI_BASEADDR 0x43C00000

#define BUF_SIZE 64

int main() {
    char buf[BUF_SIZE];
    int buf_idx = 0;
    char input_char;

    printf("--- Multi-Mode LED Control Shell ---\n\r");
    printf("Commands: set_mode <0-3>, set_speed <value>\n\r");

    while (1) {
        // 1. UART로부터 한 바이트 읽기 (Blocking 방식)
        input_char = XUartPs_RecvByte(XPAR_PS7_UART_1_BASEADDR);

        // --- 엔터 키 입력 (\r 또는 \n) ---
        if (input_char == '\r' || input_char == '\n') {
            buf[buf_idx] = '\0'; // 문자열 마무리
            printf("\n\r");      // 줄바꿈

            if (buf_idx > 0) {
                // 파싱 변수 선언
                char *cmd = NULL, *arg1 = NULL, *arg2 = NULL;
                char *p = buf;

                // --- 파싱 로직 (사용자 제시 로직 적용) ---
                // cmd 파싱
                while (*p == ' ') p++;
                if (*p != '\0') {
                    cmd = p;
                    while (*p != ' ' && *p != '\0') p++;
                    if (*p != '\0') { *p = '\0'; p++; }
                }

                // arg1 파싱
                while (*p == ' ') p++;
                if (*p != '\0') {
                    arg1 = p;
                    while (*p != ' ' && *p != '\0') p++;
                    if (*p != '\0') { *p = '\0'; p++; }
                }

                // arg2 파싱
                while (*p == ' ') p++;
                if (*p != '\0') {
                    arg2 = p;
                    while (*p != ' ' && *p != '\0') p++;
                    if (*p != '\0') { *p = '\0'; }
                }

                // --- 명령어 실행 ---
                if (cmd != NULL) {
                    if (strcmp(cmd, "set_mode") == 0 && arg1 != NULL) {
                        int mode = atoi(arg1);
                        Xil_Out32(LED_IP_BASE + 0, mode); // slv_reg0에 모드 쓰기
                        printf("Mode set to: %d\n\r", mode);
                    }
                    else if (strcmp(cmd, "set_speed") == 0 && arg1 != NULL) {
                        int speed = atoi(arg1);
                        Xil_Out32(LED_IP_BASE + 4, speed); // slv_reg1에 속도 쓰기
                        printf("Speed set to: %d\n\r", speed);
                    }
                    else {
                        printf("Unknown Command: %s\n\r", cmd);
                    }
                }
            }
            buf_idx = 0; // 버퍼 초기화
            printf("> ");
        }
        // --- 백스페이스 처리 (ASCII 8: \b, 127: DEL) ---
        else if (input_char == 8 || input_char == 127) {
            if (buf_idx > 0) {
                buf_idx--;
                // 터미널에서 문자 지우기 시퀀스
                XUartPs_SendByte(XPAR_PS7_UART_1_BASEADDR, '\b');
                XUartPs_SendByte(XPAR_PS7_UART_1_BASEADDR, ' ');
                XUartPs_SendByte(XPAR_PS7_UART_1_BASEADDR, '\b');
            }
        }
        // --- 일반 문자 입력 ---
        else {
            if (buf_idx < BUF_SIZE - 1) {
                buf[buf_idx++] = input_char;
                XUartPs_SendByte(XPAR_PS7_UART_1_BASEADDR, input_char); // 에코(Echo)
            }
        }
    }
    return 0;
}
"C:\Users\517dy\vitis_fpga\zybo_multimode_led_vitis"