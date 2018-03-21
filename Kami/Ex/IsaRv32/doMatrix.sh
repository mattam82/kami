#!/bin/bash
set -e

COMP=riscv32-unknown-elf-gcc
OBJDUMP=riscv32-unknown-elf-objdump

$COMP -nostartfiles -nodefaultlibs -nostdlib -static -s -T config.ld matmul_init.c
$OBJDUMP -d a.out > matmul_init.dmp
$COMP -nostartfiles -nodefaultlibs -nostdlib -static -s -T config.ld matmul_normal1.c
$OBJDUMP -d a.out > matmul_normal1.dmp
$COMP -nostartfiles -nodefaultlibs -nostdlib -static -s -T config.ld matmul_normal2.c
$OBJDUMP -d a.out > matmul_normal2.dmp
$COMP -nostartfiles -nodefaultlibs -nostdlib -static -s -T config.ld matmul_report.c
$OBJDUMP -d a.out > matmul_report.dmp
./BinaryToKamiPgm.native matmul_init.dmp > Matmul_init.v
./BinaryToKamiPgm.native matmul_normal1.dmp > Matmul_normal1.v
./BinaryToKamiPgm.native matmul_normal2.dmp > Matmul_normal2.v
./BinaryToKamiPgm.native matmul_report.dmp > Matmul_report.v
rm a.out
