;Template created by ANTONIO COULTON
;Email: acelectronics@murena.io
;Last updated June 2025

;TO ENABLE CORRECT OPERATION OF RESET AND INTERRUPT VECTORS: --HIGHLY IMPORTANT--
   ;under Project Properties, pic-as Linker, under Custom linker options, include a copy of the following line:
   ;"-PRES_VECT=0x00;-PINT_VECT=0x04" 

PROCESSOR 16F88
   
CONFIG  FOSC = INTOSCIO       ; Oscillator Selection bits (INTRC oscillator; port I/O function on both RA6/OSC2/CLKO pin and RA7/OSC1/CLKI pin)
CONFIG  WDTE = OFF            ; Watchdog Timer Enable bit (WDT disabled)
CONFIG  PWRTE = OFF           ; Power-up Timer Enable bit (PWRT disabled)
CONFIG  MCLRE = OFF            ; RA5/MCLR/VPP Pin Function Select bit (RA5/MCLR/VPP pin function is MCLR)
CONFIG  BOREN = ON            ; Brown-out Reset Enable bit (BOR enabled)
CONFIG  LVP = ON              ; Low-Voltage Programming Enable bit (RB3/PGM pin has PGM function, Low-Voltage Programming enabled)
CONFIG  CPD = OFF             ; Data EE Memory Code Protection bit (Code protection off)
CONFIG  WRT = OFF             ; Flash Program Memory Write Enable bits (Write protection off)
CONFIG  CCPMX = RB0           ; CCP1 Pin Selection bit (CCP1 function on RB0)
CONFIG  CP = OFF              ; Flash Program Memory Code Protection bit (Code protection off)
CONFIG  FCMEN = ON            ; Fail-Safe Clock Monitor Enable bit (Fail-Safe Clock Monitor enabled)
CONFIG  IESO = ON             ; Internal External Switchover bit (Internal External Switchover mode enabled)
    
#include <xc.inc>
   
CLONE	EQU 0x20	;value used to refer to memory store in interrupt routine

WAIT1	EQU 0x21	;values used to refer to memory stores used in wait delays
WAIT10	EQU 0x22	
WAIT100	EQU 0x23	
WAIT1k	EQU 0x24
WAIT10s	EQU 0x25

PEDFLAG	EQU 0X40
	
;variables used to point to memory stores for the readadc routines
ADC0	EQU 0x32

STATE1 EQU 00011000B	;TL1 GO
STATE2 EQU 00010100B	;TL1 SLOW
STATE3 EQU 00110010B	;TL1 STOP, TL2 PREPARE
STATE4 EQU 01000010B	;TL2 GO
STATE5 EQU 00100010B	;TL2 SLOW
STATE6 EQU 00010110B	;TL2 STOP, TL1 PREPARE
STATE7 EQU 00010010B	;TL1&2 STOP, PED GO
	
;================================== RESET & INTERRUPT VECTORS  =============================	
psect RES_VECT,class=CODE,delta=2 ; PIC10/12/16
RES_VECT:
    nop
    goto start
    
PSECT INT_VECT,class=CODE,delta=2
INT_VECT:
    movwf CLONE		    ;create a copy of the current working register
    btfss INTCON,1	    ;check interrupt has occured, skips if true
    retfie		    ;set GI and RETURN in a single clock cycle
    call your_interrupt
    bcf INTCON,1	    ;reset the interrupt flag
    movf CLONE,0x00	    ;return the saved working register back for use (working register address 0x00)
    retfie

;************************************ INTERRUPT ROUTINE ************************************
your_interrupt:    
    bsf PEDFLAG,0	;set pedestrian flag
    return

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
	movlw 00000001B	    ;PORTA,0
	bsf STATUS,5
	movwf ANSEL
	bcf STATUS,5
	movlw 01000001B	    ;01XXX001, three blank bits tell ADCON0 which analog input to check
	movwf ADCON0
	bsf ADCON0,2	    ;start adc conversion
loopadc0:
	clrwdt		    ;Pat the watchdog
	btfsc ADCON0,2	    ;check if conversion finished
	goto loopadc0
	movf ADRESH,0x00	    ;take result from ADRESH
	movwf ADC0	    ;move result to ADC0
	return

wait2sec:
	call wait1000ms
	call wait1000ms
	return

wait10sec:	;custom wait routine for 10 seconds
	movlw 10
	movwf WAIT10s
loop10sec:
	call wait1000ms
	decfsz WAIT10s
	goto loop10sec
	return

checkped:
	btfss PEDFLAG,0	;check pedestrian flag
	return	;no pedestrians -> continue
	movlw STATE7	;pedestrians waiting -> allow to cross
	movwf PORTB
	bcf PORTA,2
	bsf PORTA,3
	call wait10sec
	bsf PORTA,2
	bcf PORTA,3
	clrf PEDFLAG
	return

;================================ INITIALISATION ===============================
;PORTB,0 is the default interrupt trigger - ensure this is set as 1 if used as such.
;PORTA,5 must ALWAYS be an input.
;PORTA,0,1,2,3 are all usable as analog inputs.

start:
    clrf PORTA
    clrf PORTB
    bsf STATUS,5	;change RP0 to 1 to select BANK1
    movlw 01100000B	;set the clock speed to 4MHz
    movwf OSCCON 	;move the new clock speed to the clock controller.	
    clrf ANSEL		;disable adc
    movlw 11110011B	;call on the decided Inputs/outputs for PORTA
    movwf TRISA		
    movlw 00000001B	;call on the decided i/o for PORTB
    movwf TRISB		
    movlw 00000000B	;Vref is power supply voltage & left justified
    movwf ADCON1	;configured ready to use readadc subroutines
    bcf STATUS,5	;change RP0 to 0 to select BANK0
    
;uncomment the next lines to enable interrupt routines
    bsf INTCON,4	;set the external interrupt enable
    bsf INTCON,7	;enable all interruptions

;============================= MAIN PROGRAM =======================================
	clrf PEDFLAG	;ensure pedflag clear to begin with
main:
    movlw STATE1
	movwf PORTB
	call wait10sec
	movlw STATE2
	movwf PORTB
	call wait2sec
	call checkped	;between steps 2 and 3, check for pedestrians
	movlw STATE3
	movwf PORTB
	call wait2sec
	movlw STATE4
	movwf PORTB
	call wait10sec
	movlw STATE5
	movwf PORTB
	call wait2sec
	call checkped
	movlw STATE6
	movwf PORTB
	call wait2sec
	goto main
    
END
