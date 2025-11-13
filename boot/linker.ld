/* linker.ld — x86-64, GRUB2 Multiboot2, higher-half kernel */

ENTRY(_start)

/* Higher-half virtual base for the kernel */
KERN_OFFSET = 0xFFFFFFFF80000000;

/* 4 KiB page alignment */
PAGE = 0x1000;

/* Start all sections at 1 MiB physically, which GRUB commonly uses */
PHYS_BASE = 0x00100000;

SECTIONS
{
  /* File starts at physical 1 MiB; VMA begins at PHYS_BASE + KERN_OFFSET */
  . = PHYS_BASE;

  /* Multiboot2 header must be in the first few KiB and kept */
  .mboot ALIGN(8) : AT(ADDR(.mboot))
  {
    KEEP(*(.mboot))
  }

  /* Switch to higher-half virtual addresses */
  . = . + KERN_OFFSET;

  /* Mark the virtual and physical kernel range start */
  _kernel_start_vaddr = .;
  _kernel_start_paddr = _kernel_start_vaddr - KERN_OFFSET;

  /* Text/code section */
  .text ALIGN(PAGE) : AT(ADDR(.text) - KERN_OFFSET)
  {
    *(.text .text.*)
    *(.stub)
  }

  /* Read-only data */
  .rodata ALIGN(PAGE) : AT(ADDR(.rodata) - KERN_OFFSET)
  {
    *(.rodata .rodata.*)
    *(.gnu.linkonce.r.*)
    *(.eh_frame*)
  }

  /* Writable data */
  .data ALIGN(PAGE) : AT(ADDR(.data) - KERN_OFFSET)
  {
    *(.data .data.*)
    *(.gnu.linkonce.d.*)
  }

  /* BSS (zero-initialized) */
  .bss ALIGN(PAGE) : AT(ADDR(.bss) - KERN_OFFSET)
  {
    *(COMMON)
    *(.bss .bss.*)
    *(.gnu.linkonce.b.*)
  }

  /* End markers */
  _kernel_end_vaddr = .;
  _kernel_end_paddr = _kernel_end_vaddr - KERN_OFFSET;
}

/* Provide aliases some toolchains expect */
PROVIDE(__kernel_start = _kernel_start_vaddr);
PROVIDE(__kernel_end   = _kernel_end_vaddr);
PROVIDE(__kernel_phys_start = _kernel_start_paddr);
PROVIDE(__kernel_phys_end   = _kernel_end_paddr);
