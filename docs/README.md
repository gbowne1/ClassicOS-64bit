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

The relevant document numbers are:

| Volume        | Description                      | Order Number |
| ------------- | -------------------------------- | ------------ |
| **Volume 1**  | Basic Architecture               | `253665`     |
| **Volume 2A** | Instruction Set Reference, A–L   | `253666`     |
| **Volume 2B** | Instruction Set Reference, M–U   | `253667`     |
| **Volume 2C** | Instruction Set Reference, V     | `326018`     |
| **Volume 3A** | System Programming Guide, Part 1 | `253668`     |
| **Volume 3B** | System Programming Guide, Part 2 | `253669`     |
| **Volume 3C** | System Programming Guide, Part 3 | `326019`     |
| **Volume 3D** | System Programming Guide, Part 4 | `332831`     |
| **Volume 4**  | Model-Specific Registers (MSRs)  | `335592`     |

In this directory, you'll find several files containing the necessary information to help you use and
develop this operating system.

Please make every attempt to reference this documentation.

