#include <stdio.h>
#include <string.h>
#include<stdlib.h>
#include "xparameters.h"
#include "xgpio.h"
#include "xuartps.h"

#define MAX_BUFFER_SIZE 100

XGpio Gpio;

int main() {
    u8 input_char;
    char buffer[MAX_BUFFER_SIZE];
    int buf_idx = 0;
    u32 current_led_state= 0x00;

    XGpio_Initialize(&Gpio, XPAR_AXI_GPIO_0_DEVICE_ID);
    XGpio_SetDataDirection(&Gpio, 1, 0x0);

    printf("\r\n -- zybo z7 20 direct parser cli ------ \r\n");
    printf("Usage: led <num> <on/off>, all <on/off>, help \r\n");
    printf(">>");

    while(1){
        input_char = XUartPs_RecvByte(XPAR_PS7_UART_1_BASEADDR);

        if(input_char == '\r' || input_char == '\n'){
            buffer[buf_idx]='\0';
            printf("\r\n");

            if(buf_idx >0) {
                char *cmd = NULL;
                char *arg1= NULL;
                char *arg2= NULL;

                char *p = buffer;

                while(*p== ' ')p++;
                if(p*!='\0'){
                    cmd = p;
                    while(*p!= ' ' && *P != '\0') p++;
                    if(*p!='\0'){
                        *p='\0';
                        p++;

                    }    
                    

                }
                while(*p== ' ') p++;
                if(*p != '\0'){
                    arg1 = p;
                    while(*p!=' '&& *p != '\0')p++;
                    if(*p!='\0'){
                        *p='\0';
                        p++;
                    }
                }
                while(*p== ' ') p++;
                if(p*!= '\0'){
                    arg2=p;
                    while(*p != ' ' && *p != '\0')p++;
                    if(*p != '\0'){
                        *p='\0';
                    }
                }

                if(cmd && strcmp(cmd, "led") == 0){

                    if(arg1 == NULL || arg2 == NULL){
                        printf("usage: led <0-3> <on/ off> \r\n");
                    } else{
                        char *end;
                        long led_num = strtol(arg1, &end, 10);

                        if(*end != '\0'){
                            printf("Invalid number \r\n");
                        }
                        else if(led_num <0 || led_num >3){
                            printf("LED number must be 0~3 \r\n");

                        }
                        else{
                            if(strcmp(arg2, "on")==0){
                                currnet_led_state &= ~(1 << led_num);
                                printf("LED %ld OFF\r\n", led_num);
                            }
                            else {
                                printf("Use on/off\r\n");
                            }
                        }
                    }
                    
                }
                else if(cmd && strcmp(cmd, "all")==0){
                    if(arg1==NULL){
                        printf("usage: all <on/off> \r\n");
                    }
                    else if(strcmp(arg1, "on") == 0){
                        current_led_state = 0x0f;
                        printf("ALL ON\r\n" );

                    }
                    else if(strcmp(arg1, "off")==0){
                        currnet_led_state=0x00;
                        printf("All OFF \r\n");
                    }
                    else {
                        printf("use: all on/off\r\n");
                    }
                }
                else if(cmd && strcmp(cmd, "help")==0){
                    printf("command: \r\n");
                    printf(" ked <0-3> on off \r\ ")
                }
            }
                else {
                    printf("invalid command\r\n");
                }
                XGpio_DiscreateWrite(&Gpio, 1, current_led_state);
        }
        buf_idx=0;
        printf(">>");
    }

    else i
}