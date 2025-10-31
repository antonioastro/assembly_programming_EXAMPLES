;Template created by ANTONIO COULTON
;Email: acelectronics@murena.io
;Last updated August 2025
    
PROCESSOR 12F510 ;tell the software which chip is used.
   
  CONFIG  OSC = IntRC           ; Oscillator Select (INTOSC with 1.125 ms DRT)
  CONFIG  WDT = OFF             ; Watchdog Timer Enable bit (WDT disabled)
  CONFIG  CP = OFF              ; Code Protect (Code protection off)
  CONFIG  MCLRE = OFF           ; Master Clear Enable bit (GP3/MCLR pin functions as GP3, MCLR internally tied to VDD)
  CONFIG  IOSCFS = OFF          ; Internal Oscillator Frequency Select bit (4 MHz INTOSC Speed)
    
#include <xc.inc>
  
WAIT1	EQU 0x21	;values used to refer to memory stores used in wait delays
WAIT10	EQU 0x22	
WAIT100	EQU 0x23	
WAIT1k	EQU 0x24
	
;variables used to point to memory stores for the readadc routines
ADC0	EQU 0x32
	
;===================================== SUBROUTINES ========================================
psect code

wait1ms:    ;@4MHz, the exe rate = 1MIP, t=1us. 1000 total instructions needed to make 1ms.
    movlw 255	    ;+1 instruction
    movwf WAIT1	    ;+1
loop1ms:
	decfsz WAIT1,1	;+1*255
	goto loop1ms	;+2(255-1)
	movlw 77		;+1
	movwf WAIT1		;+1
loop1ms2:
	decfsz WAIT1,1	;+1*77
	goto loop1ms2	;+2(77-1)
	nop		;+1
	nop		;+1
	return	;+2 = 1000 total instructions

wait10ms: ;requires 10,000 instructions
	movlw 10	;+1
	movwf WAIT10	;+1
loop10ms:
	call wait1ms ;10*1000 instructions
	decfsz WAIT10,1 ;+10
	goto loop10ms ;+2*9
	return ;+2 = 10,030 total

wait100ms: ;requires 100,000 instructions
	movlw 100	    ;+1
	movwf WAIT100	    ;+1
loop100ms:
	call wait1ms	    ;+100*1000
	decfsz WAIT100,1    ;+100
	goto loop100ms	    ;+99*2
	return		    ;+2 = 100,302

wait1000ms:		;requires 1,000,000 instructions
	movlw 10	;+1
	movwf WAIT1k	;+1
loop1000ms:
	call wait100ms	;+10*100,302
	decfsz WAIT1k,1	;+10
	goto loop1000ms	;+2*9
	return		;+2 = 1,003,052

readadc0:
	movlw 11000001
	movwf ADCON0
	bsf ADCON0,1	;start adc conversion
loopadc0:
	clrwdt		    ;Pat the watchdog
	btfsc ADCON0,1	    ;check if conversion finished
	goto loopadc0
	movf ADRES,0x00	    ;take result from ADRESH
	movwf ADC0	    ;move result to ADC0
	return

variabletime:
	call readadc0
	sublw 1
	btfsc STATUS,0 ;the carry flag is clear if carry occurs when subtracting
	goto vartimeloop
	return
vartimeloop:
	call wait100ms
	decfsz ADC0,1
	goto vartimeloop
	return

psect RES_VECT,class=CODE,delta=2 ; PIC10/12/16. "-PRES_VECT=0x00" must be present as a custom linker option in the project properties.
RES_VECT:
    movlw 001111	
    movwf TRISIO	;GP3 must be INPUT.
    bcf ADCON0,0	;adc OFF by default.

main:
    btfsc GPIO,1
    goto main
    bsf GPIO,4
    call variabletime
    bcf GPIO,4
    goto main
	
	END
