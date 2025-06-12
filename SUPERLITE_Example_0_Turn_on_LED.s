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
    movlw 11111111	
    movwf TRISA		;configure all of PORTA as INPUT
    movlw 00000001
    movwf TRISB		;configure PORTB as OUTPUT, except PORTB,0 (which MUST be an input)
    bcf STATUS,5	;change RP0 to 0 to select BANK0

main:
    bsf PORTA,0
END
