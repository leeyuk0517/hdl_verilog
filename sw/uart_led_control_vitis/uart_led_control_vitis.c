/*
uart_led_control_vitis 
0123 q 시리얼 통신 입력받아서 그번호에 맞는 led 켜기 q 모두 끄기 


*/



#include <stdio.h>
#include "xparameters.h"
#include "xgpio.h"
#include "xuartps.h" // PS UART용 헤더
#include "xstatus.h"  // XSUCCESS, XST_FAILURE 등이 정의된 파일

// 하드웨어 주소값 정의 (Vivado에서 설정한 이름들)
#define GPIO_DEVICE_ID  XPAR_AXI_GPIO_0_DEVICE_ID
#define UART_DEVICE_ID  XPAR_PS7_UART_1_DEVICE_ID

XGpio Gpio; // GPIO 인스턴스

int main() {
    u8 input_char;
    int Status;

    // 1. GPIO 초기화 (LED 제어용)
    Status = XGpio_Initialize(&Gpio, GPIO_DEVICE_ID);
    if (Status != 0) return -1; // XSUCCESS 대신 0, XST_FAILURE 대신 -1

    // GPIO 채널 1을 '출력'으로 설정 (0은 출력, 1은 입력)
    XGpio_SetDataDirection(&Gpio, 1, 0x0);

    printf("--- Zybo Z7-20 LED Control Start ---\r\n");
    printf("Press 0~3 to turn on LED, 'q' to turn off all.\r\n");

    while(1) {
        // 2. UART로부터 1바이트 읽기 (Blocking 방식)
        // 이 함수는 키보드 입력이 들어올 때까지 여기서 기다립니다.
        input_char = XUartPs_RecvByte(XPAR_PS7_UART_1_BASEADDR);

        // 읽은 글자를 다시 화면에 출력 (Echo)
        printf("Received: %c\r\n", input_char);

        // 3. 입력값에 따른 LED 로직
        if (input_char == '0') {
            XGpio_DiscreteWrite(&Gpio, 1, 0x01); // 0001
        }
        else if (input_char == '1') {
            XGpio_DiscreteWrite(&Gpio, 1, 0x02); // 0010
        }
        else if (input_char == '2') {
            XGpio_DiscreteWrite(&Gpio, 1, 0x04); // 0100
        }
        else if (input_char == '3') {
            XGpio_DiscreteWrite(&Gpio, 1, 0x08); // 1000
        }
        else if (input_char == 'q') {
            XGpio_DiscreteWrite(&Gpio, 1, 0x00); // 모두 끔
            printf("All LEDs OFF!\r\n");
        }
    }

    return 0;
}
