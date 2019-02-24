#include "stdarg.h"

#include "./libs/uart.h"
#include "./libs/zpio.h"
//#include "./libs/spi.h"
//#include "./libs/vga.h"
//#include "minfat.h"
#include "./libs/small_printf.h"


void _boot();
void _break();

int serial_available(void)
{
	int r = HW_UART(REG_UART);
	if(!(r & 256)){ //hay datos disponibles
		return 1;
	}
	return 0;
}

#define USER_ID 33

int main(int argc,char **argv)
{
	char a;
	int stat = 0;
	short timeout = 30;
	short cnt = 5;
	int last_m = millis();
	int ms;
	
	while(1){
		
		//Read from USB
		if(serial_available()){
			a = getserial();
			printf("ID: %c \n",a);
				
			//Detect user request
			if(a == USER_ID){
				stat = 0x8000;
				timeout = 30;
				printf("Usuario con ID: %c ha sido detectado.\n",a);
			}
			else{
				printf("ID desconocido, apagando sistema en:\n");
				stat = 0;
				printf("Shutdown.\n");			}		
		}	

		if(a == USER_ID){
			ms = millis();
			if((ms - last_m >= 1000) && timeout){
				last_m = ms;
				cnt --;				
			}		
		}else{
			cnt = 5;
		}	

		
		while(!cnt){
			if(serial_available()){
				a = getserial();
				printf("ID: %c \n",a);
				break;
			}
				
			ms = millis();
			if((ms - last_m >= 1000) && timeout){
				last_m = ms;
				timeout --;
				printf("%d ...\n", timeout);
				ioWrite(timeout | stat);
			}
			if(!timeout){
				stat = 0;
				cnt = 5;
				printf("Shutdown.\n");
				break;
			}
		}			
					
		//Trun On or Off the device
		ioWrite(timeout | stat);
	}
	
}
