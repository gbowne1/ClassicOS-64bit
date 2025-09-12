#ifndef MULTIBOOT2_H
#define MULTIBOOT2_H

#define MULTIBOOT2_HEADER_MAGIC 0xe85250d6

#include <stdint.h>
#include <stddef.h>

struct multiboot2_header {
    uint32_t magic;
    uint32_t architecture;
    uint32_t header_length;
    uint32_t checksum;
};

struct multiboot2_tag {
    uint32_t type;
    uint32_t size;
} __attribute__((packed));

struct multiboot2_tag_framebuffer {
    uint32_t type;
    uint32_t size;
    uint64_t framebuffer_addr;
    uint32_t framebuffer_pitch;
    uint32_t framebuffer_width;
    uint32_t framebuffer_height;
    uint8_t framebuffer_bpp;
    uint8_t framebuffer_type;
    uint16_t reserved;
} __attribute__((packed));

struct multiboot2_tag_mmap {
    uint32_t type;
    uint32_t size;
    uint32_t entry_size;
    uint32_t entry_version;
} __attribute__((packed));

struct multiboot2_mmap_entry {
    uint64_t base_addr;
    uint64_t length;
    uint32_t type;
    uint32_t reserved;
} __attribute__((packed));

struct multiboot2_tag_end {
    uint32_t type;
    uint32_t size;
} __attribute__((packed));

#define MULTIBOOT2_TOTAL_SIZE (sizeof(struct multiboot2_header) + \
                               sizeof(struct multiboot2_tag_framebuffer) + \
                               sizeof(struct multiboot2_tag_end))

struct multiboot2_header header __attribute__((section(".multiboot2"), aligned(8))) = {
    .magic = MULTIBOOT2_HEADER_MAGIC,
    .architecture = 0, /* i386 for x86 compatibility */
    .header_length = MULTIBOOT2_TOTAL_SIZE,
    .checksum = -(uint32_t)(MULTIBOOT2_HEADER_MAGIC + 0 + MULTIBOOT2_TOTAL_SIZE),
};

struct multiboot2_tag_framebuffer fb_tag __attribute__((section(".multiboot2"), aligned(8))) = {
    .type = 5,
    .size = sizeof(struct multiboot2_tag_framebuffer),
    .framebuffer_addr = 0,
    .framebuffer_pitch = 160,
    .framebuffer_width = 80,
    .framebuffer_height = 25,
    .framebuffer_bpp = 16,
    .framebuffer_type = 1, /* Text mode */
    .reserved = 0,
};

struct multiboot2_tag_end end_tag __attribute__((section(".multiboot2"), aligned(8))) = {
    .type = 0,
    .size = sizeof(struct multiboot2_tag_end),
};

#endif /* MULTIBOOT2_H */