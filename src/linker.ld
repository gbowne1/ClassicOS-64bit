/* The virtual memory start address for the higher-half kernel. */
/* This matches the 'offset' defined in your boot.s */
VIRTUAL_BASE = 0xFFFFFFFF80000000;

/* Output Format (e.g., ELF64) */
OUTPUT_FORMAT(elf64-x86-64)
ENTRY(_start) /* Define the entry point, which is _start in boot.s */

/* Start of the physical address space where the kernel is loaded (e.g., 1MB) */
/* The linker needs to know where the loader (GRUB) placed the code. */
PHS_BASE = 0x00100000;

SECTIONS
{
    /* The first section starts at the physical base address */
    . = PHS_BASE;

    /* Multiboot Header Section */
    .mboot :
    {
        /* The mboot structure must be placed first in the file */
        *(.mboot)
    }

    /* The main kernel sections, mapped to the higher half */
    .text ALIGN(4K) : AT(ADDR(.text) - VIRTUAL_BASE + PHS_BASE)
    {
        /* Everything in .text is located here */
        *(.text)
    }

    .data ALIGN(4K) : AT(ADDR(.data) - VIRTUAL_BASE + PHS_BASE)
    {
        /* Everything in .data is located here */
        *(.data)
    }

    .rodata ALIGN(4K) : AT(ADDR(.rodata) - VIRTUAL_BASE + PHS_BASE)
    {
        /* Everything in .rodata is located here */
        *(.rodata)
    }

    .bss ALIGN(4K) : AT(ADDR(.bss) - VIRTUAL_BASE + PHS_BASE)
    {
        /* The BSS section (uninitialized data, like your paging structures) */
        *(.bss)
        /* Export the physical end of the kernel for memory management */
        _KERNEL_END_PHS = ALIGN(4K);
    }
}
