# ClassicOS 64 bit Documentation

This is ClassicOS's 64 bit edition documentation.

## About

This OS supports legacy 64 bit Intel x86 CPU's as found in the target_cpus.md document. 
While not specifically the scope of this OS, it could eventually support legacy AMD amd64 CPU's.
This could also eventually support Itanium and Itanium2.

This custom operating system:

Uses AT&T Assembly syntax
Makes every attempt to be C98/C99 and C11 compliant to stay in the era of these CPU's
Uses a kernel.bin to boot.
Boots with GRUB2 and uses the Multiboot2 specification and the header file `multiboot2.h` in the include directory 
The kernel is written in C, the filename is kmain.c in /src and the function is kmain();
Makes every attempt to follow POSIX, Unix and Linux best practices, etc.
Is fully open source

## Developer Documentation

Intel has official documentation here: <https://www.intel.com/content/www/us/en>

Most of them live here: <https://www.intel.com/content/www/us/en/developer/articles/technical/intel-sdm.html>

In this directory, you'll find several files containing the necessary information to help you use and
develop this operating system.

Please make every attempt to reference this documentation.

