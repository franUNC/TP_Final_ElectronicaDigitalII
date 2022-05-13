;*******************************************************************************
;                                                                              *
;    Filename: TRABAJOFINAL                                                    *
;    Date: 07/05/2022                                                          *
;    File Version: 2.0.0                                                       *
;    Author: Francisco Cabrera                                                 *
;    Company: FCEFyN                                                           *
;    Description: Decodificación de teclado y muestra de valores por display y *                                                   *
;                 comunicacion serie                                           *
;*******************************************************************************
	
	LIST	    P=16F887
	#include    <p16f887.inc>
	
    __CONFIG    _CONFIG1, _INTOSCIO & _WDT_OFF & _PWRTE_ON & _MCLRE_ON & _BOR_OFF
	
AUXC	EQU	0X20     ;Registro auxiliar para multiplexar los displays
AUXD	EQU	0X21	 ;Registro para decodificación de teclado
REG3	EQU	0X22	 ;Registro para guardar el valor que se muestra por el display 3
REG2	EQU	0X23	 ;Registro para guardar el valor que se muestra por el display 2
REG1	EQU	0X24	 ;Registro para guardar el valor que se muestra por el display 1
REG0	EQU	0X25	 ;Registro para guardar el valor que se muestra por el display 0
DATO	EQU	0X26	 ;Registro para almacenar el dato ingresado por el teclado
WTEMP	EQU	0X27	 ;Registro para guardar W cuando entra a la ISR
STEMP	EQU	0X28	 ;Registro para guardar STATUS cuando entra a la ISR
RTEMP	EQU	0X29	 ;Registro para almacenar temporalmente el valor a mostrar en el display
DEB0	EQU	0X2A     ;Registro auxiliar para realizar el DEBOUNCE	
DEB1	EQU	0X2B	 ;Registro auxiliar para realizar el DEBOUNCE
REG3A	EQU	0X2C	 ;Registro para enviar datos por TX
REG2A	EQU	0X2D	 ;Registro para enviar datos por TX
REG1A	EQU	0X2E	 ;Registro para enviar datos por TX
REG0A	EQU	0X2F	 ;Registro para enviar datos por TX
DATOA	EQU	0X30	 ;Registro auxiliar para actualizar registros REGxA

	ORG	    0X00
	GOTO	    MAIN
	
	ORG	    0X04

	MOVWF	    WTEMP  
	SWAPF	    STATUS,W
	MOVWF	    STEMP   ;Guarda el contexto del procesador
	
	BANKSEL	    INTCON
	BTFSC	    INTCON,INTF
	GOTO	    INTO
	
	BANKSEL	    STATUS
	BCF	    STATUS,C
	BTFSC	    AUXC,7
	BSF	    STATUS,C
	RLF	    AUXC,1
	MOVF	    AUXC,W
	MOVWF	    PORTC
	
	BTFSC	    AUXC,0
	GOTO	    SAVE3
	BTFSC	    AUXC,1
	GOTO	    SAVE2
	BTFSC	    AUXC,2
	GOTO	    SAVE1
	GOTO	    SAVE0
SAVE3	MOVF	    REG3,W
	GOTO	    NEXT2
SAVE2	MOVF	    REG2,W
	GOTO	    NEXT2
SAVE1	MOVF	    REG1,W
	GOTO	    NEXT2
SAVE0	MOVF	    REG0,W
NEXT2	MOVWF	    RTEMP
	MOVLW	    0X00
	MOVWF	    PORTC
	MOVF	    RTEMP,W
	MOVWF	    PORTA
	MOVF	    AUXC,W
	MOVWF	    PORTC
	
	BANKSEL	    INTCON
	BCF	    INTCON,2
	BANKSEL	    TMR0
	MOVLW	    .100
	MOVWF	    TMR0
	SWAPF	    STEMP,W
	MOVWF	    STATUS
	SWAPF	    WTEMP,1
	SWAPF	    WTEMP,W
	RETFIE
	
INTO	
	BCF	    PIR1,TXIF
	BANKSEL	    TXREG
	MOVF	    REG3A,W
	MOVWF	    TXREG
	BANKSEL	    TXSTA
	BTFSS	    TXSTA,TRMT
	GOTO	    $-1
	BANKSEL	    TXREG
	MOVF	    REG2A,W
	MOVWF	    TXREG
	BANKSEL	    TXSTA
	BTFSS	    TXSTA,TRMT
	GOTO	    $-1
	BANKSEL	    TXREG
	MOVF	    REG1A,W
	MOVWF	    TXREG
	BANKSEL	    TXSTA
	BTFSS	    TXSTA,TRMT
	GOTO	    $-1
	BANKSEL	    TXREG
	MOVF	    REG0A,W
	MOVWF	    TXREG
	BANKSEL	    TXSTA
	BTFSS	    TXSTA,TRMT
	GOTO	    $-1

	BANKSEL	    REG0
	MOVLW	    0X3F
	MOVWF	    REG0
	MOVWF	    REG1
	MOVWF	    REG2
	MOVWF	    REG3
	CLRF	    REG0A
	CLRF	    REG1A
	CLRF	    REG2A
	CLRF	    REG3A
	
	BANKSEL	    INTCON
	BCF	    INTCON,INTF
	BANKSEL	    STATUS
	SWAPF	    STEMP,W
	MOVWF	    STATUS
	SWAPF	    WTEMP,1
	SWAPF	    WTEMP,W
	RETFIE

	
MAIN
	BANKSEL	    ANSEL
	CLRF	    ANSEL
	CLRF	    ANSELH
	BANKSEL	    TRISA
	MOVLW	    0X01
	MOVWF	    TRISB
	CLRF	    TRISA 
	CLRF	    TRISC 
	MOVLW	    0XF0
	MOVWF	    TRISD 
	BANKSEL	    TXSTA
	MOVLW	    0X24
	MOVWF	    TXSTA
	BANKSEL	    RCSTA
	MOVLW	    0X80
	MOVWF	    RCSTA
	BANKSEL	    BAUDCTL
	BCF	    BAUDCTL,BRG16
	BANKSEL	    SPBRG
	MOVLW	    .25
	MOVWF	    SPBRG
	BANKSEL	    OPTION_REG
	MOVLW	    0X84  
	MOVWF	    OPTION_REG
	BANKSEL	    PIE1
	BSF	    PIE1,TXIE
	BANKSEL	    INTCON
	MOVLW	    0XB0
	MOVWF	    INTCON
	BANKSEL	    TMR0
	MOVLW	    .100
	MOVWF	    TMR0  
	MOVLW	    0X11  
	MOVWF	    AUXC  
	MOVWF	    PORTC
	MOVLW	    0X3F
	MOVWF	    REG0
	MOVWF	    REG1
	MOVWF	    REG2
	MOVWF	    REG3
	MOVWF	    PORTA
	CLRF	    REG3A
	CLRF	    REG2A
	CLRF	    REG1A
	CLRF	    REG0A
	

NEXT	MOVLW	    0XEE
	MOVWF	    AUXD  
	CLRF	    DATO
KEYB	MOVF	    AUXD,W
	MOVWF	    PORTD 
	BTFSS	    PORTD,4
	GOTO	    SAVE
	INCF	    DATO,1
	BTFSS	    PORTD,5
	GOTO	    SAVE
	INCF	    DATO,1
	BTFSS	    PORTD,6
	GOTO	    SAVE
	INCF	    DATO,1
	BTFSS	    PORTD,7
	GOTO	    SAVE
	INCF	    DATO,1
	
	BSF	    STATUS,C 
	BTFSS	    AUXD,7
	BCF	    STATUS,C
	RLF	    AUXD,1
	GOTO	    KEYB     
	
SAVE
	CALL	    DEBOUNCE
	MOVLW	    0X0F
	ANDWF	    DATO,1
	MOVF	    DATO,W
	MOVWF	    DATOA
	CALL	    DECOD
	MOVWF	    DATO
	CALL	    ORDER
	CALL	    RKEY
	GOTO	    NEXT

DEBOUNCE
	BANKSEL	    INTCON
	BCF	    INTCON,GIE
	BANKSEL	    DEB0
	MOVLW	    .255
	MOVWF	    DEB0
	MOVLW	    .12
	MOVWF	    DEB1
	
LOOP1	DECFSZ	    DEB1,1
	GOTO	    LOOP
	GOTO	    RET
LOOP	DECFSZ	    DEB0,1
	GOTO	    LOOP
	GOTO	    LOOP1
	
RET	
	BANKSEL	    INTCON
	BSF	    INTCON,GIE
	BANKSEL	    PORTD
	RETURN
	
DECOD
	MOVF	    DATO,W
	ADDWF	    PCL,1
	RETLW	    0X3F
	RETLW	    0X06
	RETLW	    0X5B
	RETLW	    0X4F
	RETLW	    0X66
	RETLW	    0X6D
	RETLW	    0X7D
	RETLW	    0X07
	RETLW	    0X7F
	RETLW	    0X67
	RETLW	    0X5F
	RETLW	    0X7C
	RETLW	    0X39
	RETLW	    0X5E
	RETLW	    0X7B
	RETLW	    0X71
	
ORDER 
	MOVF	    REG2,W
	MOVWF	    REG3
	MOVF	    REG1,W
	MOVWF	    REG2
	MOVF	    REG0,W
	MOVWF	    REG1
	MOVF	    DATO,W
	MOVWF	    REG0
	MOVF	    REG2A,W
	MOVWF	    REG3A
	MOVF	    REG1A,W
	MOVWF	    REG2A
	MOVF	    REG0A,W
	MOVWF	    REG1A
	MOVF	    DATOA,W
	MOVWF	    REG0A
	
	RETURN	
	
RKEY 
	BANKSEL	    INTCON
	BCF	    INTCON,GIE
	BANKSEL	    PORTD
	MOVLW	    0X00
	MOVWF	    PORTC
CHECK	MOVLW	    0XF0
	ANDWF	    PORTD,W
	SUBLW	    0XF0
	BTFSS	    STATUS,Z
	GOTO	    CHECK
	MOVF	    AUXC,W
	MOVWF	    PORTC
	BANKSEL	    INTCON
	BSF	    INTCON,GIE
	BANKSEL	    PORTD
	RETURN	

	END