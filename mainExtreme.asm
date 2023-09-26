	DEVICE ZXSPECTRUM48

	org 100h
begin:
	jp start
start:
	di	
	xor a :  out (10h),a;отключить квазидиск
	ld a,#c3      ; установить переход (код команды JMP) в
	ld (0000h),a  ; нулевой адрес и
	ld (0038h),a  ; адрес вызова прерывания.
	ld hl,main : ld (0001h),hl
	ld hl,ints : ld (0039h),hl		
	jp main
	
	include "include\ints.a80"
	include "include\system.a80"
	include "music\playerExtreme.asm"

main:
	ld sp,100h
	ei : halt
	halt	

	call mus_init	

mainLoop:	
	halt	
	;немного задержки чтобы было видно время выполнения
	ld b,120
1:
	push hl : pop hl : dec b : jp nz,1b

	ld a,1 : out (2),a	
	call mus_play	
	ld a,0 : out (2),a	
	

	jp mainLoop


music:	incbin "music\music4.tbk"

	savebin "mainExtreme.rom",begin,$-begin
            


                                                                                                        

