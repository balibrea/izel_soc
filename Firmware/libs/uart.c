#include "uart.h"

#ifndef DISABLE_UART_TX
__inline int putchar(int c)
{
	//while(!(HW_UART(REG_UART)&(1<<REG_UART_TXREADY)))
	while((HW_UART(REG_UART)&(1<<9)));
	
	HW_UART(REG_UART)=c;
	return(c);
}


int puts(const char *msg)
{
	int c;
	int result=0;
	// Because we haven't implemented loadb from ROM yet, we can't use *<char*>++.
	// Therefore we read the source data in 32-bit chunks and shift-and-split accordingly.
	int *s2=(int*)msg;

	do
	{
		int i;
		int cs=*s2++;
		for(i=0;i<4;++i)
		{
			c=(cs>>24)&0xff;
			cs<<=8;
			if(c==0)
				return(result);
			putchar(c);
			++result;
		}
	}
	while(c);
	return(result);
}
#endif

#ifndef DISABLE_UART_RX
char getserial()
{
	int c, r;
	
	while(1){
		r = HW_UART(REG_UART);
		if(!(r & 256)){ //hay datos disponibles
			r = HW_UART(REG_UART);
			c = r & 255;
			break;
		}
	}

	return(c);
}


int scan(char *buffer, int max_size, int echo){
	char c = 0;
	int length = 0;

	while (1) {
		c = getserial();
		
		if (c == '\b') { // BACKSPACE
			if (length > 0) {
				if (echo) {
					puts("\b \b"); // delete last char in console
				}
				buffer--;
				length--;
			}
		}
		else if (c == '\r')// ENTER
			break;
		else if ((c >= ' ') && (c <= '~')) {
			if (echo) {
				putchar(c); // echo
			}
			*buffer++ = c;
			length++;
		}
  }
  *buffer = '\0'; // terminate string

  return length;
	
}

int get_number(){
	char a[9];
	int i, val = 0;
	int d = 0;
	int r = 1;
	scan(a, 8, 0);
	
	for(i = 0; i<8; i++){
		if(a[i] >= 48 && a[i] <= 57){
			d++;			
		}
	}
	
	while(d > 0){
		val += (a[d-1] - 48)*r;
		r *= 10;
		d--;
	}
	return val;
}
#endif

