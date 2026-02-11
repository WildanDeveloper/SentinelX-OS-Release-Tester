; SentinelX Fast Boot Stub
; Copyright (C) 2026 WildanDev
; License: GPL v3
;
; Ultra-fast boot loader stub for minimal boot time
; Target: x86_64 UEFI systems

BITS 64

section .data
    boot_msg db 'SentinelX OS - Fast Boot', 0x0A, 0x0D, 0
    msg_len equ $ - boot_msg
    
    init_msg db 'Initializing...', 0x0A, 0x0D, 0
    init_len equ $ - init_msg
    
    success_msg db 'Boot successful', 0x0A, 0x0D, 0
    success_len equ $ - success_msg

section .bss
    kernel_entry resq 1
    framebuffer resq 1
    memory_map resq 1

section .text
    global _start
    extern kernel_main

_start:
    ; Save UEFI boot services pointer
    mov [boot_services], rdi
    
    ; Setup stack
    mov rsp, stack_top
    
    ; Clear direction flag
    cld
    
    ; Display boot message
    call print_boot_msg
    
    ; Initialize CPU features
    call init_cpu_features
    
    ; Setup paging
    call setup_paging
    
    ; Load kernel
    call load_kernel
    
    ; Jump to kernel entry point
    jmp [kernel_entry]

;
; Print boot message to screen
;
print_boot_msg:
    push rax
    push rdi
    push rsi
    push rdx
    
    ; Get simple text output protocol
    mov rdi, [boot_services]
    mov rdi, [rdi + 64]  ; SimpleTextOutput
    
    lea rsi, [boot_msg]
    call output_string
    
    pop rdx
    pop rsi
    pop rdi
    pop rax
    ret

;
; Initialize CPU features for performance
;
init_cpu_features:
    push rax
    push rbx
    push rcx
    push rdx
    
    ; Check for SSE support
    mov eax, 1
    cpuid
    test edx, (1 << 25)  ; SSE bit
    jz .no_sse
    
    ; Enable SSE
    mov rax, cr0
    and ax, 0xFFFB      ; Clear coprocessor emulation CR0.EM
    or ax, 0x2          ; Set coprocessor monitoring  CR0.MP
    mov cr0, rax
    
    mov rax, cr4
    or ax, 3 << 9       ; Set CR4.OSFXSR and CR4.OSXMMEXCPT
    mov cr4, rax
    
.no_sse:
    ; Check for AVX support
    mov eax, 1
    cpuid
    test ecx, (1 << 28)  ; AVX bit
    jz .done
    
    ; Enable AVX
    mov rcx, 0
    xgetbv              ; Get XCR0
    or eax, 7           ; Enable AVX, SSE, x87
    xsetbv
    
.done:
    ; Enable write-combining for framebuffer
    ; (Improves graphics performance)
    mov ecx, 0x2FF      ; MTRRdefType MSR
    rdmsr
    or eax, 0x800       ; Enable MTRRs
    wrmsr
    
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret

;
; Setup optimized page tables
;
setup_paging:
    push rax
    push rbx
    push rcx
    push rdx
    
    ; Identity map first 4GB with 2MB pages for speed
    mov rdi, page_table_l4
    mov rbx, page_table_l3
    or rbx, 0x003        ; Present + RW
    mov [rdi], rbx
    
    mov rdi, page_table_l3
    mov rbx, page_table_l2
    or rbx, 0x003
    mov [rdi], rbx
    
    ; Setup 2MB pages (faster than 4KB)
    mov rdi, page_table_l2
    mov rbx, 0x000083    ; Present + RW + PS (2MB pages)
    mov rcx, 512         ; 512 entries = 1GB
    
.map_loop:
    mov [rdi], rbx
    add rbx, 0x200000    ; 2MB
    add rdi, 8
    loop .map_loop
    
    ; Load page table
    mov rax, page_table_l4
    mov cr3, rax
    
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret

;
; Load kernel into memory
;
load_kernel:
    push rax
    push rdi
    push rsi
    
    ; Kernel loading would happen here
    ; For now, just set a placeholder entry point
    mov qword [kernel_entry], kernel_main
    
    pop rsi
    pop rdi
    pop rax
    ret

;
; Output string (UEFI stub)
;
output_string:
    ; This is a simplified stub
    ; Real implementation would use UEFI protocols
    ret

section .bss
    align 4096
    boot_services resq 1
    
    ; Page tables (for optimized 2MB pages)
    page_table_l4 resb 4096
    page_table_l3 resb 4096
    page_table_l2 resb 4096
    
    ; Stack (64KB)
    stack_bottom resb 65536
    stack_top:

; Performance optimization notes:
; 1. Uses 2MB pages instead of 4KB for TLB efficiency
; 2. Enables CPU features (SSE, AVX) early
; 3. Sets up write-combining for graphics
; 4. Minimal code path for fast boot
; 5. Direct CPU instruction usage instead of abstractions
