For debugging ClassicOS-64bit we have a few options

We should have gdb, GNU's debugger downloaded, built, compiled, installed.

gdb's documentation is here: 
<https://www.gnu.org/savannah-checkouts/gnu/gdb/index.html>
<https://sourceware.org/gdb/>
<https://ftp.gnu.org/old-gnu/Manuals/gdb/html_chapter/gdb_toc.html>

There's man pages available in linux and on the web.

<https://wiki.osdev.org/GDB>
<https://wiki.osdev.org/Kernel_Debugging>

We can use GDB from QEMU and can start with a gdb stub by using:

`qemu-system-x86_64 -cdrom myos.iso -s -S`
`qemu-system-x86_64 -kernel kernel.bin -s -S`
`qemu-system-x86_64 -kernel kernel.bin -gdb tcp::1234 -S`

In another terminal, `gdb kernel.bin` from where the `kernel.bin` lives.

Then in gdb's prompt `(gdb)` run `target remote localhost:1234`

Make sure the kernel is compiled with`-g -O0` option flags. It won't work if there's no symbols.

In GDB, `set architecture i386:x86-64` will avoid confusion with your host system’s ABI (especially if you’re using plain gdb).

The most important thing is the step and break and continue commands.

Eventually this docment set will have instructions for OS and Kernel debugging in other IDE's and editors
But, right now that's beyond the scope of this document.

If everything is correct, we should check if rax contains 0x36d76289 in _start to confirm Multiboot2 loading.

The CPU's in this range have eight (8) Debug registers DR0 through DR07, we only get access to these in Ring 0.

