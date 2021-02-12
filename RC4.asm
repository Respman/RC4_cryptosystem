extern printf

section .data
	sys_open equ 5
	sys_close equ 6
	sys_write equ 4
	sys_read equ 3
	sys_creat equ 8
	sys_lseek equ 19

	SEEK_SET equ 0

	O_RDONLY equ 0
	O_WRONLY equ 1

	Msg db "get_is_ok", 0x0A, 0
	Msglen equ $-Msg
	Errmsg db "error", 0x0A, 0
	Errlen equ $-Errmsg
	open_f dd 0
	encrypt_f dd 0
	key_f dd 0
	filename db "key.txt", 0

	S: times 256 db 0
	key: times 256 db 0
	tmp db 0
	shift db 0x0A

	p_fmt db "@%c", 0x0A, 0


section .text
global main
main:
	
	mov 	ecx, [esp + 4]
	cmp 	ecx, 4
	jne 	fail
	
	mov 	ecx, [esp + 8]
	mov 	ebx, [ecx + 4]
	mov 	eax, sys_open
	mov 	ecx, O_RDONLY
	xor 	edx, edx
	int 	0x80	
	cmp 	eax, 0
	jng 	fail
	mov 	[open_f], eax

	mov 	ecx, [esp + 8]
	mov 	eax, sys_open
	mov 	ebx, [ecx + 8]
	mov 	ecx, O_RDONLY
	xor 	edx, edx
	int 	0x80
	cmp 	eax, 0
	jng 	fail
	mov 	[key_f], eax

	mov 	ecx, [esp + 8]
	mov 	eax, sys_creat
	mov 	ebx, [ecx + 12]
	mov 	ecx, 0777
	int 	0x80
	cmp 	eax, 0
	jng 	fail
	mov 	[encrypt_f], eax

preparing_for_KSA:

	mov 	eax, sys_lseek
	mov 	ebx, [key_f]
	mov 	ecx, 0
	mov 	edx, SEEK_SET
	int 	0x80
	cmp 	eax, -1
	je		fail
	mov 	ecx, 256
	xor 	edx, edx


lp_S_and_key:
	push 	ecx
	push 	edx
	
	mov 	eax, sys_read
	mov 	ebx, [key_f]
	mov		ecx, tmp
	mov 	edx, 1
	int 	0x80
	
;	cmp 	byte [tmp], 0x0A
	cmp 	eax, 0
	jne 	skip

	mov 	eax, sys_lseek
	mov 	ebx, [key_f]
	mov 	ecx, 0
	mov 	edx, SEEK_SET
	int 	0x80
	mov 	eax, sys_read
	mov 	ebx, [key_f]
	mov		ecx, tmp
	mov 	edx, 1
	int 	0x80
skip:
	movsx 	eax, byte [tmp]
	pop 	edx
	mov 	byte [key + edx], al

	mov 	byte [S + edx], dl
	inc 	edx
	pop 	ecx
	loop 	lp_S_and_key

;print_key:
;	mov 	eax, sys_write
;	mov 	ebx, 1
;	mov 	ecx, key
;	mov 	edx, 256
;	int 0x80

;print_shift:
;	mov 	eax, sys_write
;	mov 	ebx, 1
;	mov 	ecx, shift
;	mov 	edx, 1
;	int 0x80


;print_S:
;	mov 	eax, sys_write
;	mov 	ebx, 1
;	mov 	ecx, S
;	mov 	edx, 256
;	int 0x80

KSA:
	mov 	ecx, 256
	xor 	eax, eax

KSA_lp:
	add 	al, byte [S + ecx]
	add 	al, byte [key + ecx]
	mov 	bl, byte [S + ecx]
	mov 	dl, byte [S + eax]
	xor 	bl, dl
	xor 	dl, bl
	xor 	bl, dl
	mov 	byte [S + ecx], bl
	mov 	byte [S + eax], dl
	loop 	KSA_lp

PRGA:
	xor 	ecx, ecx
	mov 	cl, -1
	xor 	edx, edx

	mov 	esi, ecx
	mov 	edi, edx

PRGA_lp:
	mov 	eax, sys_read
	mov 	ebx, [open_f]
	mov 	ecx, tmp
	mov 	edx, 1
	int 	0x80
	cmp 	eax, 0
	je 		close_all
	mov 	ecx, esi
	mov 	edx, edi

	inc 	cl
	add 	dl, byte[S + ecx]
	
	mov 	al, byte [S + ecx]
	mov 	bl, byte [S + edx]
	xor 	al, bl
	xor 	bl, al
	xor 	al, bl
	mov 	byte [S + ecx], al
	mov 	byte [S + edx], bl

	add 	al, bl
	mov 	al, byte [S + eax]
	xor 	byte [tmp], al

 	mov 	esi, ecx
	mov 	edi, edx
	mov 	eax, sys_write
	mov 	ebx, [encrypt_f]
	mov 	ecx, tmp
	mov 	edx, 1
	int 	0x80
	jmp 	PRGA_lp

close_all:
	mov 	eax, sys_close
	mov 	ebx, [open_f]
	int 	0x80

	mov 	eax, sys_close
	mov 	ebx, [encrypt_f]
	int 	0x80

	mov 	eax, sys_close
	mov 	ebx, [key_f]
	int 	0x80

exit:
	mov 	eax, 1
	int 	0x80

fail:
	mov 	eax, sys_write
	mov 	ebx, 1
	mov 	ecx, Errmsg
	mov 	edx, Errlen
	int 	0x80
	jmp 	exit
