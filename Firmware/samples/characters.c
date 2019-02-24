
#define CLK_FREQ 100000000

#include "stdarg.h"

#include "./libs/uart.h"
//#include "./libs/spi.h"
//#include "./libs/vga.h"
//#include "minfat.h"
#include "./libs/small_printf.h"


void _boot();
void _break();


static unsigned char Manifest[2048];

int main(int argc,char **argv)
{

	char a;
	small_printf("\nHola estoy probando el JTAG terminal.\n");
	
	while(1)
	{
		puts("Un caracter: ");
		a = getserial();
		small_printf("\nHas escrito: %c. \n", a);
	}

	return(0);
}
