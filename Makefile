# --- Configuration ---
# Your kernel's virtual base address (must match boot.s and linker.ld)
VIRT_BASE := 0xFFFFFFFF80000000

# Directory and file names
BUILD_DIR := build
ASM_SRC := src/boot/boot.s
C_SRC := src/kmain.c
LINKER_SCRIPT := linker.ld
KERNEL_BIN := $(BUILD_DIR)/kernel.bin

# Toolchain
CC := gcc
AS := nasm
LD := ld
QEMU := qemu-system-x86_64

# Compiler Flags
# -ffreestanding: Tells GCC not to link in the standard library or crt0
# -m64: Compiles for 64-bit target
# -I: Include directory for kernel header files (if any)
CFLAGS := -std=gnu11 -ffreestanding -O2 -Wall -Wextra -m64 -Isrc
# Assembler Flags
ASFLAGS := -f elf64

# Linker Flags
# -T: Use the custom linker script
# -nostdlib: Don't link standard libraries
LDFLAGS := -T $(LINKER_SCRIPT) -nostdlib

# --- Targets ---

# Default target: builds the kernel
.PHONY: all
all: $(KERNEL_BIN)

# Creates the build directory if it doesn't exist
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

# Primary target: The final kernel binary
$(KERNEL_BIN): $(BUILD_DIR) $(BUILD_DIR)/boot.o $(BUILD_DIR)/kmain.o
	$(LD) $(LDFLAGS) -o $@ $^
	@echo "✨ Kernel built successfully: $@"

# Rule for assembling boot.s
$(BUILD_DIR)/boot.o: $(ASM_SRC)
	$(AS) $(ASFLAGS) $< -o $@

# Rule for compiling kmain.c
$(BUILD_DIR)/kmain.o: $(C_SRC)
	$(CC) $(CFLAGS) -c $< -o $@

# --- Running and Cleanup ---

.PHONY: run
# Runs the kernel using QEMU
# -m 128: Allocate 128MB of memory
# -cpu qemu64: Emulate a 64-bit CPU
# -kernel: Tells QEMU to load the file as a Multiboot kernel
run: $(KERNEL_BIN)
	$(QEMU) -m 128 -cpu qemu64 -kernel $(KERNEL_BIN) -s -S

.PHONY: clean
# Removes all generated files
clean:
	rm -rf $(BUILD_DIR)
	@echo "🧹 Cleaned build directory."
