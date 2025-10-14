image: elf
	mkdir -p iso/boot/grub && cp grub.cfg iso/boot/grub && cp kernel.elf iso/boot && grub-mkrescue --output=kernel.iso iso

elf: boot.o entry.o
	ld -z max-page-size=0x1000 -Tlink.ld -o kernel.elf entry.o boot.o

boot.o:
	nasm -f elf64 boot.s -o boot.o

entry.o:
	gcc -ffreestanding -fno-stack-protector -mno-red-zone -o entry.o -c entry.c

.PHONY: clean
clean:

	rm -f *.o && rm -rf iso
