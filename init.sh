#! /usr/bin/env bash

rm *.o
rm *.out

nasm -f elf32 ./RC4.asm
gcc -m32 ./RC4.o -o ./RC4_asm.out

gcc ./RC4.c -o ./RC4_c.out


