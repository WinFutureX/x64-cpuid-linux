; getcpuid: very basic cpuid info display for linux amd64.
; to assemble and run (without quotes):
; "nasm -felf64 getcpuid.asm && gcc getcpuid.o -o getcpuid && ./getcpuid"

; constants
	section	.data
welcome:
	db	"CPUID info display", 0Ah, 0

strcpuid:
	db	"cpuid: 0x%08X", 0Ah, 0

strhighest:
	db	"highest: %i (0x%08X)", 0Ah, 0

strhighestex:
	db	"highest extended: %i (0x%08X)", 0Ah, 0

strvendor:
	db	"vendor: %.12s", 0Ah, 0

strbrandsupp:
	db	"Brand string supported!", 0Ah, 0

strbrand:
	db	"brand: %s", 0Ah, 0

; variables
	section	.bss
vendor:
	resd	12				; cpu vendor id: ebx, ecx and edx

brand:
	resd	48				; cpu brand str

; code
	section	.text
	align	32
	global	main
	extern	printf

main:
	push	rbp				; set up stack frame, must be aligned
	; print welcome message
	mov	rdi, welcome
	xor	eax, eax
	call	printf
	; get cpuid
	mov	rbp, rsp
	sub	rsp, 16
	mov	eax, 1				; cpu info
	cpuid
	; print cpuid
	mov	rdi, strcpuid			; base str
	mov	esi, eax			; format var
	xor	eax, eax
	call	printf
	; get highest leaf & vendor
	push	rbx
	xor	eax, eax			; highest leaf supported
	cpuid
	mov	[vendor + 0], ebx
	mov	[vendor + 4], edx
	mov	[vendor + 8], ecx
	pop	rbx
	; print highest leaf
	mov	rdi, strhighest
	mov	esi, eax			; 1st format var
	mov	edx, eax			; 2nd format var
	xor	eax, eax
	call	printf
	; get highest extended leaf
	mov	eax, 0x80000000			; highest *extended* leaf supported
	cpuid
	push	rax				; save for later
	; print highest extended leaf
	mov	rdi, strhighestex
	mov	esi, eax			; 1st format var
	mov	edx, eax			; 2nd format var
	xor	eax, eax
	call	printf
	; print vendor
	mov	rdi, strvendor
	mov	rsi, vendor			; format var
	xor	eax, eax
	call	printf
	; check max flags
	pop	rax				; now we need it
	cmp	eax, 0x80000004
	jl	.exit				; if brand string unsupported
	mov	rdi, strbrandsupp
	xor	eax, eax
	call	printf
	; get brand
	mov	eax, 0x80000002			; 1st 16 chars
	cpuid
	mov	[brand + 0], eax
	mov	[brand + 4], ebx
	mov	[brand + 8], ecx
	mov	[brand + 12], edx
	mov	eax, 0x80000003			; 2nd 16 chars
	cpuid
	mov	[brand + 16], eax
	mov	[brand + 20], ebx
	mov	[brand + 24], ecx
	mov	[brand + 28], edx
	mov	eax, 0x80000004			; 3rd 16 chars
	cpuid
	mov	[brand + 32], eax
	mov	[brand + 36], ebx
	mov	[brand + 40], ecx
	mov	[brand + 44], edx
	; print brand
	mov	rdi, strbrand
	mov	rsi, brand			; format var
	xor	eax, eax
	call	printf
.exit:
	; exit, obviously
	mov	rsp, rbp
	pop	rbp
	xor	ebx, ebx			; exit code
	mov	eax, 1				; type of call (exit)
	int	80h				; system call
