/* kmain.c */
#include "multiboot2.h"
#include <stdint.h>
#include <stddef.h>

#define MULTIBOOT2_BOOTLOADER_MAGIC 0x36d76289

/* External symbols from linker script */
extern char __bss_start[], __bss_end[];

/* CPUID function */
static inline void cpuid(uint32_t code, uint32_t *a, uint32_t *d) {
    asm volatile("cpuid"
                 : "=a"(*a), "=d"(*d)
                 : "a"(code)
                 : "ecx", "ebx");
}

/* Check if CPUID is supported */
static inline int cpuid_supported(void) {
    uint64_t rflags_before, rflags_after;
    asm volatile(
        "pushfq\n\t"
        "pop %%rax\n\t"
        "mov %%rax, %0\n\t"
        "xor $0x200000, %%rax\n\t"
        "push %%rax\n\t"
        "popfq\n\t"
        "pushfq\n\t"
        "pop %%rax\n\t"
        "mov %%rax, %1"
        : "=r"(rflags_before), "=r"(rflags_after)
        :
        : "rax"
    );
    return rflags_before != rflags_after;
}


/* CPU feature detection */
void detect_cpu(void) {
    volatile char *video_memory = (volatile char *)0xb8000;
    const char *error;

    /* Check if CPUID is supported */
    if (!cpuid_supported()) {
        error = "ERROR: CPUID not supported.";
        for (size_t i = 0; error[i] != '\0'; i++) {
            video_memory[i * 2] = error[i];
            video_memory[i * 2 + 1] = 0x4F; /* Red on white */
        }
        for (;;)
            asm volatile("hlt");
    }

    /* Check for long mode */
    uint32_t eax, edx;
    cpuid(1, &eax, &edx);
    if (!(edx & (1 << 29))) {
        error = "ERROR: CPU does not support 64-bit.";
        for (size_t i = 0; error[i] != '\0'; i++) {
            video_memory[i * 2] = error[i];
            video_memory[i * 2 + 1] = 0x4F;        }
        for (;;)
            asm volatile("hlt");
    }
}

/* Clear BSS section */
void clear_bss(void) {
    char *bss = __bss_start;
    while (bss < __bss_end) {
        *bss++ = 0;
    }
}

struct idt_entry {
    uint16_t offset_low;
    uint16_t selector;
    uint8_t ist;
    uint8_t type_attr;
    uint16_t offset_mid;
    uint32_t offset_high;
    uint32_t zero;
} __attribute__((packed));

struct idt_ptr {
    uint16_t limit;
    uint64_t base;
} __attribute__((packed));

void exception_handler(void) {
    volatile char *video_memory = (volatile char *)0xb8000;
    const char *error = "ERROR: Exception occurred!";
    for (size_t i = 0; error[i] != '\0'; i++) {
        video_memory[i * 2] = error[i];
        video_memory[i * 2 + 1] = 0x4F;
    }
    for (;;)
        asm volatile("hlt");
}

void setup_idt(void) {
    struct idt_entry idt[256] = {0};
    struct idt_ptr idtp = { .limit = sizeof(idt) - 1, .base = (uint64_t)idt };

    /* Set up divide-by-zero handler (interrupt 0) */
    uint64_t handler_addr = (uint64_t)exception_handler;
    idt[0].offset_low = handler_addr & 0xFFFF;
    idt[0].selector = 0x08; /* Code segment */
    idt[0].ist = 0;
    idt[0].type_attr = 0x8E; /* Present, DPL=0, interrupt gate */
    idt[0].offset_mid = (handler_addr >> 16) & 0xFFFF;
    idt[0].offset_high = (handler_addr >> 32) & 0xFFFFFFFF;
    idt[0].zero = 0;

    asm volatile("lidt %0" : : "m"(idtp));
}

/* Parse Multiboot2 framebuffer tag */
int get_framebuffer_info(void *mbd, uint64_t *fb_addr, uint32_t *width, uint32_t *height, uint8_t *type) {
    uint32_t total_size = *(uint32_t *)mbd;
    if (total_size < 8) return -1; /* Validate size */
    uint8_t *tag = (uint8_t *)mbd + 8;
    struct multiboot2_tag_framebuffer *fb_tag = NULL;

    while (tag < (uint8_t *)mbd + total_size && ((struct multiboot2_tag_end *)tag)->type != 0) {
        if (((struct multiboot2_tag_framebuffer *)tag)->type == 5) {
            fb_tag = (struct multiboot2_tag_framebuffer *)tag;
            break;
        }
        tag += ((struct multiboot2_tag_framebuffer *)tag)->size;
        tag = (uint8_t *)(((uintptr_t)tag + 7) & ~7);
    }

    if (!fb_tag || fb_tag->size < sizeof(*fb_tag) || fb_tag->framebuffer_type != 1) {
        return -1;
    }

    *fb_addr = fb_tag->framebuffer_addr;
    *width = fb_tag->framebuffer_width;
    *height = fb_tag->framebuffer_height;
    *type = fb_tag->framebuffer_type;
    return 0;
}

void parse_memory_map(void *mbd) {
    uint8_t *tag = (uint8_t *)mbd + 8;
    volatile char *video_memory = (volatile char *)0xb8000; /* Use text mode video memory for simplicity */
    size_t offset = 0; /* Track position in video memory for printing */

    while (((struct multiboot2_tag_end *)tag)->type != 0) {
        if (((struct multiboot2_tag_mmap *)tag)->type == 6) {
            struct multiboot2_tag_mmap *mmap = (struct multiboot2_tag_mmap *)tag;
            uint8_t *entry = (uint8_t *)(mmap + 1);
            for (uint32_t i = 0; i < (mmap->size - sizeof(*mmap)) / mmap->entry_size; i++) {
                uint64_t base_addr = *(uint64_t *)entry;
                uint64_t length = *(uint64_t *)(entry + 8);
                uint32_t type = *(uint32_t *)(entry + 16);

			/* Prevent unused variable warnings */
			(void)length;
			(void)type;

                /* Convert and print base_addr (simplified */ 
                char buf[32];
                size_t buf_idx = 0;
                uint64_t temp = base_addr;
                if (temp == 0) {
                    buf[buf_idx++] = '0';
                } else {
                    while (temp) {
                        buf[buf_idx++] = '0' + (temp % 10);
                        temp /= 10;
                    }
                }
                /* Reverse the string */
                for (size_t j = 0; j < buf_idx / 2; j++) {
                    char t = buf[j];
                    buf[j] = buf[buf_idx - 1 - j];
                    buf[buf_idx - 1 - j] = t;
                }
                buf[buf_idx] = '\0';

                /* Print "Base: <base_addr> */
                const char *prefix = "Base: ";
                for (size_t j = 0; prefix[j] != '\0'; j++) {
                    video_memory[offset * 2] = prefix[j];
                    video_memory[offset * 2 + 1] = 0x07;
                    offset++;
                }
                for (size_t j = 0; buf[j] != '\0'; j++) {
                    video_memory[offset * 2] = buf[j];
                    video_memory[offset * 2 + 1] = 0x07;
                    offset++;
                }
                video_memory[offset * 2] = ' ';
                video_memory[offset * 2 + 1] = 0x07;
                offset++;

                /* Move to next entry */
                /* entry += mmap->entry_size; */
            }
        }
        tag += ((struct multiboot2_tag *)tag)->size;
        tag = (uint8_t *)(((uintptr_t)tag + 7) & ~7);
    }
}

/* function protoype used later on */
void long_mode_entry(void *mbd, uint64_t fb_addr, uint32_t fb_width, uint32_t fb_height, uint8_t fb_type) __attribute__((noreturn));

void setup_long_mode(void *mbd, uint64_t fb_addr, uint32_t fb_width, uint32_t fb_height, uint8_t fb_type) {
    /* Page tables (aligned) */
    static uint64_t pml4[512] __attribute__((aligned(4096))) = {0};
    static uint64_t pdpt[512] __attribute__((aligned(4096))) = {0};
    static uint64_t pd[512] __attribute__((aligned(4096))) = {0};

    /* Map first 16 MB using 2MB pages (8 * 2MB = 16MB) */
    for (int i = 0; i < 8; i++) {
        pd[i] = (i * 0x200000) | 0x83; /* Present + Writable + Huge Page */
    }
    pdpt[0] = (uint64_t)pd | 0x3;      /* Present + Writable */
    pml4[0] = (uint64_t)pdpt | 0x3;    /* Present + Writable */

    /* Load CR3 with PML4 physical address */
    asm volatile("mov %0, %%cr3" : : "r"(pml4));

    /* Enable PAE (bit 5 in CR4) */
    asm volatile(
        "mov %%cr4, %%rax\n"
        "or $0x20, %%rax\n"
        "mov %%rax, %%cr4\n"
        :
        :
        : "rax"
    );

    /* Enable Long Mode in EFER MSR (MSR 0xC0000080, bit 8) */
    uint32_t eax, edx;
    asm volatile(
	    "mov $0xC0000080, %%ecx\n\t"  // EFER MSR
	    "rdmsr\n\t"
	    "or $0x100, %%eax\n\t"        // Set Long Mode Enable bit
	    "wrmsr\n\t"
	    : "=a"(eax), "=d"(edx)        // output: updated eax, edx
	    :                             // input: none
	    : "ecx"
	);

    /* Enable Paging (bit 31 in CR0) */
    asm volatile(
        "mov %%cr0, %%rax\n"
        "or $0x80000000, %%rax\n"
        "mov %%rax, %%cr0\n"
        :
        :
        : "rax"
    );

    /* Setup a minimal GDT (3 entries: null, code, data) */
    static uint64_t gdt[3] = {
        0x0000000000000000ULL,      /* Null descriptor */
        0x00af9a000000ffffULL,      /* Code segment descriptor */
        0x00af92000000ffffULL       /* Data segment descriptor */
    };

    struct {
        uint16_t limit;
        uint64_t base;
    } __attribute__((packed)) gdtr = {
        .limit = sizeof(gdt) - 1,
        .base = (uint64_t)&gdt,
    };

    asm volatile("lgdt %0" : : "m"(gdtr));

    /* Far jump to flush pipeline and switch to 64-bit code segment */
    asm volatile(
	    "cli\n\t"
        "mov $0x08, %%ax\n\t"     /* Code segment selector */
        "mov %%ax, %%ds\n\t"
        "mov %%ax, %%es\n\t"
        "mov %%ax, %%ss\n\t"
        "mov %%ax, %%fs\n\t"
        "mov %%ax, %%gs\n\t"
        "pushq $0x08\n\t"          /* Code segment selector (64-bit) */
        "lea 1f(%%rip), %%rax\n\t"
        "pushq %%rax\n\t"
        "lretq\n"
        "1:\n\t"
        :
        :
        : "rax", "ax"
    );

    /* We should be Now in 64-bit mode - this needs work */

    /*__attribute__((noreturn))
     * void long_mode_entry(void) {
     *   // Now in 64-bit mode
     *
     *  // Clear BSS, initialize devices, framebuffer, print messages, etc.
     *
     *  for (;;)
     *       asm volatile("hlt");
    }*/
}

void long_mode_entry(void *mbd, uint64_t fb_addr, uint32_t fb_width, uint32_t fb_height, uint8_t fb_type) {
    asm volatile(
        "mov $0x10, %%ax\n"
        "mov %%ax, %%ds\n"
        "mov %%ax, %%es\n"
        "mov %%ax, %%fs\n"
        "mov %%ax, %%gs\n"
        "mov %%ax, %%ss\n"
        :
        :
        : "ax"
    );

    volatile char *video_memory = (volatile char *)fb_addr;

    parse_memory_map(mbd);

    for (size_t i = 0; i < fb_width * fb_height; i++) {
        video_memory[i * 2] = ' ';
        video_memory[i * 2 + 1] = 0x07;
    }

    const char *message = "Hello, 64-bit Multiboot2 World!";
    for (size_t i = 0; message[i] != '\0'; i++) {
        video_memory[i * 2] = message[i];
        video_memory[i * 2 + 1] = 0x07;
    }

    for (;;)
        asm volatile("hlt");
}

void kmain(void *mbd, uint32_t magic) {
    volatile char *video_memory = (volatile char *)0xb8000;
    const char *error;

    if (magic != MULTIBOOT2_BOOTLOADER_MAGIC) {
        error = "ERROR: Invalid Multiboot2 magic.";
        for (size_t i = 0; error[i] != '\0'; i++) {
            video_memory[i * 2] = error[i];
            video_memory[i * 2 + 1] = 0x4F;
        }
        for (;;)
            asm volatile("hlt");
    }

    detect_cpu();

    uint64_t fb_addr;
    uint32_t fb_width, fb_height;
    uint8_t fb_type;
    if (get_framebuffer_info(mbd, &fb_addr, &fb_width, &fb_height, &fb_type) != 0) {
        error = "ERROR: Framebuffer not available or not in text mode.";
        for (size_t i = 0; error[i] != '\0'; i++) {
            video_memory[i * 2] = error[i];
            video_memory[i * 2 + 1] = 0x4F;
        }
        for (;;)
            asm volatile("hlt");
    }

 
    setup_long_mode(mbd, fb_addr, fb_width, fb_height, fb_type);

    for (;;)
        asm volatile("hlt");
}

void _start(void *mbd, uint32_t magic) {
    /* Clear BSS section */
    clear_bss();

    /* Call kmain with Multiboot2 magic */
    kmain(mbd, magic);
}
