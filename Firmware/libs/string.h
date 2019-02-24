/* string.h */
/* 2012, rok.krajnc@gmail.com */

#ifndef __STRING_H__
#define __STRING_H__

//#include "hardware.h"

typedef unsigned int size_tt;

// basic string functions
extern size_tt strlen(const char *s);
extern char *strcpy(char *dest, const char *src);
extern char *strncpy(char *dest, const char *src, size_tt n);
extern char *strcat(char *dest, const char *src);
extern char *strncat(char *dest, const char *src, size_tt n);
extern int strcmp(const char *s1, const char *s2);
extern int strncmp(const char *s1, const char *s2, size_tt n);
extern char *strchr(const char *s, int c);
extern char *strrchr(const char *s, int c);

// basic mem functions
extern void *memcpy(void *dest, const void *src, size_tt n);
extern void *memmove(void *dest, void *src, size_tt n);
extern int memcmp(const void *s1, const void *s2, size_tt n);
extern void *memchr(const void *s, int c, size_tt n);
extern void *memset(void *d, int c, size_tt n);

char *next_word(char *c);


#endif // __STRING_H__

