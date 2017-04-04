;
; CSC330_FinalExam.asm
;
; Created: 12/5/2016 8:34:50 PM
; Author : nick
;

.cseg
;setup registers
.def	io_set			=r16
.def	reg_workhorse	=r17
.def	wave_inc		=r18
.def	wave_tri		=r19
.def	adc_pot			=r20
.def	trigger			=r21
.def	wave_direction	=r22
.def	wave_sine		=r23
.def	temp_sreg		=r24
.def	switch			=r25

;set up vectors
.org	0x0000
		rjmp	setup
.org	0x001C
		rjmp	TIMER0_COMPA
.org	0x002A
		rjmp	ISR_ADC

.org	0x0100

;setup program
setup:	ser	io_set
		out DDRD, io_set

		; initialize stack
		ldi ZL, low(RAMEND)							
		sts	SPL, ZL
		ldi ZH, high(RAMEND)					
		sts SPH, ZH

		ldi ZL, low(sine_tbl* 2)
		ldi ZH, high(sine_tbl * 2)

		ldi	reg_workhorse, 0b00000010
		out	TCCR0A, reg_workhorse
		ldi	reg_workhorse, 0b00000011
		out TCCR0B, reg_workhorse
		ldi reg_workhorse, 0b00000010
		sts TIMSK0, reg_workhorse
		ldi reg_workhorse, 25
		out OCR0A, reg_workhorse

		; set up admux 
		ldi reg_workhorse, 0b01100101				
		sts ADMUX, reg_workhorse 					
		; set up adcsra 
		ldi reg_workhorse, 0b11101111	
		sts ADCSRA, reg_workhorse

		sei
		
;loop that jumps to sawtooth wave
loop:	;rjmp Sawtooth
		;rjmp Triangle
		rjmp Sine
		

;Sawtooth wave output
Sawtooth:	
			out PORTD, wave_inc
			rjmp loop
			
;Triangle wave output
Triangle:
			cpi trigger, 0b11111111
			breq setflag
			rjmp loop		

			setflag:
							ldi trigger, 0b00000000

			maintriangle:
							out PORTD, wave_tri
							cpi wave_direction, 0b00000000
							breq increment
							cpi wave_direction, 0b11111111
							breq decrement

			increment:	
							cpi wave_tri, 255
							breq direction_set
							inc wave_tri
							rjmp Triangle

			decrement:
							cpi wave_tri, 0
							breq direction_set
							dec wave_tri
							rjmp Triangle
							
			direction_set:
							ldi switch, 0b11111111
							eor wave_direction, switch
							rjmp maintriangle

;Sine wave output
Sine:

							cpi trigger, 0b11111111
							breq setsineflag
							rjmp loop

			setsineflag:	
							ldi trigger, 0b00000000
		
							lpm wave_sine, Z+
							out PORTD, wave_sine
							dec wave_sine
							cpi wave_sine, 0
							breq resetsine
							rjmp loop

			resetsine:
							ldi wave_sine, 255
							ldi ZL, low(sine_tbl* 2)
							ldi ZH, high(sine_tbl * 2)
							rjmp loop
							

;Timer compare A interrupt
TIMER0_COMPA:
				in temp_sreg, SREG							;push ant other regs of importance
				push temp_sreg
				;inc wave_inc

				ldi trigger, 0b11111111
				
				pop temp_sreg								; pop any other regs of importance
				out SREG, temp_sreg
				reti

ISR_ADC:	
			;push sreg
			in temp_sreg, SREG							;push ant other regs of importance
			push temp_sreg
				
			lds adc_pot,ADCH
			out OCR0A, adc_pot
				
			pop temp_sreg								; pop any other regs of importance
			out SREG, temp_sreg							; pop sreg
			
			
			reti					

sine_tbl:
.DB			128,131,134,137,140,143,146,149,152,155,158,162,165,167,170,173,176,179,182,185,188,190,193,196,198,201,203,206,208,211,213,215,218,220,222,224,226,228,230,232,234,235,237,238,240,241,243,244,245,246,248,249,250,250,251,252,253,253,254,254,254,255,255,255,255,255,255,255,254,254,254,253,253,252,251,250,250,249,248,246,245,244,243,241,240,238,237,235,234,232,230,228,226,224,222,220,218,215,213,211,208,206,203,201,198,196,193,190,188,185,182,179,176,173,170,167,165,162,158,155,152,149,146,143,140,137,134,131,128,124,121,118,115,112,109,106,103,100,97,93,90,88,85,82,79,76,73,70,67,65,62,59,57,54,52,49,47,44,42,40,37,35,33,31,29,27,25,23,21,20,18,17,15,14,12,11,10,9,7,6,5,5,4,3,2,2,1,1,1,0,0,0,0,0,0,0,1,1,1,2,2,3,4,5,5,6,7,9,10,11,12,14,15,17,18,20,21,23,25,27,29,31,33,35,37,40,42,44,47,49,52,54,57,59,62,65,67,70,73,76,79,82,85,88,90,93,97,100,103,106,109,112,115,118,121,124