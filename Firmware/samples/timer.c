
#define CLK_FREQ 100000000

#include "stdarg.h"

#include "./libs/uart.h"
#include "./libs/zpio.h"
//#include "./libs/spi.h"
//#include "./libs/vga.h"
//#include "minfat.h"
#include "./libs/small_printf.h"


void _boot();
void _break();


int main(int argc,char **argv)
{

	//char a;
	//small_printf("\nDemo A + B sobre el JTAG terminal.\n");
	int last_m = millis();
	int ms;
	
	while(1)
	{
		ms = millis();
		if(ms - last_m >= 1000){
			last_m = ms;
			puts("HOLA\n");
		}
		//a = getserial();
		//small_printf("\nHas escrito: %c. \n", a);
		ioWrite(millis());
	}

	return(0);
}
