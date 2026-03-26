/*
파싱 추가 led 0 1 명령   all on  all off 제어  
 현재 led 유지 기능 없음 추가 예정 
*/

#include <stdio.h>
#include <string.h> // 문자열 비교 함수 strcmp, strtok 사용을 위해 추가
#include "xparameters.h"
#include "xgpio.h"
#include "xuartps.h"

#define MAX_BUFFER_SIZE 100 // 명령어를 담을 바구니 크기

XGpio Gpio;

int main() {
    u8 input_char;
    char buffer[MAX_BUFFER_SIZE];
    int buf_idx = 0;

    XGpio_Initialize(&Gpio, XPAR_AXI_GPIO_0_DEVICE_ID);
    XGpio_SetDataDirection(&Gpio, 1, 0x0);

    printf("\r\n--- Zybo Z7-20 Command Parser Ready ---\r\n");
    printf("Commands: 'led0 on', 'led1 on', 'all off', 'all on'\r\n");
    printf(">> "); // 프롬프트 표시

    while(1) {
        // 1. UART로 1바이트 읽기
        input_char = XUartPs_RecvByte(XPAR_PS7_UART_1_BASEADDR);

        // 2. 엔터키(CR: \r 또는 LF: \n) 확인
        if (input_char == '\r' || input_char == '\n') {
            buffer[buf_idx] = '\0'; // 문자열의 끝을 알리는 NULL 추가
            printf("\r\n"); // 줄바꿈

            // 3. 명령어 해석 (Parser)
            if (strcmp(buffer, "led0 on") == 0) {
                XGpio_DiscreteWrite(&Gpio, 1, 0x01);
                printf("Success: LED 0 is now ON\r\n");
            }
            else if (strcmp(buffer, "led1 on") == 0) {
                XGpio_DiscreteWrite(&Gpio, 1, 0x02);
                printf("Success: LED 1 is now ON\r\n");
            }
            else if (strcmp(buffer, "all on") == 0) {
                XGpio_DiscreteWrite(&Gpio, 1, 0x0F);
                printf("Success: All LEDs are ON\r\n");
            }
            else if (strcmp(buffer, "all off") == 0) {
                XGpio_DiscreteWrite(&Gpio, 1, 0x00);
                printf("Success: All LEDs are OFF\r\n");
            }
            else if (strlen(buffer) > 0) {
                printf("Error: Unknown command [%s]\r\n", buffer);
            }

            // 4. 다음 명령어를 위해 버퍼 초기화
            buf_idx = 0;
            printf(">> ");
        }
        else {
            // 엔터가 아니면 버퍼에 쌓기 (백스페이스 처리 생략 - 단순화)
            if (buf_idx < MAX_BUFFER_SIZE - 1) {
                buffer[buf_idx++] = input_char;
                XUartPs_SendByte(XPAR_PS7_UART_1_BASEADDR, input_char); // 내가 친 글자 화면에 보여주기 (Echo)
            }
        }
    }
    return 0;
}
