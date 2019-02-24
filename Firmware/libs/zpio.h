#ifndef ZPIO_H
#define ZPIO_H

/* Hardware registers for a supporting UART to the ZPUFlex project. */

#ifdef __cplusplus
extern "C" {
#endif

#define GPIOBASE 0xFFFFFFB4

#define HW_IO(x) *(volatile unsigned int *)(GPIOBASE + x)

#define REG_IO 0x0

int ioWrite(int c);

int ioRead();

unsigned int millis();

#ifdef __cplusplus
}
#endif

#endif

