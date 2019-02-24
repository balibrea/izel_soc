#include "zpio.h"

#ifdef ZPIO_H

int ioWrite(int c)
{
	HW_IO(REG_IO)=c;
	return(c);
}


int ioRead()
{
	int r;
	r = HW_IO(REG_IO);
	return(r);
}

unsigned int millis(){
	volatile unsigned int * ms = (volatile unsigned int *)0xFFFFFFC8;
	int time;
	time = *ms;
	return(time);
}

#endif
