/*
strtok 말고 직접 파싱 추가 

*/

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
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

    printf("\r\n--- Zybo Z7-20 Direct Parser CLI ---\r\n");
    printf("Usage: led <num> <on/off>, all <on/off>, help\r\n");
    printf(">> ");

    while(1) {
        input_char = XUartPs_RecvByte(XPAR_PS7_UART_1_BASEADDR);

        // 1. Enter 처리
        if (input_char == '\r' || input_char == '\n') {
            buffer[buf_idx] = '\0';
            printf("\r\n");

            if (buf_idx > 0) {
                char *cmd = NULL;
                char *arg1 = NULL;
                char *arg2 = NULL;

                char *p = buffer;

                // --- cmd ---
                while (*p == ' ') p++;   // FIX: 무한루프 방지
                if (*p != '\0') {
                    cmd = p;
                    while (*p != ' ' && *p != '\0') p++;
                    if (*p != '\0') {
                        *p = '\0';
                        p++;
                    }
                }

                // --- arg1 ---
                while (*p == ' ') p++;
                if (*p != '\0') {
                    arg1 = p;
                    while (*p != ' ' && *p != '\0') p++;
                    if (*p != '\0') {
                        *p = '\0';
                        p++;
                    }
                }

                // --- arg2 ---
                while (*p == ' ') p++;
                if (*p != '\0') {
                    arg2 = p;
                    while (*p != ' ' && *p != '\0') p++;
                    if (*p != '\0') {
                        *p = '\0';
                    }
                }

                // ===== 명령 처리 =====

                if (cmd && strcmp(cmd, "led") == 0) {

                    if (arg1 == NULL || arg2 == NULL) {
                        printf("Usage: led <0-3> <on/off>\r\n");
                    } else {
                        char *end;
                        long led_num = strtol(arg1, &end, 10);

                        // 숫자 검증
                        if (*end != '\0') {
                            printf("Invalid number\r\n");
                        }
                        else if (led_num < 0 || led_num > 3) {
                            printf("LED number must be 0~3\r\n");
                        }
                        else {
                            if (strcmp(arg2, "on") == 0) {
                                current_led_state |= (1 << led_num);
                                printf("LED %ld ON\r\n", led_num);
                            }
                            else if (strcmp(arg2, "off") == 0) {
                                current_led_state &= ~(1 << led_num);
                                printf("LED %ld OFF\r\n", led_num);
                            }
                            else {
                                printf("Use on/off\r\n");
                            }
                        }
                    }
                }

                else if (cmd && strcmp(cmd, "all") == 0) {
                    if (arg1 == NULL) {
                        printf("Usage: all <on/off>\r\n");
                    }
                    else if (strcmp(arg1, "on") == 0) {
                        current_led_state = 0x0F;
                        printf("ALL ON\r\n");
                    }
                    else if (strcmp(arg1, "off") == 0) {
                        current_led_state = 0x00;
                        printf("ALL OFF\r\n");
                    }
                    else {
                        printf("Use: all on/off\r\n");
                    }
                }

                else if (cmd && strcmp(cmd, "help") == 0) {
                    printf("Commands:\r\n");
                    printf(" led <0-3> <on/off>\r\n");
                    printf(" all <on/off>\r\n");
                    printf(" help\r\n");
                }

                else {
                    printf("Invalid command\r\n");
                }

                XGpio_DiscreteWrite(&Gpio, 1, current_led_state);
            }

            buf_idx = 0;
            printf(">> ");
        }

        // 2. 백스페이스
        else if (input_char == 8 || input_char == 127) {
            if (buf_idx > 0) {
                buf_idx--;

                XUartPs_SendByte(XPAR_PS7_UART_1_BASEADDR, '\b');
                XUartPs_SendByte(XPAR_PS7_UART_1_BASEADDR, ' ');
                XUartPs_SendByte(XPAR_PS7_UART_1_BASEADDR, '\b');
            }
        }

        // 3. 일반 입력
        else {
            if (buf_idx < MAX_BUFFER_SIZE - 1) {
                buffer[buf_idx++] = input_char;
                XUartPs_SendByte(XPAR_PS7_UART_1_BASEADDR, input_char);
            }
        }
    }

    return 0;
}