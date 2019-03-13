#include "stdarg.h"
#include "./libs/uart.h"
#include "./libs/zpio.h"
#include "./libs/spi.h"
#include "./libs/small_printf.h"
#include "./libs/fat_filelib.h"


//~ float __floatsisf(){
    //~ return 0;
//~ }


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

#define size 0x40000

int main()
{
    char *ptr = 0x102004;
    int r;

    int opt;
    printf("GPIO0 Boot options:\n");
    printf("0 : Boot from SD card\n");
    printf("1 : Boot from JTAG\n");
    opt = ioRead()&0x0001;

    if(!opt){
        printf("Booting from SD card\n");
        // Initialise media
        spi_init();

        FL_FILE *file;

        // Initialise File IO Library
        fl_init();

        // Attach media access functions to library
        if (fl_attach_media(media_read, media_write) != FAT_INIT_OK)
        {
        printf("ERROR: Media attach failed\n");
        return 1;
        }

        printf("Listing directories...\n\n");

        // List root directory
        fl_listdirectory("/");

        // Read File
        //int valid = 0;
        while(1){
            char app_file[15];
            printf("\nAPP FILE >> ");
            scan(app_file, 14, 0);
            file = fl_fopen(app_file, "rb");
            if (file)
            {
                // read
                r = fl_fread(ptr, 1, size, file);
                printf("\n %d bytes read\n", r);
                break;
            }
            else
                printf("\nERROR: Read file failed\n");
        }
        fl_fclose(file);
        fl_shutdown();

    }else{
        // TODO
        printf("Booting from JTAG, waiting for uploader\n");
        int file_len = get_number();
        char in_byte[file_len];
        scan(in_byte, file_len, 0);
        printf("\nEND");
        printf(in_byte);
    }

    int *code = 0x00;//0x102004;

    //printf(data);
    int i=0;
    for(i; i<size/4;i++){
        int d = (*(ptr+(i*4)+3)<<24) | (*(ptr+(i*4)+2)<<16) | (*(ptr+(i*4)+1)<<8) | *(ptr+(i*4));
        d = (d&0xff000000)>>24 | (d&0x00ff0000)>>8 | (d&0x0000ff00)<<8 | (d&0x000000ff)<<24;
        *(code+i) = d;
    }

    printf("\n\nEnd... \n");

    //_boot();

    printf("shutdown.\n");
    return 0;
}
