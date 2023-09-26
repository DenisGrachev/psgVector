
/*
Player for Fast PSG Packer for compression levels [4..5]
Source for sjasm cross-assembler.
Source code is based on psndcj/tbk player and bfox/tmk player.
Modified by physic 8.12.2021.

8080 Version by Denis Grachev

Max time is 930t for compression level 4 (recomended), 1032t for compression level 5
Player size is increased from 348 to 543 bytes.

11hhhhhh llllllll nnnnnnnn	3	CALL_N - вызов с возвратом для проигрывания (nnnnnnnn + 1) значений по адресу 11hhhhhh llllllll
10hhhhhh llllllll			2	CALL_1 - вызов с возвратом для проигрывания одного значения по адресу 11hhhhhh llllllll
01MMMMMM mmmmmmmm			2+N	PSG2 проигрывание, где MMMMMM mmmmmmmm - инвертированная битовая маска регистров, далее следуют значения регистров.
							во 2-м байте также инвертирован порядок следования регистров (13..6)

001iiiii 					1	PSG2i проигрывание, где iiiii номер индексированной маски (0..31), далее следуют значения регистров
0001pppp					1	PAUSE16 - пауза pppp+1 (1..16)
0000hhhh vvvvvvvv			2	PSG1 проигрывание, 0000hhhh - номер регистра + 1, vvvvvvvv - значение
00001111					1	маркер оцончания трека
00000000 nnnnnnnn			2	PAUSE_N - пауза nnnnnnnn+1 фреймов (ничего не выводим в регистры)


Nested loops are fully supported at this version. Please make sure there is enough room for nested levels.
Packer shows max nested level. It need to increase MAX_NESTED_LEVEL variable if it not enough.
*/


;AY PORTS - NOW FOR VECTOR-06C
AY_DATA = #14
AY_REG = #15

MAX_NESTED_LEVEL EQU 8

LD_HL_CODE	EQU 0x2A
JP_CODE		EQU 0xC3

			MACRO SAVE_POS
				ex	de,hl
				ld	hl, (trb_play+1)
				ld	(hl),e
				inc	l
				ld	(hl),d						
			ENDM
							
;init = mus_init
;play =  trb_play
mus_stop
stop	
			ld d,#0d			
1:			
			ld a,d : out (AY_REG),a
			xor a : out (AY_DATA),a
			dec d
			jp nz,1b

			ret

mus_init	ld hl, music
			ld	 a, l
			ld	 (mus_low+1), a
			ld	 a, h
			ld	 (mus_high+1), a
			ld	de, 16*4
			add	 hl, de
			ld (stack_pos+1), hl
			ld a, LD_HL_CODE
			ld (trb_play), a

			xor a
			ld hl, stack_pos
			ld (hl), a
			inc hl

			ld (trb_play+1), hl			
			ret							

pause_rep	db 0
trb_pause	ld hl,pause_rep
			dec	 (hl)
			ret nz						

			ld a,(savedByte) : ld (trb_play+2),a

saved_track	
			ld hl, LD_HL_CODE			; end of pause
			ld (trb_play), hl
			ld	hl, (trb_play+1)		
			jp trb_rep					

endtrack	//end of track
			pop	 hl
			jp mus_init
		

pl_frame	call pl0x						
after_play_frame
			xor	 a
			ld	 (stack_pos), a				
			SAVE_POS 						
			dec	 l							
trb_rep		dec	 l
			dec (hl)
			ret	 nz							
trb_rest	
			dec	 l
			dec	 l
			ld	 (trb_play+1), hl
			ret								

mus_play
trb_play				
			ld hl, (stack_pos+1)
			ld a, (hl)
			add a
			jp nc, pl_frame				    
pl1x		// Process ref	
			ld b, (hl)
			inc hl
			ld c, (hl)
			inc hl
			jp p, pl10						

pl11		
			ld a, (hl)			
			inc hl	
			ex	de,hl
			ld  hl, (trb_play+1)
			dec	 l
			dec (hl)
			jp	 z, same_level_ref			
nested_ref
			// Save pos for the current nested level
			inc	 l
			ld	(hl),e
			inc	l
			ld	(hl),d
			inc  l							
same_level_ref
			ld	 (hl),a
			inc	 l
			// update nested level
			ld	 (trb_play+1),hl			

			ex	de,hl					
			add hl, bc	
			ld a, (hl)
			add a		            		
			call pl0x						
			// Save pos for the new nested level
			SAVE_POS 						
			ret							 
			

savedByte: db 0

single_pause
			pop	 de
			jp	 after_play_frame
long_pause
			inc	 hl
			ld	 a, (hl)
			inc hl
			jp	 pause_cont
pl_pause	and	 #0f
			inc hl
			jp z, single_pause
pause_cont	
			//set pause
			ld (pause_rep), a	
			//SAVE_POS
			ex	de,hl
			ld	hl, (trb_play+1)
			ld  a, l
			ld (saved_track+2), a			

			ld	(hl),e
			inc	l
			ld	(hl),d						
			
			ld a,(trb_play+2) : ld (savedByte),a
;=====================================================================		    
			ld a,JP_CODE : ld (trb_play),a
			ld hl,trb_pause : ld (trb_play+1),hl						
;=====================================================================
			
			
			pop	 hl						
			ret								

pause_or_psg1
			add	 a
			ld a, (hl)
			jp c, pl_pause
			jp z, long_pause
		    //psg1 or end of track
			cp #0f
			jp z, endtrack
			dec a	 
			inc hl

			out (AY_REG),a
			ld a,(hl) : inc hl  
			out (AY_DATA),a
			
			ret								

pl00		add	 a
			jp	 nc, pause_or_psg1						
			
		// psg2i
			rrca : rrca						
			
		
			ld de,00000

mus_low		add	 0
			ld	 e, a
mus_high	adc	 0
			sub	 e
			ld	 d, a					
			ld	 a,(de)
			inc	 de
			
							
			push de
			
			inc	 hl						
			call reg_left_6_D5

			
			pop de
			ld	 a, (de)			
					
			add a			
			jp play_by_mask_13_6

			

pl10
			SAVE_POS 						

			ex	de,hl

			;set 6, b
			ld a,b : or 01000000b : ld b,a

			add hl,bc

			ld a, (hl)
			add a		            		
			
			call pl0x
			ld	hl, (trb_play+1)
			jp trb_rep						


pl0x						
			add a					
			jp nc, pl00						

pl01	// player PSG2
			inc hl	
			jp z, play_all_0_5				
play_by_mask_0_5
CH = 0
			dup 5
				add a
				jp c,1f
			    ld b,a;push af
				ld a,CH : out (AY_REG),a
				ld a,(hl) : inc hl
				out (AY_DATA),a
				ld a,b;pop af				
CH=CH+1				
1	
			edup							

		
			add a
			jp c, play_all_0_5_end			
			ld a,5 : out (AY_REG),a
			ld a,(hl) : inc hl
			out (AY_DATA),a


second_mask	ld a, (hl)
			inc hl					
before_6    add a
			jp z,play_all_6_13						
			jp play_by_mask_13_6
			
play_all_0_5
	
			cpl						; 0->ff

			ld a,0 : out (AY_REG),a
			ld a,(hl) : inc hl 
			out (AY_DATA),a

			
CHN = 1
			dup 4				
				ld a,CHN : out (AY_REG),a
				ld a,(hl) : inc hl 
				out (AY_DATA),a			
							
CHN = CHN + 1				
			edup					

			

			ld a,CHN : out (AY_REG),a
			ld a,(hl) : inc hl 
			out (AY_DATA),a
				

play_all_0_5_end
			ld a, (hl)
			inc hl					
			add a
			jp nz,play_by_mask_13_6
play_all_6_13
					
			cpl						; 0->ff, keep flag c
			// write regs [6..12] or [6..13] depend on flag
			jp	 c, 7f					
CHL = 5			
			dup 8
CHL = CHL + 1													
				ld a,CHL : out (AY_REG),a
				ld a,(hl) : inc hl :
				out (AY_DATA),a			
;1				
			edup
			ret	
7:
CHL = 5			
			dup 7
CHL = CHL + 1										
				ld a,CHL : out (AY_REG),a
				ld a,(hl) : inc hl :
				out (AY_DATA),a			
;1				
			edup
			ret			
			

play_by_mask_13_6
			jp c,1f
			ld b,a;push af
			ld a,13 : out (AY_REG),a
			ld a,(hl) : inc hl 
  			out (AY_DATA),a
			ld a,b;pop af			
1			

			add a
			jp c,1f
			ld b,a;push af
			ld a,12 : out (AY_REG),a
			ld a,(hl) : inc hl : 
   			out (AY_DATA),a
			ld a,b;pop af			
1			

reg_left_6	add a
			jp c,1f
			ld e,a;push af
			ld a,11 : out (AY_REG),a
			ld a,(hl) : inc hl
			out (AY_DATA),a
			ld a,e;pop af

1			
CH = 11
			dup 4
CH = CH - 1			
				add a
				jp c,1f
				ld e,a;push af
				ld a,CH : out (AY_REG),a	
				ld a,(hl) : inc hl 				
				out (AY_DATA),a
				ld a,e;pop af
1									
			edup

 			add a
			ret c	
			ld a,CH-1 : out (AY_REG),a
			ld a,(hl) : inc hl 
			out (AY_DATA),a
			
			ret		

reg_left_6_D5
			add a
			jp c,1f
			ld e,a;push af
			ld a,5 : out (AY_REG),a
			ld a,(hl) : inc hl
			out (AY_DATA),a
			ld a,e;pop af

1			
CH=5
			dup 4
CH=CH-1			
				add a
				jp c,1f

				ld e,a;push af
				ld a,CH : out (AY_REG),a	
				ld a,(hl) : inc hl 				
				out (AY_DATA),a
				ld a,e;pop af
1									
			edup
 			add a
			ret c
CH=CH-1		
			;ld e,a;push af
			ld a,CH : out (AY_REG),a
			ld a,(hl) : inc hl 
			out (AY_DATA),a
			;ld a,e;pop af
			ret					

stack_pos	
			dup MAX_NESTED_LEVEL		// Make sure packed file has enough nested level here
				DB 0	// counter
				DW 0	// HL value (position)
			edup
stack_pos_end
;			ASSERT high(stack_pos) == high(stack_pos_end), Please move player code in memory for several bytes.
			DISPLAY	"player code occupies ", /D, $-stop, " bytes"
