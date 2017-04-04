; CSC330_FinalExam.asm
; tag v.1.0
; Nicholas Bohay
; 12/13/2016
; CSC-330 
; final code for 8 bit Monophonic Synthesizer for CSC330 Final Project 

.cseg
;setup registers
.def    sine_inc        =r16
.def    reg_workhorse   =r17
.def    wave_inc        =r18
.def    wave_tri        =r19
.def    adc_pot         =r20
.def    trigger         =r21
.def    wave_direction  =r22
.def    wave_sine       =r23
.def    temp_sreg       =r24
.def    switch          =r25

;set up vectors
.org    0x0000
        rjmp    setup                                                           ;setup vector
.org    0x001C
        rjmp    TIMER0_COMPA                                                    ;TIMER0/COMPA vector
.org    0x002A
        rjmp    ISR_ADC                                                         ;ISR_ADC vector

.org    0x0100

;setup program
setup:                             ser      reg_workhorse
                                   out      DDRD, reg_workhorse

                                   ;initialize stack
                                   ldi      ZL, low(RAMEND)                            
                                   out      SPL, ZL
                                   ldi      ZH, high(RAMEND)                    
                                   out      SPH, ZH

                                   ;set up sine table
                                   ldi      ZL, low(sine_tbl* 2)
                                   ldi      ZH, high(sine_tbl * 2)

                                   ;set up the TCCR0A,TCCR0B, TIMSK0, OCR0A
                                   ldi      reg_workhorse, 0b00000010
                                   out      TCCR0A, reg_workhorse
                                   ldi      reg_workhorse, 0b00000101
                                   out      TCCR0B, reg_workhorse
                                   ldi      reg_workhorse, 0b00000010
                                   sts      TIMSK0, reg_workhorse
                                   ldi      reg_workhorse, 25
                                   out      OCR0A, reg_workhorse

                                   ;set up ADMUX
                                   ldi      reg_workhorse, 0b01100101                
                                   sts      ADMUX, reg_workhorse                     
                                   ;set up ADCSRA
                                   ldi      reg_workhorse, 0b11101111    
                                   sts      ADCSRA, reg_workhorse

                                   sei
        
;loop that jumps to each wave output when commented out
loop:                              rjmp     Sawtooth
                                   ;rjmp    Triangle
                                   ;rjmp    Sine
        
            ;Sawtooth wave output
            Sawtooth:              out     PORTD, wave_inc                    ;outputs sinewave to PortD
                                   rjmp    loop
            
            ;Triangle wave output
            Triangle:              cpi     trigger, 0b11111111                ;checks if trigger is set then resets it. and moves to main
                                   breq    setflag                            ;resets the trigger to 0
                                   rjmp    loop        

                    setflag:       ldi     trigger, 0b00000000                ;resets the trigger form 1 to 0
                    
                    maintriangle:  out     PORTD, wave_tri                    ;outputs wave_tri checks the direction of the triangle wave 
                                   cpi     wave_direction, 0b00000000         ;checks another flag wave direction to decide if incrementing or decrementing
                                   breq    increment
                                   cpi     wave_direction, 0b11111111
                                   breq    decrement
                    
                    increment:     cpi     wave_tri, 255                      ;if flag is set to 00000000 then increments to 255
                                   breq    direction_set
                                   inc     wave_tri
                                   rjmp    Triangle
                    
                    decrement:     cpi     wave_tri, 0                        ;checks if flag set to 11111111 then decrements to 255
                                   breq    direction_set
                                   dec     wave_tri
                                   rjmp    Triangle
                    
                    direction_set: ldi     switch, 0b11111111                 ;flips the direction of the triangle wave, if at 255 decrements, if at 0 increments        
                                   eor     wave_direction, switch
                                   rjmp    maintriangle

            ;Sine wave output
            Sine:                  cpi     trigger, 0b11111111                ;checks if the trigger has been set 
                                   breq    setsineflag                        ;resets trigger value
                                   rjmp    loop

                    setsineflag:   ldi     trigger, 0b00000000                ;switches the trigger value to 0 
        
                    mainsine:      lpm     wave_sine, Z+                      ;gets the next pointer value
                                   out     PORTD, wave_sine                   ;outputs value onto PortD
                                   inc     sine_inc                           ;increments sine_inc from 0 to 255
                                   cpi     sine_inc, 255                      ;checks if the sine_inc has gotten to 255 and then resets 
                                   breq    resetsine
                                   rjmp    loop

                    resetsine:     ldi     sine_inc, 0                        ;sets sine_inc to 0 and resets the pointer 
                                   ldi     ZL, low(sine_tbl* 2)
                                   ldi     ZH, high(sine_tbl * 2)
                                   rjmp    loop
                            

;Timer compare A interrupt
TIMER0_COMPA:                      in      temp_sreg, SREG                    ;push regs of importance
                                   push    temp_sreg

                                   inc     wave_inc
                                   ldi     trigger, 0b11111111
                
                                   pop     temp_sreg                          ;pop any other regs of importance
                                   out     SREG, temp_sreg
                                   reti

;Get the potentiometer value 
ISR_ADC:                           in      temp_sreg, SREG                    ;push sreg                    
                                   push    temp_sreg
                                     
                                   lds     adc_pot,ADCH                       ;checks potentiometer value 
                                   out     OCR0A, adc_pot                            
                
                                   pop     temp_sreg                                
                                   out     SREG, temp_sreg                    ;pop sreg
                                   reti        
                        
; sine table based on internet sine wave table generator
sine_tbl:                          .DB     128,131,134,137,140,143,146,149,152,155,158,162,165,167,170,173,176,179,182,185,188,190,193,196,198,201,203,206,208,211,213,215,218,220,222,224,226,228,230,232,234,235,237,238,240,241,243,244,245,246,248,249,250,250,251,252,253,253,254,254,254,255,255,255,255,255,255,255,254,254,254,253,253,252,251,250,250,249,248,246,245,244,243,241,240,238,237,235,234,232,230,228,226,224,222,220,218,215,213,211,208,206,203,201,198,196,193,190,188,185,182,179,176,173,170,167,165,162,158,155,152,149,146,143,140,137,134,131,128,124,121,118,115,112,109,106,103,100,97,93,90,88,85,82,79,76,73,70,67,65,62,59,57,54,52,49,47,44,42,40,37,35,33,31,29,27,25,23,21,20,18,17,15,14,12,11,10,9,7,6,5,5,4,3,2,2,1,1,1,0,0,0,0,0,0,0,1,1,1,2,2,3,4,5,5,6,7,9,10,11,12,14,15,17,18,20,21,23,25,27,29,31,33,35,37,40,42,44,47,49,52,54,57,59,62,65,67,70,73,76,79,82,85,88,90,93,97,100,103,106,109,112,115,118,121,124,128