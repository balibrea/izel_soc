
#define CLK_FREQ 100000000

#include "stdarg.h"

#include "./libs/uart.h"
#include "./libs/zpio.h"
//#include "./libs/spi.h"
//#include "./libs/vga.h"
//#include "minfat.h"
#include "./libs/small_printf.h"



int __modsi3(int a, int b){
	int i = 0;
	int c;
	while(i <= a){
		c = b*i;
		if(c==a){
			return 0;
		}else if(c > a){
			c = b*(i-1);
			return a-c;
		}
		i++;
	}
}


int __divsi3(int a, int b){
	unsigned int i = 0;
	int c;
	short f = 0;
	short r;
			
	while(i <= a){
		c = b*i;
		if(c==a){
			return i; //resto 0
		}else if(c > a){
			c = b*(i-1);
			r = a-c;
			break;
		}
		i++;
	}
		
	if(r>5){
		return c++;
	}else{
		return c;
	}	
}


int __udivsi3(int a, int b){
	return __divsi3(a, b);
}

int __umodsi3(int a, int b){
	return __modsi3(a, b);
}



void _boot();
void _break();


int main(int argc,char **argv)
{

	//char a;
	//small_printf("\nDemo A + B sobre el JTAG terminal.\n");
	printf("Timer test\n");
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
