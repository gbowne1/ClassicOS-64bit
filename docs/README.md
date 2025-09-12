# Experimental ClassicOS 64 bit

Compile this only on a 64 bit native host

- grub 2.02 to 2.06 
- gcc 8.3 to 15.1
- ld from binutils 2.42
- nasm 2.16.01
- gdb 8.1 => 10.1
- coreutils (for dd) 8.30 => 8.32
- grub2-common
- xorriso
- schillytools (I used source from schily?2020?11?25.tar.bz2)
- genisoimage in cdrkit v1
- QEMU qemu-system-x86_64 10.1.x (qemu-system-x86 package?)
- TigerVNC 1.9.0 through 1.11.0
- RealVNC 3.x / 6.x
- Xming (on Windows)
- use whatever IDE

## Target CPU's

Pentium D
Pentium Dual Core
Pentium 1400 series
Core 2 Duo
Pentium 4 (after Willamette?)
Pentium Extreme Edition
Celeron D
Core 2 Quad
Core 2 Extreme
Core i3 1st through 3rd Gen
Core i5 1st through 3rd Gen
Core i7 1st through 3rd Gen
Xeon (Other legacy 32/64bit Xeon's not mentioned below)
Xeon E3-12xx
Xeon E122x
Xeon E2xxx
Xeon E4-26xx
Xeon E5-26xx
Xeon E5-4xxx
Xeon E5-5xxx
Xeon L5xxx
Xeon X
Xeon W

## Compile the kernel
gcc -c kmain.c -o kmain.o -ffreestanding -fno-pie (also try with -m64 flag)

also try adding -nostdlib, -fno-pic, -fno-stack-protector, -mno-red-zone, -O0 to -O2 for debug

## Link the kernel
ld -T linker.ld -o kernel.bin kmain.o

## grub2
grub-mkrescue -o myos.iso iso
grub-mkrescue -o myos.iso iso/

where -o stands for output

make sure the kernel bin is in the /boot as in /boot/kernel.bin
grub config file goes in /boot/grub/
the iso can go in /iso/boot/grub/?

can we use grub-file --is-x86-multiboot2 <kernelfilehere>?

GRUB2 searches the ISO filesystem starting from the root.

iso/
??? boot/
    ??? kernel.bin        # Your Multiboot2-compliant kernel
    ??? grub/
        ??? grub.cfg      # GRUB config file

Is the .iso required?

? Yes, if you want to boot using an emulator (like QEMU/VirtualBox) or write to USB

? No, if you're booting your kernel in another way (e.g., via direct BIOS load or custom bootloader)

## QEMU testing

you'll probably need qemu-desktop or qemu-system-x86

qemu-system-x86_64 -cdrom myos.iso
qemu-system-x86_64 -cdrom myos.iso -vga std
qemu-system-x86_64 -cdrom myos.iso -vga std -no-reboot -no-shutdown
qemu-system-x86_64 -cdrom myos.iso -d int,cpu -no-reboot > qemu_log.txt (and with 2>&1)

if the kernel isn't working try `qemu-system-x86_64 -cdrom myos.iso -monitor stdio`

To test the other CPUs we tartget, use the -cpu flag(s):

-cpu Nehalem, -cpu SandyBridge or -cpu IvyBridge

some might also need -smp 2 or -smp 4 (these are the number of cores)

You could also try
qemu-system-x86_64 -cdrom myos.iso -d int -no-reboot -no-shutdown

We could also qemu-system-x86_64 -cdrom classicos.iso -s -S if we have debug symbols.

Since the goal here is to primarily support older CPU's..
qemu-system-x86_64 -cpu core2duo -cdrom classicos.iso
qemu-system-x86_64 -cpu pentium4 -cdrom classicos.iso

The help for that is here: qemu-system-x86_64 -cpu help

Check if rax contains 0x36d76289 in _start to confirm Multiboot2 loading

`qemu-system-x86_64 -kernel your_kernel.elf -s -S`

this assumes we have a .elf

from there we can:

gdb your_kernel.elf
(gdb) target remote localhost:1234
(gdb) b _start
(gdb) c
(gdb) info registers rax

we should see `rax            0x36d76289`

if we `qemu-system-x86_64 -cdrom myos.iso -s -S` it still uses the same except its just gdb not gdb your_kernel.elf

on real hardware use a USB stick and write the iso to it with:
sudo dd if=myos.iso of=/dev/sdX bs=4M; sync
sudo dd if=myos.iso of=/dev/sdX bs=4M status=progress && sync

where /dev/sdX is whatever USB you have inserted.

if nothing else works hexdump and objdump will help

hexdump -C -n 64 kernel.bin | grep 'd6 50 52 e8' to see if it got multiboot.
hexdump -C kernel.bin | head -n 20 for full early bytes.

GRUB needs a valid Multiboot2 header, placed within the first 32 KiB of the file.

readelf -h kernel.bin to Check ELF headers (should be 64-bit).
file kernel.bin will confirm "ELF 64-bit LSB executable".

grub-install --target=i386-pc /dev/null

see: https://wiki.osdev.org/Creating_a_64-bit_kernel and forum.osdev.org
