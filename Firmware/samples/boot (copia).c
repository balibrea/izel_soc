
#define CLK_FREQ 100000000

#include "stdarg.h"

#include "./libs/uart.h"
#include "./libs/spi.h"
#include "./libs/vga.h"
#include "./libs/zpio.h"
#include "minfat.h"
#include "./libs/small_printf.h"

//#define use_fbptr2

#define framebuffer_addr 0x10000
#define framebuffer_addr2 (0x10000 + 648*480*2)

void spin()
{
	int s;
	int x;
	int y;
	for(s=0;s<5;++s)
	{
		// Spin for a while
		for(y=0;y<480;++y)
		{
			for(x=0;x<640;x+=2)
			{
				int t=HW_VGA(FRAMEBUFFERPTR); // Dummy read
			}
		}
	}
}

int patern(int xpos, int ypos){
	//int r,g,b;
	int x,y;
	short *fbptr=(short *)framebuffer_addr;
	
#ifdef use_fbptr2
	short *fbptr2=(short *)framebuffer_addr2;
#endif

	HW_VGA(FRAMEBUFFERPTR)=framebuffer_addr;

	for(y=0;y<480;++y)
	{
		for(x=0;x<640;++x)
		{
			//~ int t;
			//~ r=(x>>4)&31;
			//~ g=(y>>4)&63;
			//~ b=((x+y)>>4)&31;
			//~ t=(r<<11)|(g<<5)|b;				
			
			if(x >= xpos && x<= 150 + xpos && y >= ypos && y <= 150 + ypos){
				*fbptr++=0xffff;
#ifdef use_fbptr2
				*fbptr2++=0xffff;
#endif
			}else{
				*fbptr++=0x000f;
#ifdef use_fbptr2
				*fbptr2++=ioRead();
#endif
				ioWrite(ioRead());
				//*fbptr++=t;
				//*fbptr2++=~t;
			}			
			
		}
	}
	return 0;
}

int main(int argc, char **argv)
{
	int xpos = 0;
	int ypos = 0; 
	//printf("VGA Framebuffer test\n");

	// Write a repeating pattern to the framebuffer
	
	//printf("Filled screen - toggling framebuffer\n");
	while(1)
	{
		patern(xpos, ypos);
		//if(!busy){
		HW_VGA(FRAMEBUFFERPTR)=framebuffer_addr2;
		//}
		//spin();
		//printf("Buffer 2\n");
		
#ifdef use_fbptr2
		spin();
		//printf("Buffer 1\n");
		HW_VGA(FRAMEBUFFERPTR)=framebuffer_addr;
#endif
		
		ypos += 5;
		xpos += 5;
		
		if((ypos >= 480-150) || (xpos >= 640-150)){
			ypos = 0;
			xpos = 0;
		}
	}

	return(0);
}
