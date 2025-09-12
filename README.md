# ClassicOS-64bit

ClassicOS-64bit is a custom 64-bit operating system targeting legacy x86-64 CPUs (e.g., Pentium 4, Core 2 Duo, early Core i3/i5/i7, and various Xeon processors). Built with GRUB2 and Multiboot2, it’s designed for older hardware, supporting Pentium 3 and later 64-bit Intel CPUs. This project is written in C and focuses on a minimal, efficient kernel for legacy systems.

## Getting Started

- **Build Requirements**: See [docs/build_requirements.md](docs/build_requirements.md) for tools and versions.
- **Target CPUs**: Check supported processors in [docs/target_cpus.md](docs/target_cpus.md).
- **Build Instructions**: Follow [docs/build_instructions.md](docs/build_instructions.md) to compile and link the kernel.
- **GRUB2 Setup**: Configure GRUB2 and Multiboot2 in [docs/grub_setup.md](docs/grub_setup.md).
- **QEMU Testing**: Test the OS with QEMU as described in [docs/qemu_testing.md](docs/qemu_testing.md).
- **Debugging**: Debug with GDB and other tools in [docs/debugging.md](docs/debugging.md).

## Project Structure

- src/: C source files (e.g., kmain.c).
- include/: Header files (e.g., multiboot2.h).
- oot/: Bootloader files, including linker.ld and GRUB config.
- iso/: ISO generation files (e.g., iso/boot/grub/).
- uild/: Compiled binaries and artifacts.
- docs/: Detailed documentation.

## Contributing

Contributions are welcome! Please submit pull requests or issues on [GitHub](https://github.com/yourusername/ClassicOS-64bit).

## License

[Specify your license here, e.g., MIT, GPL, etc.]
