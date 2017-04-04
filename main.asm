;
; beta.asm
;
; Created: 12/5/2016 6:05:07 PM
; Author : Nicholas
;BOHAY_FINAL_PROJECT_BETA
;
;display sawtooth wave

.cseg
;setup registers
.def	io_set			=r16
.def	reg_workhorse	=r17
.def	wave_inc		=r18
.def	wave_temp		=r19

;set up vectors
.org	0x0000
		rjmp	setup
.org	0x001C
		rjmp	TIMER0_COMPA
.org	0x0100

;setup program
setup:	ser	io_set
		out DDRD, io_set
		ldi	reg_workhorse, 0b00000010
		out	TCCR0A, reg_workhorse
		ldi	reg_workhorse, 0b00000101
		out TCCR0B, reg_workhorse
		ldi reg_workhorse, 0b00000010
		sts TIMSK0, reg_workhorse
		ldi reg_workhorse, 255
		out OCR0A, reg_workhorse

		; initialize stack
		ldi ZL, low(RAMEND)							
		sts	SPL, ZL
		ldi ZH, high(RAMEND)					
		sts SPH, ZH
		sei
		
;loop that jumps to sawtooth wave
loop:	rjmp Sawtooth
		rjmp loop

;Sawtooth wave output
Sawtooth:	
			out PORTD, wave_inc
			rjmp loop

;Timer compare A interrupt
TIMER0_COMPA:
				inc wave_inc
				reti
						