
;Если определана то играем в счётчик иначе в АУ
;регистры АУ
AYREGS:
;частоты
;A
AYR0: db 0
AYR1: db 0
;B
AYR2: db 0
AYR3: db 0
;C
AYR4: db 0
AYR5: db 0
;NOISE
AYR6: db 0
;MIXER MASKS
AYR7: db 0
;VOLUME A
AYR8: db 0
;VOLUME B
AYR9: db 0
;VOLUME C
AYR10: db 0
;OGIBA FREQ
AYR11: db 0
AYR12: db 0
;OGIBA MODE
AYR13: db 0

LD_HL_CODE	EQU 0x2A
JP_CODE		EQU 0xC3

;состояние каналов 0 - заглушен 1 - играет
;обновляем из регистра микшера АУ - R7 и из громкостей по каналам
vCH1: db 0
vCH2: db 0
vCH3: db 0

flushVI:

	ld a,(AYR7)
	or a : rra : push af
	jp nc,a1;канал включен
    ld a,(vCH1) : or a : jp z,a2
    ld a,#36 : out (08),a;глушим канал
    xor a : ld (vCH1),a : jp a2
a1
	ld a,1 : ld (vCH1),a
a2
	pop af

	or a : rra : push af
	jp nc,b1;канал включен
    ld a,(vCH2) : or a : jp z,b2
    ld a,#76 : out (08),a;глушим канал
    xor a : ld (vCH2),a : jp b2
b1
	ld a,1 : ld (vCH2),a
b2	

	pop af

	or a : rra
	jp nc,c1;канал включен
    ld a,(vCH3) : or a : jp z,c2
    ld a,#b6 : out (08),a;глушим канал
    xor a : ld (vCH3),a : jp c2
c1
	ld a,1 : ld (vCH3),a
c2	


	;берём громкости
	ld a,(AYR8)
	;and 00001111b
	or a : jp nz,z1	
    ld a,(vCH1) : or a : jp z,z2
    ld a,#36 : out (08),a;глушим канал
    xor a : ld (vCH1),a : jp z2
z1
	ld a,1 : ld (vCH1),a
z2:

	ld a,(AYR9)
	;and 00001111b
	or a : jp nz,x1
    ld a,(vCH2) : or a : jp z,x2
    ld a,#76 : out (08),a;глушим канал
    xor a : ld (vCH2),a : jp x2
x1
	ld a,1 : ld (vCH2),a
x2

	ld a,(AYR10)
	;and 00001111b
	or a : jp nz,y1
    ld a,(vCH3) : or a : jp z,y2
    ld a,#b6 : out (08),a;глушим канал
    xor a : ld (vCH3),a : jp y2
y1
	ld a,1 : ld (vCH3),a
y2


	;пишем частоту
	ld a,(vCH1) : or a : jp z,h1;если канал включен суём частоту	
	ld hl,(AYR0) : call FreqAY_to_VI53
	ld a,l : out (#0b),a
	ld a,h : out (#0b),a
h1	

	ld a,(vCH2) : or a : jp z,h2;если канал включен суём частоту	
	ld hl,(AYR2) : call FreqAY_to_VI53
	ld a,l : out (#0a),a
	ld a,h : out (#0a),a
h2

	ld a,(vCH3) : or a : jp z,h3;если канал включен суём частоту	
	ld hl,(AYR4) : call FreqAY_to_VI53
	ld a,l : out (#09),a
	ld a,h : out (#09),a
h3
	ret


FreqAY_to_VI53:
		;dirty
		;add hl,hl : add hl,hl : add hl,hl : add hl,hl
		;ret
		;more precise
        ;l-low h-high freq
		ld	a,00001111b
		and	h
		ld	h, a
Not0Freq:
		push	bc
		ld	b,h
		ld	c,l
		add	hl,hl
		ld	e, l
		ld	d, h
		add	hl,hl
		add	hl,de
		add	hl,hl	;*12
		add	hl,bc	;*13
		ld	a,b
		or	a
		rra
		ld	b,a
		ld	a,c
		rra
		ld	c,a
		add	hl,bc	;*13.5
		pop	bc
		ret



;init = mus_init
;play =  trb_play
mus_stop
stop	
			ld a,#36 : out (08),a;
			ld a,#76 : out (08),a;
			ld a,#b6 : out (08),a;
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

			ld a,#36 : out (08),a;
			ld a,#76 : out (08),a;
			ld a,#b6 : out (08),a;
			
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
			

endtrack	;end of track
			pop	 hl
			jp mus_init
			

pl_frame	call pl0x						
after_play_frame
			xor	 a
			ld	 (stack_pos), a				
			
            ;save pos
	        ex	de,hl
			ld	hl, (trb_play+1)
			ld	(hl),e
			inc	l
			ld	(hl),d			

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
			call trb_play		
			call flushVI		
			ret

trb_play				
			ld hl, (stack_pos+1)
			ld a, (hl)
			add a
			jp nc, pl_frame				    
pl1x		;Process ref	
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
			;Save pos for the current nested level
			inc	 l
			ld	(hl),e
			inc	l
			ld	(hl),d
			inc  l							
same_level_ref
			ld	 (hl),a
			inc	 l
			;update nested level
			ld	 (trb_play+1),hl			

			ex	de,hl					
			add hl, bc	
			ld a, (hl)
			add a		            		
			call pl0x						
			;Save pos for the new nested level
			;save pos
	        ex	de,hl
			ld	hl, (trb_play+1)
			ld	(hl),e
			inc	l
			ld	(hl),d			
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
			;set pause
			ld (pause_rep), a	
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
		    ;psg1 or end of track
			cp #0f
			jp z, endtrack
			dec a	 
			inc hl
						
;===============================================================================						
			push de : push hl
			ld hl,AYREGS : ld e,a : ld d,0 : add hl,de : ex hl,de
			pop hl
			ld a,(hl) : inc hl : ld (de),a
			pop de
;===============================================================================						
			ret								

pl00		add	 a
			jp	 nc, pause_or_psg1
			
			;psg2i
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
			;save pos
	        ex	de,hl
			ld	hl, (trb_play+1)
			ld	(hl),e
			inc	l
			ld	(hl),d			

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

pl01	 ;player PSG2
			inc hl
			jp z, play_all_0_5				
play_by_mask_0_5
				add a
				jp c,f1
			    ld b,a;push af
				ld a,(hl) : inc hl
				ld (AYREGS + 0),a
				ld a,b;pop af				
f1		

				add a
				jp c,f2
			    ld b,a;push af
				ld a,(hl) : inc hl
				ld (AYREGS + 0),a
				ld a,b;pop af				
f2		

				add a
				jp c,f3
			    ld b,a;push af
				ld a,(hl) : inc hl
				ld (AYREGS + 0),a
				ld a,b;pop af				
f3		

				add a
				jp c,f4
			    ld b,a;push af
				ld a,(hl) : inc hl
				ld (AYREGS + 0),a
				ld a,b;pop af				
f4		

				add a
				jp c,f5
			    ld b,a;push af
				ld a,(hl) : inc hl
				ld (AYREGS + 0),a
				ld a,b;pop af				
f5		


			add a
			jp c, play_all_0_5_end						
			ld a,(hl) : inc hl
			ld (AYREGS + 5),a


second_mask	ld a, (hl)
			inc hl					
before_6    add a
			jp z,play_all_6_13							
			jp play_by_mask_13_6			
play_all_0_5			
			cpl						; 0->ff			
			ld a,(hl) : inc hl 			
			ld (AYREGS + 0),a			

				ld a,(hl) : inc hl 
				ld (AYREGS + 1),a
				ld a,(hl) : inc hl 
				ld (AYREGS + 2),a
				ld a,(hl) : inc hl 
				ld (AYREGS + 3),a
				ld a,(hl) : inc hl 
				ld (AYREGS + 4),a
				ld a,(hl) : inc hl 
				ld (AYREGS + 5),a
				
play_all_0_5_end
			ld a, (hl)
			inc hl					
			add a
			jp nz,play_by_mask_13_6
play_all_6_13
			cpl						; 0->ff, keep flag c
			; write regs [6..12] or [6..13] depend on flag
			jp	 c, h7				; 4+7=11	
				
				inc hl
				ld a,(hl) : inc hl
				ld (AYREGS + 7),a
				ld a,(hl) : inc hl
				ld (AYREGS + 8),a
				ld a,(hl) : inc hl
				ld (AYREGS + 9),a
				ld a,(hl) : inc hl
				ld (AYREGS + 10),a			
				inc hl
				inc hl				
				inc hl

			ret	
h7				
				inc hl
				ld a,(hl) : inc hl
				ld (AYREGS + 7),a
				ld a,(hl) : inc hl
				ld (AYREGS + 8),a
				ld a,(hl) : inc hl
				ld (AYREGS + 9),a
				ld a,(hl) : inc hl
				ld (AYREGS + 10),a
				inc hl
				inc hl
			ret			
			

play_by_mask_13_6
			jp c,h8
			inc hl
h8			
			add a
			jp c,h9
			inc hl
h9			

reg_left_6	add a
			jp c,e0
			inc hl
e0			
				add a
				jp c,e1
				ld e,a
				ld a,(hl) : inc hl 				
				ld (AYREGS + 10),a
				ld a,e
e1
				add a
				jp c,e2
				ld e,a
				ld a,(hl) : inc hl 				
				ld (AYREGS + 9),a
				ld a,e
e2
				add a
				jp c,e3
				ld e,a
				ld a,(hl) : inc hl 				
				ld (AYREGS + 8),a
				ld a,e
e3:
				add a
				jp c,e4
				ld e,a
				ld a,(hl) : inc hl 				
				ld (AYREGS + 7),a
				ld a,e
e4


 			add a
			ret c	
			inc hl
			ret		

reg_left_6_D5
			add a
			jp c,e5
			ld e,a;push af
			ld a,(hl) : inc hl
			ld (AYREGS + 5),a
			ld a,e;pop af
e5	

				add a
				jp c,g1
				ld e,a;push af
				ld a,(hl) : inc hl 				
				ld (AYREGS + 4),a
				ld a,e;pop af
g1					
				add a
				jp c,g2
				ld e,a;push af
				ld a,(hl) : inc hl 				
				ld (AYREGS + 3),a
				ld a,e;pop af
g2
				add a
				jp c,g3
				ld e,a;push af
				ld a,(hl) : inc hl 				
				ld (AYREGS + 2),a
				ld a,e;pop af
g3					
				add a
				jp c,g4
				ld e,a;push af
				ld a,(hl) : inc hl 				
				ld (AYREGS + 1),a
				ld a,e;pop af
g4										
			add a
			ret c
			ld a,(hl) : inc hl 
			ld (AYREGS + 0),a
			ret					

stack_pos	
			;Make sure packed file has enough nested level here
				DB 0	; counter
				DW 0	; HL value (position)
                DB 0	; counter
				DW 0	; HL value (position)
                DB 0	; counter
				DW 0	; HL value (position)
                DB 0	; counter
				DW 0	; HL value (position)
                DB 0	; counter
				DW 0	; HL value (position)
                DB 0	; counter
				DW 0	; HL value (position)
                DB 0	; counter
				DW 0	; HL value (position)
                DB 0	; counter
				DW 0	; HL value (position)			
stack_pos_end

