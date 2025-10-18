PROCESSOR 16F88 ;tell the software which chip is used. Datasheet: https://docs.rs-online.com/a168/0900766b81382af8.pdf
   
CONFIG  FOSC = INTOSCIO       ; Oscillator Selection bits (INTRC oscillator; port I/O function on both RA6/OSC2/CLKO pin and RA7/OSC1/CLKI pin)
CONFIG  WDTE = OFF            ; Watchdog Timer Enable bit (WDT disabled)
CONFIG  PWRTE = OFF           ; Power-up Timer Enable bit (PWRT disabled)
CONFIG  MCLRE = OFF            ; RA5/MCLR/VPP Pin Function Select bit (RA5/MCLR/VPP pin function is Digital I/O)
CONFIG  BOREN = ON            ; Brown-out Reset Enable bit (BOR enabled)
CONFIG  LVP = ON              ; Low-Voltage Programming Enable bit (RB3/PGM pin has PGM function, Low-Voltage Programming enabled)
CONFIG  CPD = OFF             ; Data EE Memory Code Protection bit (Code protection off)
CONFIG  WRT = OFF             ; Flash Program Memory Write Enable bits (Write protection off)
CONFIG  CCPMX = RB0           ; CCP1 Pin Selection bit (CCP1 function on RB0)
CONFIG  CP = OFF              ; Flash Program Memory Code Protection bit (Code protection off)
CONFIG  FCMEN = ON            ; Fail-Safe Clock Monitor Enable bit (Fail-Safe Clock Monitor enabled)
CONFIG  IESO = ON             ; Internal External Switchover bit (Internal External Switchover mode enabled)
    
#include <xc.inc>

psect RES_VECT,class=CODE,delta=2 ; PIC10/12/16. The line "-PRES_VECT=0x00" must be present as a custom linker option in the project properties.
RES_VECT:
    bsf STATUS,5	;change RP0 (bit 5 of STATUS register) to 1 to select BANK1
    movlw 00100000	
    movwf TRISA		;configure PORTA,0 as INPUT, 1-7 OUTPUT
    movlw 00000000
    movwf TRISB		;configure PORTB as OUTPUT
    bcf STATUS,5	;change RP0 to 0 to select BANK0

COUNT EQU 0x40 ;define a pointer to the file register where the count is stored
COUNT_TEMP EQU 0x41 ;define a temporary location to use the value in COUNT for other purposes

NUM_10s	EQU 0x42 ;define a pointer to the file register for converting the count to BCD
NUM_1s	EQU 0x43

NINE	EQU 11001111B ;define the digits to display on PORTA or PORTB
EIGHT	EQU 11011111B
SEVEN	EQU 00000111B
SIX	EQU 11011101B
FIVE	EQU 11001101B
FOUR	EQU 11000110B
THREE	EQU 10001111B
TWO	EQU 10011011B
ONE	EQU 00000110B
ZER0	EQU 01011111B

clrf COUNT ;initially set the value in COUNT to zero.
clrf COUNT_TEMP

main:
    btfss PORTA,5   ;PORTA5 is the only INPUT on PORTA.
    goto main
    incf COUNT,1    ;increment the value in COUNT
    movf COUNT,0x00 ;copy COUNT to working register
    movwf COUNT_TEMP
dec_10_loop:
    movlw 10
    subwf COUNT_TEMP 
    btfss STATUS,0
    goto reset_value_10s
    incf NUM_10s 
    goto dec_10_loop 
reset_value_10s:
    movlw 10
    addwf COUNT_TEMP
units:
    movf COUNT_TEMP,0x00 
    movwf NUM_1s

check_10s_digit_is_9:
    movf NUM_10s,0x00
    sublw 9
    btfss STATUS,2
    goto check_10s_digit_is_8
    movlw NINE
    movwf PORTA
    goto check_1s_digit_is_9

check_10s_digit_is_8:
    movf NUM_10s, 0x00
    sublw 8
    btfss STATUS,2
    goto check_10s_digit_is_7
    movlw EIGHT
    movwf PORTA
    goto check_1s_digit_is_9

check_10s_digit_is_7:
    movf NUM_10s, 0x00
    sublw 7
    btfss STATUS,2
    goto check_10s_digit_is_6
    movlw SEVEN
    movwf PORTA
    goto check_1s_digit_is_9
    
check_10s_digit_is_6:
    movf NUM_10s, 0x00
    sublw 6
    btfss STATUS,2
    goto check_10s_digit_is_5
    movlw SIX
    movwf PORTA
    goto check_1s_digit_is_9
    
check_10s_digit_is_5:
    movf NUM_10s, 0x00
    sublw 5
    btfss STATUS,2
    goto check_10s_digit_is_4
    movlw FIVE
    movwf PORTA
    goto check_1s_digit_is_9
    
check_10s_digit_is_4:
    movf NUM_10s, 0x00
    sublw 4
    btfss STATUS,2
    goto check_10s_digit_is_3
    movlw FOUR
    movwf PORTA
    goto check_1s_digit_is_9

check_10s_digit_is_3:
    movf NUM_10s, 0x00
    sublw 3
    btfss STATUS,2
    goto check_10s_digit_is_2
    movlw THREE
    movwf PORTA
    goto check_1s_digit_is_9
    
check_10s_digit_is_2:
    movf NUM_10s, 0x00
    sublw 2
    btfss STATUS,2
    goto check_10s_digit_is_1
    movlw TWO
    movwf PORTA
    goto check_1s_digit_is_9
    
check_10s_digit_is_1:
    movf NUM_10s, 0x00
    sublw 1
    btfss STATUS,2
    goto check_10s_digit_is_0
    movlw ONE
    movwf PORTA
    goto check_1s_digit_is_9
    
check_10s_digit_is_0:
    movf NUM_10s, 0x00
    sublw 0
    btfss STATUS,2
    nop
    movlw ZER0
    movwf PORTA
    goto check_1s_digit_is_9

check_1s_digit_is_9:
    movf NUM_1s, 0x00
    sublw 9
    btfss STATUS,2
    goto check_1s_digit_is_8
    movlw NINE
    movwf PORTB
    goto finished

check_1s_digit_is_8:
    movf NUM_1s, 0x00
    sublw 8
    btfss STATUS,2
    goto check_1s_digit_is_7
    movlw EIGHT
    movwf PORTB
    goto finished

check_1s_digit_is_7:
    movf NUM_1s, 0x00
    sublw 7
    btfss STATUS,2
    goto check_1s_digit_is_6
    movlw SEVEN
    movwf PORTB
    goto finished
    
check_1s_digit_is_6:
    movf NUM_1s, 0x00
    sublw 6
    btfss STATUS,2
    goto check_1s_digit_is_5
    movlw SIX
    movwf PORTB
    goto finished
    
check_1s_digit_is_5:
    movf NUM_1s, 0x00
    sublw 5
    btfss STATUS,2
    goto check_1s_digit_is_4
    movlw FIVE
    movwf PORTB
    goto finished
    
check_1s_digit_is_4:
    movf NUM_1s, 0x00
    sublw 4
    btfss STATUS,2
    goto check_1s_digit_is_3
    movlw FOUR
    movwf PORTB
    goto finished

check_1s_digit_is_3:
    movf NUM_10s, 0x00
    sublw 3
    btfss STATUS,2
    goto check_1s_digit_is_2
    movlw THREE
    movwf PORTB
    goto finished
    
check_1s_digit_is_2:
    movf NUM_1s, 0x00
    sublw 2
    btfss STATUS,2
    goto check_1s_digit_is_1
    movlw TWO
    movwf PORTB
    goto finished
    
check_1s_digit_is_1:
    movf NUM_1s, 0x00
    sublw 1
    btfss STATUS,2
    goto check_1s_digit_is_0
    movlw ONE
    movwf PORTB
    goto finished
    
check_1s_digit_is_0:
    movf NUM_1s, 0x00
    sublw 0
    btfss STATUS,2
    nop
    movlw ZER0
    movwf PORTB
    goto finished
    
finished:
    goto main

END