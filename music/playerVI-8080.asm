

        
;Если определана то играем в счётчик иначе в АУ
;регистры АУ
AYREGS:
;частоты
;A
AYR0:  db 0
AYR1:  db 0
;B
AYR2:  db 0
AYR3:  db 0
;C
AYR4:  db 0
AYR5:  db 0
;NOISE
AYR6:  db 0
;MIXER MASKS
AYR7:  db 0
;VOLUME A
AYR8:  db 0
;VOLUME B
AYR9:  db 0
;VOLUME C
AYR10:  db 0
;OGIBA FREQ
AYR11:  db 0
AYR12:  db 0
;OGIBA MODE
AYR13:  db 0

LD_HL_CODE		EQU 0x2A
JP_CODE			EQU 0xC3

;состояние каналов 0 - заглушен 1 - играет
;обновляем из регистра микшера АУ - R7 и из громкостей по каналам
vCH1:  db 0
vCH2:  db 0
vCH3:  db 0

flushVI:
	lda AYR7
	ora a 
        rar
        push psw
	 jnc a1
	;канал включен
        lda vCH1
        ora a
         jz a2
        mvi a,$36
        out 08
	;глушим канал
        xra a
        sta vCH1
        jmp a2
a1:
	mvi a,1
        sta vCH1
a2:
	pop psw

	ora a
        rar
        push psw
	 jnc b1
	;канал включен
	lda vCH2
	ora a
	 jz b2
	mvi a,$76
	out 08
	;глушим канал
        xra a
	sta vCH2
	jmp b2
b1:
	mvi a,1
	sta vCH2
b2:
	pop psw

	ora a
	rar
	 jnc c1
	;канал включен
	lda vCH3
	ora a
	 jz c2
	mvi a,$b6
	out 08
	;глушим канал
	xra a
	sta vCH3
	jmp c2
c1:
	mvi a,1
	sta vCH3
c2:
	;берём громкости
	lda AYR8
	;and 00001111b
	ora a
	 jnz z1	
	lda vCH1
	ora a
	 jz z2
	mvi a,$36
	out 08
	;глушим канал
	xra a
	sta vCH1
	jmp z2
z1:
	mvi a,1
	sta vCH1
z2:
	lda AYR9
	;and 00001111b
	ora a
	 jnz x1
	lda vCH2
	ora a
	 jz x2
    	mvi a,$76
	out 08
	;глушим канал
	xra a
	sta vCH2
	jmp x2
x1:
	mvi a,1
	sta vCH2
x2:
	lda AYR10
	;and 00001111b
	ora a
	 jnz y1
	lda vCH3
	ora a
	 jz y2
	mvi a,$b6
	out 08
	;глушим канал
	xra a
	sta vCH3
	jmp y2
y1:
	mvi a,1
	sta vCH3
y2:
	;пишем частоту
	lda vCH1
	ora a
	 jz h1
	;если канал включен суём частоту	
	lhld AYR0
	call FreqAY_to_VI53
	mov a,l
	out $0b
	mov a,h
	out $0b
h1:
	lda vCH2
	ora a
	 jz h2
	;если канал включен суём частоту	
	lhld AYR2
	call FreqAY_to_VI53
	mov a,l
	out $0a
	mov a,h
	out $0a
h2:
	lda vCH3
	ora a
	 jz h3
	;если канал включен суём частоту	
	lhld AYR4
	call FreqAY_to_VI53
	mov a,l
	out $09
	mov a,h
	out $09
h3:
	ret

FreqAY_to_VI53:
		;dirty
		;add hl,hl : add hl,hl : add hl,hl : add hl,hl
		;ret
		;more precise
	        ;l-low h-high freq
		mvi a,00001111b
		ana h
		mov h,a
Not0Freq:
		push b
		mov b,h
		mov c,l
		dad h
		mov e,l
		mov d,h
		dad h
		dad d
		dad h	
		;*12
		dad b
		;*13
		mov a,b
		ora a
		rar
		mov b,a
		mov a,c
		rar
		mov c,a
		dad b
		;*13.5
		pop b
		ret

;init = mus_init
;play =  trb_play
mus_stop:
stop:
		mvi a,$36
		out 08
		mvi a,$76
		out 08
		mvi a,$b6
		out 08
		ret

mus_init:
		lxi h,music
		mov a,l
		sta mus_low+1
		mov a,h
		sta mus_high+1
		lxi d,16*4
		dad d
		shld stack_pos+1
		mvi a,LD_HL_CODE
		sta trb_play

		xra a
		lxi h,stack_pos
		mov m,a
		inx h

		shld trb_play+1

		mvi a,$36
		out 08
		mvi a,$76
		out 08
		mvi a,$b6
		out 08
		
		ret			
					
			

pause_rep:
			db 0
trb_pause:
			lxi h,pause_rep
			dcr m
			 rnz						

			lda savedByte
			sta trb_play+2

saved_track:
			lxi h,LD_HL_CODE
			; end of pause
			shld trb_play
			lhld trb_play+1
			jmp trb_rep					
			

endtrack:
			;end of track
			pop h
			jmp mus_init
			

pl_frame:
			call pl0x						
after_play_frame:
			xra a
			sta stack_pos
			
	            ;save pos
		        xchg
			lhld trb_play+1
			mov m,e
			inr l
			mov m,d			

			dcr l							
trb_rep:
			dcr l
			dcr m
			 rnz							
trb_rest:	
			dcr l
			dcr l
			shld trb_play+1
			ret								

mus_play:
			call trb_play		
			call flushVI		
			ret

trb_play:
			lhld stack_pos+1
			mov a,m
			add a
			 jnc pl_frame				    
pl1x:
			;Process ref	
			mov b,m
			inx h
			mov c,m
			inx h
			jp pl10						
pl11:		
			mov a,m			
			inx h	
			xchg
			lhld trb_play+1
			dcr l
			dcr m
			 jz same_level_ref			
nested_ref:
			;Save pos for the current nested level
			inr l
			mov m,e
			inr l
			mov m,d
			inr l							
same_level_ref:
			mov m,a
			inr l
			;update nested level
			shld trb_play+1

			xchg					
			dad b	
			mov a,m
			add a		            		
			call pl0x						
			;Save pos for the new nested level
			;save pos
		        xchg
			lhld trb_play+1
			mov m,e
			inr l
			mov m,d			
			ret							 
			

savedByte:
	 db 0

single_pause:
			pop d
			jmp after_play_frame
long_pause:
			inx h
			mov a,m
			inx h
			jmp pause_cont
pl_pause:
			ani $0f
			inx h
			 jz single_pause
pause_cont:
			;set pause
			sta pause_rep
			xchg
			lhld trb_play+1
			mov a,l
			sta saved_track+2

			mov m,e
			inr l
			mov m,d						
			
			lda trb_play+2
			sta savedByte
;=====================================================================		    
			mvi a,JP_CODE
			sta trb_play
			lxi h,trb_pause
			shld trb_play+1
;====================================================================						
			pop h						
			ret								
pause_or_psg1:
			add a
			mov a,m
			 jc pl_pause
			 jz long_pause
		    ;psg1 or end of track
			cpi $0f
			 jz endtrack
			dcr a	 
			inx h
						
;===============================================================================						
			push d
			push h
			lxi h,AYREGS	
			mov e,a
			mvi d,0
			dad d
			xchg
			pop h
			mov a,m
			inx h
			stax d
			pop d
;===============================================================================						
			ret								

pl00:
			add a
			 jnc pause_or_psg1
			
			;psg2i
			rrc
			rrc						
				
			lxi d,00000

mus_low:
			adi 0
			mov e,a
mus_high:
			aci 0
			sub e
			mov d,a					
			ldax d
			inx d
			
					
			push d
			inx h							
			call reg_left_6_D5

			
			pop d
			ldax d			
					
			add a			
			jmp play_by_mask_13_6

		

pl10:
			;save pos
		        xchg
			lhld trb_play+1
			mov m,e
			inr l
			mov m,d			

			xchg

			;set 6, b
			mov a,b
			ori 01000000b
			mov b,a

			dad b

			mov a,m
			add a		            		
			
			call pl0x
			lhld trb_play+1
			jmp trb_rep						
			


pl0x:
			add a					
			 jnc pl00						

pl01:
			 ;player PSG2
			inx h
			 jz play_all_0_5				
play_by_mask_0_5:
				add a
				 jc f1
	    		    mov b,a			
				mov a,m 
				 inx h
				sta AYREGS+0
				mov a,b
f1:

				add a
				 jc f2
			    mov b,a
				mov a,m
				 inx h
				sta AYREGS+0
				mov a,b
f2:

				add a
				 jc f3
			    mov b,a
				mov a,m
				 inx h
				sta AYREGS+0
				mov a,b
f3:

				add a
				 jc f4
			    mov b,a
				mov a,m
				inx h
				sta AYREGS+0
				mov a,b
f4:

				add a
				 jc f5
			    mov b,a
				mov a,m
				 inx h
				sta AYREGS+0
				mov a,b
f5:
			add a
			 jc play_all_0_5_end						
			mov a,m
			 inx h
			sta AYREGS+5
second_mask:
			mov a,m
			inx h					
before_6:
			add a
			 jz play_all_6_13							
			jmp play_by_mask_13_6			
play_all_0_5:
			cma	
			; 0->ff			
			mov a,m
			inx h 			
			sta AYREGS+0

				mov a,m
				inx h 
				sta AYREGS+1
				mov a,m
				inx h 
				sta AYREGS+2
				mov a,m
				inx h 
				sta AYREGS+3
				mov a,m
				inx h 
				sta AYREGS+4
				mov a,m
				inx h 
				sta AYREGS+5
				
play_all_0_5_end:
			mov a,m
			inx h					
			add a
			 jnz play_by_mask_13_6
play_all_6_13:
			cma					
			; 0->ff, keep flag c
			; write regs [6..12] or [6..13] depend on flag
			 jc h7				; 4+7=11	
				
				inx h
				mov a,m
				inx h
				sta AYREGS+7
				mov a,m
				inx h
				sta AYREGS+8
				mov a,m
				inx h
				sta AYREGS+9
				mov a,m
				inx h
				sta AYREGS+10
				inx h
				inx h				
				inx h
			ret	
h7:
				inx h
				mov a,m
				inx h
				sta AYREGS+7
				mov a,m
				inx h
				sta AYREGS+8
				mov a,m
				inx h
				sta AYREGS+9
				mov a,m
				inx h
				sta AYREGS+10
				inx h
				inx h
			ret			
			

play_by_mask_13_6:
			 jc h8
			inx h
h8:
			add a
			 jc h9
			inx h
h9:

reg_left_6:
			add a
			 jc e0
			inx h
e0:
				add a
				 jc e1
				mov e,a
				mov a,m
				inx h 				
				sta AYREGS+10
				mov a,e
e1:
				add a
				 jc e2
				mov e,a
				mov a,m
				inx h 				
				sta AYREGS+9
				mov a,e
e2:
				add a
				 jc e3
				mov e,a
				mov a,m
				inx h 				
				sta AYREGS+8
				mov a,e
e3:
				add a
				 jc e4
				mov e,a
				mov a,m
				inx h 				
				sta AYREGS+7
				mov a,e
e4:


 			add a
			 rc	
			inx h
			ret		

reg_left_6_D5:
			add a
			 jc e5
			mov e,a
			mov a,m
			inx h
			sta AYREGS+5
			mov a,e
e5:

				add a
				 jc g1
				mov e,a
				mov a,m
				inx h 				
				sta AYREGS+4
				mov a,e
g1:
				add a
				 jc g2
				mov e,a
				mov a,m
				inx h 				
				sta AYREGS+3
				mov a,e
g2:
				add a
				 jc g3
				mov e,a
				mov a,m
				inx h 				
				sta AYREGS+2
				mov a,e
g3:
				add a
				 jc g4
				mov e,a
				mov a,m
				inx h 				
				sta AYREGS+1
				mov a,e
g4:
			add a
			 rc
			mov a,m
			inx h 
			sta AYREGS+0
			ret					

stack_pos:
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
stack_pos_end: