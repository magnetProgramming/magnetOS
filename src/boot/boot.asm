[bits 16]
[org 0x7c00]

start:
	; disable interupts
	cli
	
	; set SS
	mov ax, 0x0000
	mov ss, ax
	
	; set SP
	mov sp, 0x7C00
	
	cld
	
	; set ds es
	mov ax, cs
	mov ds, ax
	mov es, ax
	
	; call welcome
	call load
	
	mov ax, 0x1000  
	mov es, ax
	mov bx, 0x0000
	
	mov ax, 0x0220
	
	mov ch, 0x0
	mov dh, 0x0
	mov CL, 0x2
	
	int 13h
	
	jc disk_error
	
	; reenable interupts
	sti

	jmp 0x1000:0

; end start

; welcome

load:
	; print welcome message
	mov bx, load_message
	call print
	
	; print new line
	mov bx, newline
	call print
	
	ret

; end welcome

disk_error:
	; print disk error message
	mov bx, disk_error_message
	call print
	mov bx, newline
	call print
	
	jmp start

; ----- data -----
load_message: db 0x0D, 0x0A, "Loading magnetOS...", 0
disk_error_message: db 0x0D, 0x0A, "Failed to read disk", 0
disk_success_message: db 0x0D, 0x0A, "Successfully read disk", 0
newline: db 0x0D, 0x0A, 0

; ----- data -----

; ----- functions -----

; print
print:
	pusha
	mov ah, 0x0E
	.print_loop:
		mov al, [bx]
		cmp al, 0
		je .done
		int 0x10
		inc bx
		jmp .print_loop
	.done:
		popa
		ret		
; ----- functions -----

; ----- BOOT SECTOR FOOTER -----

times 510 -($ - $$) db 0 ; padding up to 510 bytes
dw 0xAA55 ; magic boot signature 510-511 = 0x55, 0xAA

; ----- BOOT SECTOR FOOTER -----