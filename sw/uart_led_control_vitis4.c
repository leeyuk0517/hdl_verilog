/*
키보드 입력 → UART 수신 → 버퍼에 저장
→ Enter 입력 → 문자열 분해(strtok)
→ 명령어 + 인자 해석
→ LED 상태 변경
→ GPIO 출력   
👉 strtok 없이 직접 파서 만드는 방법 (임베디드 실무에서 많이 씀)
👉 또는 strtok_r (thread-safe 버전)
strtok 적용  백스페이스 적용 ! 
all on off 도 적용 
!!!!!!!!!!기억!!!!!!!!!!!!   |
"led0 on"  → |= 0x01        |
"led0 off" → &= ~0x01       |
!!!!!!!!!!!!!!!!!!!!!!!     |
*/
#include <stdio.h>
#include <string.h>
#include <stdlib.h> // atoi 사용을 위해 추가
#include "xparameters.h"
#include "xgpio.h"
#include "xuartps.h"

#define MAX_BUFFER_SIZE 100

XGpio Gpio;

int main() {
    u8 input_char;
    char buffer[MAX_BUFFER_SIZE];
    int buf_idx = 0;
    u32 current_led_state = 0x00;

    XGpio_Initialize(&Gpio, XPAR_AXI_GPIO_0_DEVICE_ID);
    XGpio_SetDataDirection(&Gpio, 1, 0x0);

    printf("\r\n--- Zybo Z7-20 Professional Terminal ---\r\n");
    printf("Usage: led <num> <on/off>  |  Example: led 2 on\r\n");
    printf(">> ");

    while(1) {
        input_char = XUartPs_RecvByte(XPAR_PS7_UART_1_BASEADDR);

        // 1. 엔터 처리
        if (input_char == '\r' || input_char == '\n') {
            buffer[buf_idx] = '\0';
            printf("\r\n");

            if (buf_idx > 0) {
                // [strtok 핵심 로직]
                char *cmd = strtok(buffer, " ");    // 첫 번째 단어 추출 (예: led)
                char *arg1 = strtok(NULL, " ");   // 두 번째 단어 추출 (예: 2)
                char *arg2 = strtok(NULL, " ");   // 세 번째 단어 추출 (예: on)

                if (cmd != NULL && strcmp(cmd, "led") == 0 && arg1 != NULL && arg2 != NULL) {
                    int led_num = atoi(arg1); // 문자열 "2"를 숫자 2로 변환

                    if (led_num >= 0 && led_num <= 3) {
                        if (strcmp(arg2, "on") == 0) {
                            current_led_state |= (1 << led_num); // 비트 시프트 활용
                            printf("Success: LED %d turned ON\r\n", led_num);
                        } else if (strcmp(arg2, "off") == 0) {
                            current_led_state &= ~(1 << led_num);
                            printf("Success: LED %d turned OFF\r\n", led_num);
                        }
                    } else {
                        printf("Error: LED number must be 0-3\r\n");
                    }
                }

                else if (cmd != NULL && strcmp(cmd, "all") == 0 && arg1 != NULL) {
                    if (strcmp(arg1, "on") == 0) {
                        current_led_state = 0x0F; // 1111 (모두 켬)
                        printf("Success: All LEDs turned ON\r\n");
                    } else if (strcmp(arg1, "off") == 0) {
                        current_led_state = 0x00; // 0000 (모두 끔)
                        printf("Success: All LEDs turned OFF\r\n");
                    } else {
                        printf("Error: Use 'all on' or 'all off'\r\n");
                    }
                }
                // --- 여기까지 추가 ---
                else if (cmd != NULL && strcmp(cmd, "help") == 0) {
                    printf("Available: led <0-3> <on/off>, all <on/off>, help\r\n");
                }



                else if (cmd != NULL && strcmp(cmd, "help") == 0) {
                    printf("Available: led <0-3> <on/off>, help\r\n");
                }





                else {
                    printf("Invalid Syntax. Try: led 0 on\r\n");
                }

                XGpio_DiscreteWrite(&Gpio, 1, current_led_state);
            }
            buf_idx = 0;
            printf(">> ");
        }
        // 2. 백스페이스 처리 (ASCII 8: BS, 127: DEL)
        else if (input_char == 8 || input_char == 127) {
            if (buf_idx > 0) {
                buf_idx--; // 1. 보드 내 버퍼 인덱스 감소

                // 2. 터미널 화면 지우기 3단계 전송
                // (1) 커서를 뒤로 한 칸 옮김 (\b)
                XUartPs_SendByte(XPAR_PS7_UART_1_BASEADDR, '\b');
                // (2) 그 자리에 공백을 써서 글자를 지움 (Space)
                XUartPs_SendByte(XPAR_PS7_UART_1_BASEADDR, ' ');
                // (3) 공백을 썼으니 다시 커서가 오른쪽으로 감. 다시 뒤로 한 칸 옮김 (\b)
                XUartPs_SendByte(XPAR_PS7_UART_1_BASEADDR, '\b');
            }
        }

        // 3. 일반 글자 처리
        else {
            if (buf_idx < MAX_BUFFER_SIZE - 1) {
                buffer[buf_idx++] = input_char;
                XUartPs_SendByte(XPAR_PS7_UART_1_BASEADDR, input_char);
            }
        }
    }
    return 0;
}
