[org 0x0000]

	%DEFINE magnetOS_VER '0.1'

start:
	; disable interupts
	cli
	
	; set SS
	mov ax, cs
	mov ss, ax
	
	; set SP
	mov sp, 0xFFFE
	
	cld
	
	; set ds es
	mov ax, cs
	mov ds, ax
	mov es, ax
	
	; call welcome
	call welcome
	
	; reenable interupts
	sti
	
	; go to main_loop
	jmp main_loop

welcome:
	; print welcome message
	mov bx, welcome_message
	call print
	
	; print new line
	mov bx, newline
	call print
	
	ret

; end welcome

; main_loop
main_loop:
	; print prompt
	mov bx, prompt
	call print
	
	mov di, input_buffer
	
; end main_loop

; read_char

read_char:
	; get key
	call getch
	
	; if enter is pressed je end_line
	cmp al, 0x0D
	je end_line
	
	cmp al, 0x08 ; backspace pressed
	je handle_backspace
	
	cmp di, input_buffer + 63
	jae read_char
	
	; echo normal characters
	mov ah, 0x0E
	int 0x10
	
	; store char in buffer
	mov [di], al
	inc di
	jmp read_char
	
; end read_char

; handle_backspace

handle_backspace:
	cmp di, input_buffer
	jbe .done
	
	dec di
	mov byte [di], 0
	
	; ERASE FROM SCREEN
	
	; print backspace (move cursor left)
	mov ah, 0x0E
	mov al, 0x08
	int 0x10
	
	; overwrite space
	mov ah, 0x0E
	mov al, ' '	;space
	int 0x10
	
	; move cursor left again
	mov ah, 0x0E
	mov al, 0x08
	int 0x10
	
.done:
	jmp read_char

; end handle_backspace

; end_line

end_line:
	; terminate string with 0
	mov byte [di], 0
	
	; print newline
	mov bx, newline
	call print
	
	
	; handle the command in input_buffer
	call handle_command
	
	
	; print another newline
	mov bx, newline
	call print
	
	; loop again
	jmp main_loop

; end end_line

; ----- data -----
welcome_message: db 0x0D, 0x0A, "Welcome to magnetOS", 0
newline: db 0x0D, 0x0A, 0
prompt: db "magnetOS> ", 0

input_buffer: times 64 db 0

; command strings
cmd_help: db "help", 0
cmd_clear: db "clear", 0
cmd_version: db "version ", 0
cmd_echo: db "echo", 0
cmd_reboot: db "reboot", 0

; command output
help_text: db "Commands: help, clear, version, echo, reboot", 0
version_text: db "magnetOS ", magnetOS_VER, " (Real Mode)", 0
unknown_command: db "Unknown command", 0

; ----- data -----

; ----- command handling -----

handle_command:
	; if empty returns
	mov si, input_buffer
	mov al, [si]
	cmp al, 0
	je .done
	
	; compare with "help"
	mov si, input_buffer
	mov di, cmd_help
	call str_eql
	je .do_help
	
	; compare with "clear"
	mov si, input_buffer
	mov di, cmd_clear
	call str_eql
	je .do_clear
	
	; compare with "version"
	mov si, input_buffer
	mov di, cmd_version
	call str_eql
	je .do_version
	
	; compare with "echo"
	mov si, input_buffer
	mov di, cmd_echo
	call str_eql
	je .do_echo
	
	; compare with "reboot"
	mov si, input_buffer
	mov di, cmd_reboot
	call str_eql
	je .do_reboot
	
	; unknown command
	mov bx, unknown_command
	call print
	mov bx, newline
	call print
	jmp .done

.do_help:
	mov bx, help_text
	call print
	mov bx, newline
	call print
	jmp .done

.do_clear:
	mov ax, 0x0003
	int 0x10
	jmp .done

.do_version:
	mov bx, version_text
	call print
	mov bx, newline
	call print
	jmp .done

.do_reboot:
	mov ax, 0
	int 0x19
	jmp .done
	
.do_echo:
	mov si, input_buffer
	call parse_args
	mov al, [si]
	cmp al, 0
	je .done
	
	mov bx, si
	call print
	jmp .done


.done:
	ret

; ----- command handling -----

; ----- functions -----

; parse_args
parse_args:
	.skip_command:
		mov al, [si]
		cmp al, 0
		je .no_args
		
		cmp al, ' '
		je .found_space
		
		inc si
		jmp .skip_command
	
	
.found_space:
.skip_spaces:
		inc si
		mov al, [si]
		cmp al, ' '
		je .skip_spaces
		
		ret
		
.no_args:
	ret

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
; getch
; waits for a key, returns ASCII in AL
getch:
	xor ah, ah
	int 0x16
	ret
	
str_eql:
	.compare_loop:
		mov al, [si]
		mov ah, [di]
		
		cmp ah, 0
		je .end_of_cmd ; reached end of cmd string
		
		cmp al, 0
		je .not_equal ; input ended before cmd finished
		
		cmp al, ah
		jne .not_equal ; not equal
		
		cmp al, 0
		je .equal ; equal
		
		inc si
		inc di
		jmp .compare_loop
		
.end_of_cmd:
	cmp al, 0
	je .equal
	cmp al, ' '
	je .equal
	jmp .not_equal

.not_equal:
	ret

.equal:
	ret

; ----- functions -----