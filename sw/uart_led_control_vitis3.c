/*
led  uart명령어 제어  
파싱 및 led 기억 추가 
유지 추가 

*/

#include <stdio.h>
#include <string.h>
#include "xparameters.h"
#include "xgpio.h"
#include "xuartps.h"

#define MAX_BUFFER_SIZE 100

XGpio Gpio;

int main() {
    u8 input_char;
    char buffer[MAX_BUFFER_SIZE];
    int buf_idx = 0;

    // 핵심: 현재 LED 상태를 비트 단위로 저장할 변수 (초기값 0)
    u32 current_led_state = 0x00;

    XGpio_Initialize(&Gpio, XPAR_AXI_GPIO_0_DEVICE_ID);
    XGpio_SetDataDirection(&Gpio, 1, 0x0); // 출력 설정

    printf("\r\n--- Zybo Z7-20 Smart LED Controller ---\r\n");
    printf("Commands: 'ledX on/off' (X=0~3), 'all on/off'\r\n");
    printf(">> ");

    while(1) {
        input_char = XUartPs_RecvByte(XPAR_PS7_UART_1_BASEADDR);

        if (input_char == '\r' || input_char == '\n') {
            buffer[buf_idx] = '\0';
            printf("\r\n");

            // --- LED 0 제어 ---
            if (strcmp(buffer, "led0 on") == 0) {
                current_led_state |= 0x01; // 1번째 비트(0001)만 1로 만듦
            }
            else if (strcmp(buffer, "led0 off") == 0) {
                current_led_state &= ~0x01; // 1번째 비트(1110과 AND)만 0으로 만듦
            }
            // --- LED 1 제어 ---
            else if (strcmp(buffer, "led1 on") == 0) {
                current_led_state |= 0x02; // 2번째 비트(0010)만 1로 만듦
            }
            else if (strcmp(buffer, "led1 off") == 0) {
                current_led_state &= ~0x02; // 2번째 비트만 0으로 만듦
            }
            // --- LED 2 제어 ---
            else if (strcmp(buffer, "led2 on") == 0) {
                current_led_state |= 0x04; // 3번째 비트(0100)만 1로 만듦
            }
            else if (strcmp(buffer, "led2 off") == 0) {
                current_led_state &= ~0x04;
            }
            // --- LED 3 제어 ---
            else if (strcmp(buffer, "led3 on") == 0) {
                current_led_state |= 0x08; // 4번째 비트(1000)만 1로 만듦
            }
            else if (strcmp(buffer, "led3 off") == 0) {
                current_led_state &= ~0x08;
            }
            // --- 전체 제어 ---
            else if (strcmp(buffer, "all on") == 0) {
                current_led_state = 0x0F; // 1111
            }
            else if (strcmp(buffer, "all off") == 0) {
                current_led_state = 0x00; // 0000
            }
            else if (strlen(buffer) > 0) {
                printf("Unknown Command: [%s]\r\n", buffer);
            }

            // 최종적으로 계산된 비트 값을 하드웨어(GPIO)에 한 번에 씀
            XGpio_DiscreteWrite(&Gpio, 1, current_led_state);
            printf("LED State: [Hex:0x%X] [Bin:", (unsigned int)current_led_state);
            // 간단하게 2진수 상태 보여주기
            for(int i=3; i>=0; i--) printf("%d", (int)((current_led_state >> i) & 1));
            printf("]\r\n>> ");

            buf_idx = 0;
        }
        else {
            if (buf_idx < MAX_BUFFER_SIZE - 1) {
                buffer[buf_idx++] = input_char;
                XUartPs_SendByte(XPAR_PS7_UART_1_BASEADDR, input_char);
            }
        }
    }
    return 0;
}
