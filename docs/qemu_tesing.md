To test this operating system you'll probably need `qemu-desktop` or `qemu-system-x86`
but please check your package manager for details on which packages will give 
`qemu-system-x86_64`

QEMU's documentation is at

<https://www.qemu.org/documentation/>

There's a wiki too.

Here are some commands that should get us to testing the boot and kernel.
Replace myos.iso with the iso created in grub2_setup.md instructions.

`qemu-system-x86_64 -cdrom myos.iso`

`qemu-system-x86_64 -cdrom myos.iso -vga std`

`qemu-system-x86_64 -cdrom myos.iso -vga std -no-reboot -no-shutdown`

`qemu-system-x86_64 -cdrom myos.iso -d int,cpu -no-reboot > qemu_log.txt`

`qemu-system-x86_64 -cdrom myos.iso -d int,cpu -no-reboot > qemu_log.txt 2>&1`

`qemu-system-x86_64 -cdrom myos.iso -monitor stdio`

`qemu-system-x86_64 -cdrom myos.iso -d int -no-reboot -no-shutdown`

`qemu-system-x86_64 -cdrom myos.iso -s -S` 

`qemu-system-x86_64 -cpu core2duo -cdrom myos.iso`

`qemu-system-x86_64 -cpu pentium4 -cdrom myos.iso`

`qemu-system-x86_64 -cpu help`

`qemu-system-x86_64 -kernel kernel.bin -s -S`

there is also -drive, -fdd, -hdd. 

To test out the other CPU's we support use:

-cpu Nehalem
-cpu SandyBridge
-cpu IvyBridge


