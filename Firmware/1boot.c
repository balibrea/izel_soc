/*
 * boot.c
 * 
 * Copyright 2019 Yosel de Jesús Balibrea Lastre <yosel.balibrea@reduc.edu.cu>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 * MA 02110-1301, USA.
 * 
 * 
 */
 
#include "stdarg.h"
#include "./libs/uart.h"
//#include "./libs/zpio.h"
#include "./libs/spi.h"
#include "./libs/small_printf.h"
#include "./libs/fat_filelib.h"


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

#define size 0x10000

int main()
{
    FL_FILE *file;
    
    char *ptr = 0x102004;
    int r;
    
    printf("\n\nBootloader is too big to be stored in internal ROM \nLoading it from SD card.\n");
    
    // Initialise media
    spi_init();

    // Initialise File IO Library
    fl_init();
    
    // Attach media access functions to library
    if (fl_attach_media(media_read, media_write) != FAT_INIT_OK)
    {
        printf("ERROR: Media attach failed\n");
        return 1; 
    }	
	    
    // Read File
    file = fl_fopen("/app2.bin", "rb");
    if (file)
    {
        // read
        r = fl_fread(ptr, 1, size, file);
        printf("\n %d bytes read\n", r);        
    }
    else{
        printf("ERROR: Can not find bootloader file.\n"); 
        return -1;
	}     
			
	//printf(data);
    int i=0;
    
    for(i; i<size/4;i++){
		int d = (*(ptr+(i*4)+3)<<24) | (*(ptr+(i*4)+2)<<16) | (*(ptr+(i*4)+1)<<8) | *(ptr+(i*4));
		d = (d&0xff000000)>>24 | (d&0x00ff0000)>>8 | (d&0x0000ff00)<<8 | (d&0x000000ff)<<24;
		*(ptr+i) = d;				
	} 
                            
    fl_fclose(file);
    fl_shutdown();
    printf("booting...\n");
    
    _boot();
    
    return 0;
}

