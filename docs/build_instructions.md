To build and compile this operating system we need to have at least GNU 8.3 
This document will allow us to lay out the options to build or compile the kernel
into the necessary option files.

There's no cross-compiler needed as ideally we should be developing this operating
system on a native Intel x86 64 bit CPU as defined in` target_cpus.md` but, if you're
using some other architecture, or system, you'll need some cross-compiler.

To install GNU.. they should be available in your OS's package manager.
You can also build or compile it from source.

The are available on https://ftp.gnu.org/gnu/ as tar.gz files

There's other ways around this too, download and install binutils, build-essential
gcc g++ and gdb could be available as separate packages.

GNU gcc's documentation is at <https://gcc.gnu.org/onlinedocs/>

We will use gcc to compile the kernel which is `kmain.c` in the `/src` directory to a .o file called `kernel.o`
to which we link using GNU's or binutil's ld.

The command syntax is `gcc [options] [source files] [object files] [libraries] [-o output]`. This is 
defined in GCC's documentation.

-c takes the filename to be compiled (use this because we aren't using gcc to link we are using ld)

-o this is the output file (which will be `kernel.o`)

-ffrestanding
-fno-pic
-fno-pie
-fno-stack-protector
-mno-red-zone
-nostdlib
-m64
-fno-builtin
-fno-exceptions
-fno-rtti
-nodefaultlibs
-nostartfiles

To give us error and warning generation
-Wall
-Werror
-Wextra
-Wpedantic
-pedantic
-pedantic-errors
-everything

-std=c99 or -stc=C11

-O0, -01 or -O2 for debugging

-I to give it the path for the include files

We could also possible use -mtune and -march, but probably not necessary.

You can read about these here <https://gcc.gnu.org/onlinedocs/gcc/Optimize-Options.html>
