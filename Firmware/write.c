#include "stdarg.h"
#include "./libs/uart.h"
//#include "./libs/zpio.h"
#include "./libs/spi.h"
#include "./libs/small_printf.h"
#include "./libs/fat_filelib.h"
//#include "./libs/vga.h"


int __modsi3(int a, int b){
    //~ while(a < b){
        //~ a = a * 10;
        //~ //printf("por 10\n");
    //~ }

    int i = 0;
    int c;
    while(i <= a){
        //printf("ronda %d\n", i);
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
    //int c = a%b;
    //printf("modulo de %d y %d es: %d", a,b, a%b);

    unsigned int i = 0;
    int c;
    short f = 0;
    short r;

    while(i <= a){
        //printf("ronda %d\n", i);
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



int main()
{
    FL_FILE *file;
    char data[80];

    // Initialise media
    spi_init();

    // Initialise File IO Library
    fl_init();

    printf("Write file demo program\n");

    // Attach media access functions to library
    if (fl_attach_media(media_read, media_write) != FAT_INIT_OK)
    {
        printf("ERROR: Media attach failed\n");
        return 1;
    }

    // Create File
    printf("Create /log.txt file\n");
    file = fl_fopen("/log.txt", "wb");
    printf("file created\n");
    if (file)
    {
        // Write some data
        printf("Write some data to put in the file:\n");
        scan(data, 80, 0);
        if (fl_fwrite(data, 1, sizeof(data), file) != sizeof(data))
            printf("ERROR: Write file failed\n");
    }
    else
        printf("ERROR: Create file failed\n");

    // Close file
    printf("Closing file\n");
    fl_fclose(file);

    printf("File closed, listing directories\n");

    fl_listdirectory("/");

    return 0;
}

