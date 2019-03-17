extern GetStdHandle
extern WriteConsoleA
extern ReadConsoleA
extern ExitProcess

global main

%include "../defines.h"

section .data
error_msg: db "Invalid input. Integer only, please!", 13, 10, 0

section .text

main:
    push    rbp
    mov     rbp, rsp

    sub     rsp, 512

    mov     rcx, -11 ; stdout
    call    GetStdHandle
    mov     qword STD_OUT_HANDLE, rax

    mov     rcx, -10 ; stdin
    call    GetStdHandle
    mov     qword STD_INPUT_HANDLE, rax

    mov     qword READ_FROM_CONSOLE, 0
    mov     qword WRITTEN_TO_CONSOLE, 0

; get user input
    mov     rcx, rax                ; stdin handle
    lea     rdx, INPUT_BUFFER       ; pointer to input buffer
    mov     r8, MAX_INPUT           ; limited to 12 atm
    lea     r9, READ_FROM_CONSOLE   ; function will tell us how many chars it read
    and     rsp, -16                ; align stack
    push    0                       ; last parameter not used (specifies a control character to signal end of read)
    sub     rsp, 32
    call    ReadConsoleA
    add     rsp, 32

; convert to number
    lea     rcx, INPUT_BUFFER
    mov     rdx, qword READ_FROM_CONSOLE
    mov     rbx, 10
    xor     r8, r8
    xor     rax, rax
.convert_loop:
    cmp     rdx, 0
    jz      .conversion_successful

    mov     al, byte [rcx]
    cmp     al, 48              ; less than '0'?
    jl      .invalid_input?
    cmp     al, 57              ; greater than '9'?
    jg      .invalid_input? 

    sub     al, 48              ; n - '0' gives actual decimal digit
    imul    r8, rbx
    add     r8, rax

    dec     rdx
    inc     rcx

    jmp     .convert_loop

.invalid_input?:
    cmp     al, 13                  ; carriage retur
    jz      .conversion_successful
    cmp     al, 10                  ; newline
                                    ; either of these means the user supplied a valid string
                                    ; and that we've reached the end
    jz      .conversion_successful

    lea     rcx, [rel error_msg]
    call    string_length

    mov     rcx, qword STD_OUT_HANDLE
    lea     rdx, [rel error_msg]
    mov     r8,  rax
    lea     r9,  WRITTEN_TO_CONSOLE
    and     rsp, -16
    push    0
    sub     rsp, 32
    call    WriteConsoleA
    add     rsp, 32

    jmp    .end

.conversion_successful:
    mov     qword INPUT_NUMBER, r8

.find_end_of_userinput:
    lea     rcx, INPUT_BUFFER
    mov     r9, qword READ_FROM_CONSOLE

.feof_loop:
    cmp     r9, 0
    jz      .found_end
    cmp     byte [rcx], 0x0d     ; search for carriage return
    jz      .found_end
    inc     rcx
    dec     r9
    jmp     .feof_loop

    ; this means the user entered >= 12 digits
.found_end:
    mov     qword END_OF_STRING, rcx
    sub     qword READ_FROM_CONSOLE, r9 ; set new length of string

.reverse_factorial:
    mov     rcx, 2
    mov     rax, qword INPUT_NUMBER
    xor     rdx, rdx

.rf_loop:
    div     rcx

    cmp     rax, 1
    jz      .is_remainder_zero

    cmp     rdx, 0
    jnz     .not_factorial

    inc     rcx

    jmp     .rf_loop

.is_remainder_zero:
    cmp     rdx, 0
    jnz     .not_factorial

;   rcx contains x!
;   turn it into a string
    mov     rsi, END_OF_STRING
    mov     rax, 0x00203d20       ; " = "
    mov     dword [rsi], eax
    mov     r8, 3
    add     rsi, 3

    mov     rbx, 10
    mov     rax, rcx
    lea     rcx, TEMP_BUFFER
    xor     rdi, rdi
.factorial_to_string:
    cmp     rax, 0
    jz      .copy_from_temp

    xor     rdx, rdx
    div     rbx
    add     rdx, 48

    mov     byte [rcx], dl

    inc     rdi
    inc     rcx
    jmp     .factorial_to_string

.copy_from_temp:
    dec     rcx     ; now points to first digit
    mov     r9, rdi
    add     r8, rdi

.cft_loop:
    cmp     r9, 0
    jz      .append

    mov     al, byte [rcx]
    mov     byte [rsi], al

    inc     rsi
    dec     r9
    dec     rcx

    jmp     .cft_loop

.append:
    mov     rax, 0x000a0d21             ; "!\r\n\0"
    mov     dword [rsi], eax
    add     r8, 3
    add     qword READ_FROM_CONSOLE, r8
    jmp     .end

.not_factorial:
    mov     rcx, END_OF_STRING
    mov     rax, 0x0d454e4f4e202020     ; "   NONE\r"  (can't move 64 bit immediate into memory)
    mov     qword [rcx], rax 
    mov     word [rcx+8], 0x00a         ; "\n\0"
    add     qword READ_FROM_CONSOLE, 9  ; number of chars just added

.end:
    mov     rcx, qword STD_OUT_HANDLE
    lea     rdx, INPUT_BUFFER
    mov     r8, qword READ_FROM_CONSOLE
    lea     r9, WRITTEN_TO_CONSOLE
    and     rsp, -16
    push    0
    sub     rsp, 32
    call    WriteConsoleA
    add     rsp, 32

    mov     rsp, rbp
    pop     rbp
    mov     eax, 0
    and     rsp, -16
    call    ExitProcess

string_length:
    xor     rax, rax 
.loop:
    cmp     byte [rcx], 0
    jz      .end
    inc     rax
    inc     rcx
    jmp     .loop
.end:
    ret
