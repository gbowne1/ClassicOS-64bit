; A basic multiboot2 compatible longmode bootstrap that loads into a higher half kernel.
; It identity maps the lower 1GB of memory
; And then maps the lowest 1GB of memory to the last 2GB of memory. (higher-half)
; Then it jumps to entry64 if it successfuly enters long mode, entry32 if it loads successfully
; but is on a computer that does not support long mode, and error if it fails to load.

; This section of the code is for 32 bit execution
bits 32

section .text

; These must be global to be seen by the linker script
global mboot
global _start

; Removes kernel_offset from `a`
; This is needed because our linker script maps everything to the higher half
; of the address space, and we have not initialized paging untill rather far down our code.
%define offset 0xFFFFFFFF80000000
%define no_offset(a) a-offset


mboot:
    ; MAGIC
    dd 0xE85250D6

    ; Architecture -- 0 is protected mdoe
    dd 0

    ; Header Size
    dd mboot_end - mboot

    ; Checksum
    dd -(0xE85250D6+0+mboot_end-mboot)

    

    ; End tag
    dw 0
    dw 0
    dd 8
mboot_end:

; Entry point
_start:

    ; Initialize new stack
    mov esp, no_offset(stack)

    ; Save the multiboot registers
    mov [no_offset(mboot_ebx)], ebx
    mov [no_offset(mboot_eax)], eax
    
    ; If these first two checks fail, they will jump to error

    ; Check that we are using multiboot
    call check_multiboot

    ; Check that CPUID is supported
    call check_cpuid


    ; Check that longmode is supported
    call check_longmode ; Note, if long mode is not supported, this will jump to entry 32


    ; Initialize paging and enable long mode
    call initialize_paging

    ; Enable paging
    call enable_paging
    
    ; We are now in compatibility mode

    ; Load the long mode GDT
    call load_gdt


    ; Far jump to the 64 bit entry point to enable long mode
    jmp 0x08:no_offset(entry64)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;  Paging
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Initializes longmode paging
initialize_paging:

    ; Map lower half of the PML4 (first entry, starting at 0x00)
    mov eax, no_offset(paging_pdpt_low) ; Remember to use physical addresses here
    or eax, 0b11 ; Set flags in the lower 12 bits as present and read/write
    mov [no_offset(paging_pml4)], eax

    ; Map the 511th PML4 entry with the higher-half pdpt
    mov eax, no_offset(paging_pdpt_high)
    or eax, 0b11
    mov [no_offset(paging_pml4) + 511 * 8], eax

    ; Map the higher half pdpt. We offset the page directory at 510 so that
    ; the kernel is at the desired address
    mov eax, no_offset(paging_pd)
    or eax, 0b11
    mov [no_offset(paging_pdpt_high) + 510 * 8], eax

    ; Identity map the lower half pdpt
    mov eax, no_offset(paging_pd)
    or eax, 0b11
    mov [no_offset(paging_pdpt_low)], eax

    ; Map the page tables
    mov eax, no_offset(paging_pts) ; The physical address of all page tables to map
    mov ebx, 0b11 ; Each entry should have the present and read/write flags set
    mov ecx, 512 * 512 ; We are mapping 512 entries over 512 page tables
    mov edx, 0 ; We want the pages to start mapping at physical address 0
    call map_pts ; Map the page tables

    ; Map the page directory to the page tables.
    mov eax, no_offset(paging_pd) ; The physical address of the page directory to map
    mov ebx, 0b11 ; Each entry should have the present and read/write flags set
    mov ecx, 512 ; We are mapping 512 page directory entries
    mov edx, no_offset(paging_pts) ; The physical addresses of the page tables we are mapping into the page directory.
    call map_pd ; Map the page directory

    ; Load the PML4 into the cr3 register
    mov eax, no_offset(paging_pml4)
    mov cr3, eax ; CR3 is a control register, and thus can only be accessed by a register-to-register mov

    ; Enable PAE
    mov eax, cr4
    or eax, 1 << 5 ; Bit 5 of CR4 is the PAE bit
    mov cr4, eax

    ; Enable longmode
    mov ecx, 0xC0000080 ; Read MSR 0xC0000080, which contains the long mode bit
    rdmsr
    or eax, 1 << 8 ; Enable the long mode bit (bit 8)
    wrmsr ; Write eax to MSR 0xC0000080

    ; Paging is initialized and ready to be enabled

    ; Return
    ret

; Enables paging
enable_paging:
    mov eax, cr0 ; Load CR0 and set bit 31, which enables paging
    or eax, 1 << 31
    mov cr0, eax

    ret

; Maps the page tables using a custom designed linear method.
; Because we know all page tables are going to be contiguous, we can treat them as a signle list of page
; tables instead of recursively mapping over each paging structure.
; Arguments:
; EAX: The physical address of the page table structures
; EBX: The flags to apply to each page table
; ECX: The number of page tables to map
; EDX: The physical address to start mapping at
map_pts:

    ; Clear all bits of EBX that are not flags
    and ebx, 0xFFF ; The flags are the first 12 bits.

    ; Apply the flags to the offset address. We only need to do this once,
    ; because we can guarentee the bottom 12 bits wont be modified.
    or edx, ebx

.map1: ; The main loop which maps a single address

    ; Move the address into the table at address EAX
    mov [eax], edx

    ; Go to the next page by adding the page size to offset.
    add edx, 0x1000 ; This does not modify the flags.

    ; Go to the next page table
    add eax, 8 ; Each page table is 8 bytes in size.

    ; Decrement and loop if ecx is larger than zero
    dec ecx
    jnz .map1

    ; Return
    ret

; Maps a page directory to an array of page tables
; Arguments:
; EAX: The physical address of the page directory
; EBX: The flags to apply to each page directory
; ECX: The number of entries to map
; EDX: The physical address of the page tables to map
map_pd:

    ; Clear all non-flag values in EBX
    ; So that we don't accidentally overwrite the address
    ; of the page tables
    and ebx, 0xFFF

    ; Apply the flags to the physical address
    ; This only needs to be done once, because we can guarentee that
    ; the lower 12 bits will not change until we are done
    or edx, ebx

.map1: ; The main loop that maps a single page directory
    
    ; Move the address and flags into the table
    mov [eax], edx

    ; Go to the next page table entry
    add edx, 0x1000 ; This does not modify the flags.

    ; Go to the next page directory entry
    add eax, 8 ; Each entry is 8 bytes long

    ; Decrement and loop if ecx is larger than zero
    dec ecx
    jnz .map1

    ; Return
    ret



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;  Utilities
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Loads the GDT
load_gdt:
    lgdt [no_offset(gdt64_ptr)]
    ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;  Checks
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


; Verifies that we have been loaded by a multiboot loader.
; jumps to error if we encounter an issue
check_multiboot:
    cmp eax, 0x36d76289
    jne error
    ret

; Checks if CPUID is supported. Based on OSDEV wiki implementation.
check_cpuid:

    ; Copy FLAGS to EAX
    pushfd
    pop eax

    ; Also copy to ebx so we can compare it later
    mov ebx, eax

    ; Flip the ID bit
    xor eax, 1 << 21

    ; Save EAX, with the ID bit flipped to FLAGS using the stack
    push eax
    popfd

    ; Get flags again
    pushfd
    pop eax
    
    ; Restore flags to the old version
    push ebx
    popfd

    ; If eax and ebx are the same, then CPUID does not exist
    xor eax, ebx
    jz error
    ret

; Verifies that the CPU supports long mode. Based on OSDEV wiki implementation.
check_longmode:

    ; Check if CPUID has the extended functions
    mov eax, 0x80000000
    cpuid ; CPUID should place the highest possible function into eax
    cmp eax, 0x80000001
    
    ; So if the higest possible function is lower than the long mode bit, then there is no long mode
    jb entry32

    ; If we got here, the CPU supports the extended functions.
    ; So lets check for long mdoe in CPUID EAX = 0x80000001
    mov eax, 0x80000001
    cpuid
    test edx, 1 << 29 ; Check the long mode bit (bit 29)
    jz entry32 ; Jump to the 32 bit entry if long mode is non existant

    ; If we reached here, long mode is supported
    ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;  Post-Bootstrap
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


; This is where the code jumps to if we are unable to load long mode.
entry32:
    jmp $

; Any other startup errors should hang here
error:
    jmp $


bits 64 ; Enter 64 bits here

extern c_entry

; This is where the code jumps to once we are loaded into long mode
entry64:
    ; Reset the segment registers
    mov ax, 0x00
    mov ss, ax
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    ; Reload the multiboot registers
    mov eax, [mboot_eax]
    mov ebx, [mboot_ebx]

    ; Print something to screen
    mov [0xb8000], byte 'a'

    ; Jump
    call c_entry


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;  BSS Section
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

section .bss

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;  Paging structures
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Make sure this section is aligned on a page boundary
align 0x1000

; We have a single pml4 (Page Map Level 4)
paging_pml4:
    resb 0x1000 ; All paging structures take up 0x1000 (4096/a single page) of bytes

; Two PDPTs (Page Directory Poitner Table). This is so we can map the physical address space to the higher half *and* identity map the lower half.
; This is so we can jump to long mode from protected mode before we can address the higher half.
paging_pdpt_low:
    resb 0x1000
paging_pdpt_high:
    resb 0x1000

; All of these following paging structures are used twice: once on the higher half and once on the lower half.
; There is also enough to address 1GB, which is much more than we need, but is a nice number that is easy to map (512 page tables)

; A single page directory
paging_pd:
    resb 0x1000

; 512 page tables (8GB of address space)
paging_pts:
    resb 0x1000 * 0x0200

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;  Other structures
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Multiboot saved info addresses
mboot_saved_info:
    mboot_eax: resd 1
    mboot_ebx: resd 1

; The stack
stack resb 1024 ; Reserve 1024 bytes of stack





;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;  Data section
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
section .data


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;  GDT structures
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; The pointer to the gdt
gdt64_ptr:
    gdt_size: dw no_offset(gdt64_end) - no_offset(gdt64_start) - 1
    gdt_offset: dd no_offset(gdt64_start) ; We want the physical address of the gdt

gdt64_start:
    gdt64_null:
        dd 0x00000000
        dd 0x00000000
    
    ; The code segment
    gdt64_code:
        dw 0xFFFF
        dw 0x0000
        db 0x00
        db 0b10011010
        db 0b10101111
        db 0x00
    
    gdt64_data:
        dw 0x0000
        dw 0x0000
        db 0x00
        db 0b10010010
        db 0b10101111
        db 0x00
gdt64_end:
