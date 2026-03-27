 
 /*
 
 // 백스페이스 처리
            else if (input_char == 8 || input_char == 127) {
                if (buf_idx > 0) {
                    buf_idx--;
                    XUartPs_SendByte(XPAR_PS7_UART_1_BASEADDR, '\b');
                    XUartPs_SendByte(XPAR_PS7_UART_1_BASEADDR, ' ');
                    XUartPs_SendByte(XPAR_PS7_UART_1_BASEADDR, '\b');
                }
            }

*/



/*


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "xparameters.h"
#include "xil_io.h"
#include "xuartps.h"

#define REF_CLK 100000000
#define LED_IP_BASE 0x43C00000
#define MAX_BUFFER_SIZE 100

// 하드웨어 레지스터 주소 정의
#define REG_MODE_SET    (LED_IP_BASE + 0)
#define REG_SPEED_SET   (LED_IP_BASE + 4)
#define REG_STATUS_READ (LED_IP_BASE + 8)

// --- [추가] 모드 이름을 문자열로 반환하는 함수 ---
const char* get_mode_name(u8 mode) {
    switch(mode) {
        case 0: return "Blinker (All LED)";
        case 1: return "PWM (Brightness Control)";
        case 2: return "Shift (Running LED)";
        case 3: return "Pattern (Switch Direct)";
        default: return "Unknown";
    }
}

void print_help() {
    printf("\r\n===============================================");
    printf("\r\n   Multi-Mode LED System Control Shell");
    printf("\r\n   - t_mode <0-3>   : Change LED Pattern");
    printf("\r\n   - t_speed <sec>  : Set Speed (e.g., 0.5 or 1)");
    printf("\r\n   - help           : Show this menu");
    printf("\r\n===============================================");
    printf("\r\n>> ");
}

int main() {
    u8 input_char;
    char buffer[MAX_BUFFER_SIZE];
    int buf_idx = 0;
    u32 last_hw_status = 0xFFFFFFFF; // 초기 상태와 다르게 설정

    print_help();

    while(1) {
        // --- 1. 하드웨어 상태 실시간 감시 (Verilog의 slv_reg2 피드백 읽기) ---
        // --- 1. 하드웨어 상태 실시간 감시 (Verilog의 slv_reg2 피드백 읽기) ---
        u32 current_hw_status = Xil_In32(REG_STATUS_READ);

        if (current_hw_status != last_hw_status) {
            u8 sw_val   = (current_hw_status >> 2) & 0x0F;
            u8 btn_val  = (current_hw_status >> 6) & 0x0F;
            u8 mode_val = current_hw_status & 0x03;
            u8 last_mode = last_hw_status & 0x03; // 이전 모드 값

            // [추가] 버튼이 눌렸고, 모드까지 바뀌었다면? -> 강조 출력!
            if (btn_val != 0 && mode_val != last_mode) {
                printf("\r\n***************************************");
                printf("\r\n[!] BUTTON INPUT! -> MODE CHANGED!");
                printf("\r\n[!] Current Mode: [%d] %s", mode_val, get_mode_name(mode_val));
                printf("\r\n***************************************");
            }
            else {
                // 일반적인 스위치 변화 등은 기존처럼 출력
                printf("\r\n[EVENT] Hardware State Changed!");
                printf("\r\n  - Current Mode : [%d] %s", mode_val, get_mode_name(mode_val));
            }

            // 스위치 상태는 항상 시각화해서 출력
            printf("\r\n  - Switches     : [ ");
            for(int i=3; i>=0; i--) printf("%d ", (sw_val >> i) & 1);
            printf("]");

            if (btn_val) {
                printf(" | Button: 0x%X Pushed!", btn_val);
            }
            printf("\r\n>> ");

            last_hw_status = current_hw_status;
        }

        // --- 2. UART 입력 처리 (Non-blocking) ---
        if (XUartPs_IsReceiveData(XPAR_PS7_UART_1_BASEADDR)) {
            input_char = XUartPs_RecvByte(XPAR_PS7_UART_1_BASEADDR);

            if (input_char == '\r' || input_char == '\n') {
                buffer[buf_idx] = '\0';
                printf("\r\n");

                if (buf_idx > 0) {
                    char *cmd = strtok(buffer, " "); // strtok을 쓰면 파싱이 더 간결해집니다.
                    char *arg1 = strtok(NULL, " ");

                    if (cmd && strcmp(cmd, "t_mode") == 0) {
                        if (arg1) {
                            int val = atoi(arg1);
                            if (val >= 0 && val <= 3) {
                                Xil_Out32(REG_MODE_SET, val);
                                printf("SUCCESS: Mode changed to %s\r\n", get_mode_name(val));
                            } else {
                                printf("ERROR: Mode must be 0~3\r\n");
                            }
                        }
                    }
                    else if (cmd && strcmp(cmd, "t_speed") == 0) {
                        if (arg1) {
                            double sec = atof(arg1);
                            if (sec > 0) {
                                u32 divider_val = (u32)(sec * REF_CLK);
                                Xil_Out32(REG_SPEED_SET, divider_val);
                                printf("SUCCESS: Speed updated to %.2f seconds\r\n", sec);
                            } else {
                                printf("ERROR: Speed must be > 0\r\n");
                            }
                        }
                    }
                    else if (cmd && strcmp(cmd, "help") == 0) {
                        print_help();
                    }
                }
                buf_idx = 0;
                printf(">> ");
            }
            // 백스페이스 처리
             else if (input_char == 8 || input_char == 127) {
            	 if (buf_idx > 0) {
            		 buf_idx--;
                     XUartPs_SendByte(XPAR_PS7_UART_1_BASEADDR, '\b');
                     XUartPs_SendByte(XPAR_PS7_UART_1_BASEADDR, ' ');
                     XUartPs_SendByte(XPAR_PS7_UART_1_BASEADDR, '\b');
                 	}
             }
             else if (buf_idx < MAX_BUFFER_SIZE - 1) {
                  buffer[buf_idx++] = input_char;
                  XUartPs_SendByte(XPAR_PS7_UART_1_BASEADDR, input_char);
              }


        }
    }
    return 0;
}



*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "xparameters.h"
#include "xil_io.h"
#include "xuartps.h"

#define LED_IP_BASE 0x43C00000
#define REG_MODE_SET    (LED_IP_BASE + 0)
#define REG_SPEED_SET   (LED_IP_BASE + 4)
#define REG_STATUS_READ (LED_IP_BASE + 8)

#define REF_CLK         100000000
#define MAX_BUFFER_SIZE 100
#define UART_BASEADDR   XPAR_PS7_UART_1_BASEADDR

// 모드 이름
const char* get_mode_name(u8 mode) {
    switch(mode) {
        case 0: return "Blinker (All LED)";
        case 1: return "PWM (Brightness Control)";
        case 2: return "Shift (Running LED)";
        case 3: return "Pattern (Switch Direct)";
        default: return "Unknown";
    }
}

int main() {
    u8 input_char;
    char buffer[MAX_BUFFER_SIZE];
    int buf_idx = 0;
    u32 last_hw_status = 0xFFFFFFFF;

    printf("\033[2J\033[H");
    printf("\r\n>> ");

    while(1) {
        // --- 1. 하드웨어 상태 감시 (이 부분 비트만 수정!) ---
        u32 current_hw_status = Xil_In32(REG_STATUS_READ);

        if (current_hw_status != last_hw_status) {
            // 하드웨어: {16'b0, sw[4], 4'b0, btn[4], 4'b0, mode[2]}
            u8 mode_val = current_hw_status & 0x03;           // 비트 0~1
            u8 btn_val  = (current_hw_status >> 6) & 0x0F;    // 비트 6~9 (btn)
            u8 sw_val   = (current_hw_status >> 14) & 0x0F;   // 비트 14~17 (sw)

            printf("\r\n[EVENT] HW Change Detect!");
            printf("\r\n  - Mode: [%d] %s", mode_val, get_mode_name(mode_val));
            printf("\r\n  - SW  : 0x%X | BTN: 0x%X", sw_val, btn_val);
            printf("\r\n>> %.*s", buf_idx, buffer); 
            fflush(stdout);

            last_hw_status = current_hw_status;
        }

        // --- 2. UART 입력 처리 (사용자 로직 그대로 유지) ---
        if (XUartPs_IsReceiveData(UART_BASEADDR)) {
            input_char = XUartPs_RecvByte(UART_BASEADDR);

            if (input_char == '\r' || input_char == '\n') {
                buffer[buf_idx] = '\0';
                printf("\r\n");

                if (buf_idx > 0) {
                    char *cmd = strtok(buffer, " ");
                    char *arg1 = strtok(NULL, " ");

                    if (cmd && strcmp(cmd, "t_mode") == 0) {
                        if (arg1) {
                            int val = atoi(arg1);
                            Xil_Out32(REG_MODE_SET, val);
                        }
                    } else if (cmd && strcmp(cmd, "t_speed") == 0) {
                        if (arg1) {
                            float sec = atof(arg1);
                            Xil_Out32(REG_SPEED_SET, (u32)(sec * REF_CLK));
                        }
                    }
                }
                buf_idx = 0;
                printf(">> ");
            }
            // ★ 시발 백스페이스랑 에코 이걸로 함! ★
            else if (input_char == 8 || input_char == 127) {
                if (buf_idx > 0) {
                    buf_idx--;
                    XUartPs_SendByte(UART_BASEADDR, '\b'); // 커서 뒤로
                    XUartPs_SendByte(UART_BASEADDR, ' ');  // 공백 써서 지우기
                    XUartPs_SendByte(UART_BASEADDR, '\b'); // 다시 커서 뒤로
                }
            }
            else if (buf_idx < MAX_BUFFER_SIZE - 1) {
                buffer[buf_idx++] = input_char;
                XUartPs_SendByte(UART_BASEADDR, input_char); // 에코(Echo)
            }
        }
    }
    return 0;
}