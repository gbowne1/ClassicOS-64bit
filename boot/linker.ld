/* linker.ld */
OUTPUT_FORMAT("elf64-x86-64")
ENTRY(_start)

SECTIONS {
    /* Load kernel at 1 MiB physical address */
    . = 0x100000;

    /* Multiboot2 header, 8-byte aligned */
    .multiboot2 : ALIGN(8) {
        __multiboot2_start = .;
        *(.multiboot2)
        __multiboot2_end = .;
    }

    /* Code section */
    .text : ALIGN(4K) {
        __text_start = .;
        *(.text)
        __text_end = .;
    }

    /* Read-only data */
    .rodata : ALIGN(4K) {
        __rodata_start = .;
        *(.rodata*)
        __rodata_end = .;
    }

    /* Read-write data */
    .data : ALIGN(4K) {
        __data_start = .;
        *(.data)
        __data_end = .;
    }

    /* BSS (zero-initialized data) */
    .bss : ALIGN(4K) {
        __bss_start = .;
        *(.bss)
        *(COMMON)
        __bss_end = .;
    }

    /* Kernel end symbol */
    __kernel_end = .;

    /* Debugging sections (keep symbols for GDB) */
    /DISCARD/ : {
        *(.comment)
        *(.eh_frame)
    }
}
