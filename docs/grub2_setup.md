In order to use GRUB2 and have `multiboot2.h` support, you will need the `grub2-common` package.
Check your distros package manager to see what to install. You can build/compile from source
if you like. 

GRUB's documentation is here:

<https://www.gnu.org/software/grub/>
<https://www.gnu.org/software/grub/manual/grub/grub.html>

GRUB's multiboot2.h specification:

<https://www.gnu.org/software/grub/manual/multiboot2/multiboot.html>

Some general notes:

<https://wiki.osdev.org/GRUB>
<https://wiki.osdev.org/Multiboot>
<https://forum.osdev.org/viewtopic.php?t=38557>

So, GRUB2 searches the ISO filesystem starting from the root. GRUB2 also needs a valid
Multiboot2 header, placed within the first 32 KiB of the file.

`grub-mkrescue -o classicos-64bit.iso iso` or `grub-mkrescue -o classicos-64bit.iso iso/` 

Note: both do the same thing

The structure should look like 

```shell
iso/
├── boot/
│   ├── grub/
│   │   └── grub.cfg      ← GRUB config
│   └── kernel.bin        ← ClassicOS-64bit Multiboot(2) kernel
```

After running this command you should get a classicost-64bit.iso

This checks whether the given file (<filename>) is Multiboot2-compliant — specifically, 
whether it has a valid Multiboot2 header that the GRUB2 bootloader would recognize when booting a kernel.
`grub-file --is-x86-multiboot2 <filename>`

`grub-install --target=i386-pc /dev/null`
`grub-install --target=i386-pc --boot-directory=/mnt/boot /dev/null`

In order for the boot to work:
- make sure the kernel bin is in the /boot as boot/kernel.bin 
- grub config file goes in /boot/grub/ 
  - for GRUB2 it's `grub.cfg`
- the iso can go in /iso/boot/grub/
