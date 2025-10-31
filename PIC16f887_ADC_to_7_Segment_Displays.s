;Template created by Antonio Coulton
;Email: acelectronics@murena.io
;Last updated August 2025

;TO ENABLE CORRECT OPERATION OF RESET AND INTERRUPT VECTORS: --HIGHLY IMPORTANT--
   ;under Project Properties, pic-as Linker, under Custom linker options, include a copy of the following line:
   ;"-PRES_VECT=0x00;-PINT_VECT=0x04" 

PROCESSOR 16F887

  CONFIG  FOSC = INTRC_NOCLKOUT ; Oscillator Selection bits (INTOSCIO oscillator)
  CONFIG  WDTE = OFF            ; Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
  CONFIG  PWRTE = OFF           ; Power-up Timer Enable bit (PWRT disabled)
  CONFIG  MCLRE = OFF            ; RE3/MCLR pin function select bit (RE3/MCLR pin function is MCLR)
  CONFIG  CP = OFF              ; Code Protection bit (Program memory code protection is disabled)
  CONFIG  CPD = OFF             ; Data Code Protection bit (Data memory code protection is disabled)
  CONFIG  BOREN = ON            ; Brown Out Reset Selection bits (BOR enabled)
  CONFIG  IESO = ON             ; Internal External Switchover bit (Internal/External Switchover mode is enabled)
  CONFIG  FCMEN = ON            ; Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is enabled)
  CONFIG  LVP = ON              ; Low Voltage Programming Enable bit (RB3/PGM pin has PGM function, low voltage programming enabled)
  CONFIG  BOR4V = BOR40V        ; Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
  CONFIG  WRT = OFF             ; Flash Program Memory Self Write Enable bits (Write protection off)
   
#include <xc.inc>
   
CLONE	EQU 0x20	;value used to refer to memory store in interrupt routine

WAIT1	EQU 0x21	;values used to refer to memory stores used in wait delays
WAIT10	EQU 0x22	
WAIT100	EQU 0x23	
WAIT1k	EQU 0x24
	
ADCTEMP	EQU 0x31	;variables used to point to memory stores for the readadc routines
ADC0	EQU 0x32

BINARY_INPUT EQU 0x40
NUM_100s    EQU 0x41
NUM_10s	EQU 0x42
NUM_1s	EQU 0x43

;NUM	EQU abcdefg0B
NINE	EQU 11011110B
EIGHT	EQU 11111110B
SEVEN	EQU 00001110B
SIX	EQU 11111010B
FIVE	EQU 11011010B
FOUR	EQU 11001100B
THREE	EQU 10011110B
TWO	EQU 10110110B
ONE	EQU 00001100B
ZER0	EQU 01111110B


	
;===================================== RESET & INTERRUPT VECTORS  =================================	
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

;**************************************** INTERRUPT ROUTINE ***********************************
your_interrupt:    
    nop
    return

;========================================== SUBROUTINES =========================================
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
	bsf ADCON0,1	    ;start adc conversion
loopadc0:
	clrwdt		    ;Pat the watchdog
	btfsc ADCON0,1	    ;check if conversion finished
	goto loopadc0
	movf ADRESH,w	    ;take result from ADRESH
	movwf ADC0	    ;move result to ADC0
	return

;================================ INITIALISATION ===============================
;PORTB,0 is the default interrupt trigger - ensure this is set as 1 if used as such.
;PORTA,5 must ALWAYS be an input.
;PORTA are all usable as analog inputs.
;PORTE,3 must be an INPUT.

start:
    clrf PORTA
    clrf PORTB
    clrf PORTC
    clrf PORTD
    clrf PORTE
    bsf STATUS,5	;change RP0 to 1 to select BANK1
    movlw 01100000B	;set the clock speed to 4MHz 
    movwf OSCCON 	;move the new clock speed to the clock controller.	
    clrf ANSEL		;disable adc
    movlw 00000001B	;call on the decided Inputs/outputs for PORTA
    movwf TRISA		
    movlw 00000001B	;call on the decided i/o for PORTB
    movwf TRISB
    movlw 00000000B	;call on the decided i/o for PORTC
    movwf TRISC
    movlw 00000000B	;call on the decided i/o for PORTD
    movwf TRISD
    movlw 1000B	;call on the decided i/o for PORTE
    movwf TRISE
    movlw 00000000B	;Vref is power supply voltage & left justified
    movwf ADCON1	;configured ready to use readadc subroutines
    bcf STATUS,5	;change RP0 to 0 to select BANK0
    
;uncomment the next lines to enable interrupt routines
    ;bsf INTCON,4	;set the external interrupt enable
    ;bsf INTCON,7	;enable all interruptions
    
;=============================== MAIN PROGRAM =====================================
main:
    call readadc0 
    movf ADC0,w
    ;movlw 178
    movwf BINARY_INPUT
    bsf STATUS,0
    clrf NUM_100s
    clrf NUM_10s
    clrf NUM_1s
dec_100_loop:
    movlw 100
    subwf BINARY_INPUT	    ;subtract 100 from value
    btfss STATUS,0	    ;check if is <0 - check carry flag in STATUS register
    goto reset_value_100s   ;if is <0, move on to test num 10s
    incf NUM_100s	    ;else +1 to 100s counter
    goto dec_100_loop	    ;repeat to test again
reset_value_100s:
    movlw 100
    addwf BINARY_INPUT
dec_10_loop:
    movlw 10
    subwf BINARY_INPUT	    ;subtract 10 from the remainder value after removing 100s
    btfss STATUS,0	    ;check if <0
    goto reset_value_10s    ;if <0, move on to get num 1s
    incf NUM_10s	    ;else +1 to 10s counter
    goto dec_10_loop	    ;repeat to test 10s again
reset_value_10s:
    movlw 10
    addwf BINARY_INPUT
units:
    movf BINARY_INPUT,w	    ;put number of units into its own memory
    movwf NUM_1s
    
check_100s_digit_is_2:
    movf NUM_100s,w
    sublw 2
    btfss STATUS,2
    goto check_100s_digit_is_1
    movlw TWO
    movwf PORTD
    goto check_10s_digit_is_9
    
check_100s_digit_is_1:
    movf NUM_100s,w
    sublw 1
    btfss STATUS,2
    goto check_100s_digit_is_0
    movlw ONE
    movwf PORTD
    goto check_10s_digit_is_9
    
check_100s_digit_is_0:
    movf NUM_100s,w
    sublw 0
    btfss STATUS,2
    nop
    movlw ZER0
    movwf PORTD
    goto check_10s_digit_is_9
    
check_10s_digit_is_9:
    movf NUM_10s,w
    sublw 9
    btfss STATUS,2
    goto check_10s_digit_is_8
    movlw NINE
    movwf PORTC
    goto check_1s_digit_is_9

check_10s_digit_is_8:
    movf NUM_10s,w
    sublw 8
    btfss STATUS,2
    goto check_10s_digit_is_7
    movlw EIGHT
    movwf PORTC
    goto check_1s_digit_is_9

check_10s_digit_is_7:
    movf NUM_10s,w
    sublw 7
    btfss STATUS,2
    goto check_10s_digit_is_6
    movlw SEVEN
    movwf PORTC
    goto check_1s_digit_is_9
    
check_10s_digit_is_6:
    movf NUM_10s,w
    sublw 6
    btfss STATUS,2
    goto check_10s_digit_is_5
    movlw SIX
    movwf PORTC
    goto check_1s_digit_is_9
    
check_10s_digit_is_5:
    movf NUM_10s,w
    sublw 5
    btfss STATUS,2
    goto check_10s_digit_is_4
    movlw FIVE
    movwf PORTC
    goto check_1s_digit_is_9
    
check_10s_digit_is_4:
    movf NUM_10s,w
    sublw 4
    btfss STATUS,2
    goto check_10s_digit_is_3
    movlw FOUR
    movwf PORTC
    goto check_1s_digit_is_9

check_10s_digit_is_3:
    movf NUM_10s,w
    sublw 3
    btfss STATUS,2
    goto check_10s_digit_is_2
    movlw THREE
    movwf PORTC
    goto check_1s_digit_is_9
    
check_10s_digit_is_2:
    movf NUM_10s,w
    sublw 2
    btfss STATUS,2
    goto check_10s_digit_is_1
    movlw TWO
    movwf PORTC
    goto check_1s_digit_is_9
    
check_10s_digit_is_1:
    movf NUM_10s,w
    sublw 1
    btfss STATUS,2
    goto check_10s_digit_is_0
    movlw ONE
    movwf PORTC
    goto check_1s_digit_is_9
    
check_10s_digit_is_0:
    movf NUM_10s,w
    sublw 0
    btfss STATUS,2
    nop
    movlw ZER0
    movwf PORTC
    goto check_1s_digit_is_9

check_1s_digit_is_9:
    movf NUM_1s,w
    sublw 9
    btfss STATUS,2
    goto check_1s_digit_is_8
    movlw NINE
    movwf PORTA
    goto finished

check_1s_digit_is_8:
    movf NUM_1s,w
    sublw 8
    btfss STATUS,2
    goto check_1s_digit_is_7
    movlw EIGHT
    movwf PORTA
    goto finished

check_1s_digit_is_7:
    movf NUM_1s,w
    sublw 7
    btfss STATUS,2
    goto check_1s_digit_is_6
    movlw SEVEN
    movwf PORTA
    goto finished
    
check_1s_digit_is_6:
    movf NUM_1s,w
    sublw 6
    btfss STATUS,2
    goto check_1s_digit_is_5
    movlw SIX
    movwf PORTA
    goto finished
    
check_1s_digit_is_5:
    movf NUM_1s,w
    sublw 5
    btfss STATUS,2
    goto check_1s_digit_is_4
    movlw FIVE
    movwf PORTA
    goto finished
    
check_1s_digit_is_4:
    movf NUM_1s,w
    sublw 4
    btfss STATUS,2
    goto check_1s_digit_is_3
    movlw FOUR
    movwf PORTA
    goto finished

check_1s_digit_is_3:
    movf NUM_10s,w
    sublw 3
    btfss STATUS,2
    goto check_1s_digit_is_2
    movlw THREE
    movwf PORTA
    goto finished
    
check_1s_digit_is_2:
    movf NUM_1s,w
    sublw 2
    btfss STATUS,2
    goto check_1s_digit_is_1
    movlw TWO
    movwf PORTA
    goto finished
    
check_1s_digit_is_1:
    movf NUM_1s,w
    sublw 1
    btfss STATUS,2
    goto check_1s_digit_is_0
    movlw ONE
    movwf PORTA
    goto finished
    
check_1s_digit_is_0: ;in theory this step is not needed (if not any other value, it must be zero!)
    movf NUM_1s,w
    sublw 0
    btfss STATUS,2
    nop
    movlw ZER0
    movwf PORTA
    goto finished
    
finished:
    goto main

END
