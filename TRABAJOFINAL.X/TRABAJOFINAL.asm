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
REG3A	EQU	0X2C
REG2A	EQU	0X2D
REG1A	EQU	0X2E
REG0A	EQU	0X2F
DATOA	EQU	0X30

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
	CLRF	    TRISA ;PORTA salidas digitales para datos de los display
	CLRF	    TRISC ;PORTC salidas digitales para multiplexar displays (en uso PORTC <3-0>)
	MOVLW	    0XF0
	MOVWF	    TRISD ;PORTD <7-4> entradas digitales, PORTD <3-0> salidas digitales para teclado matricial
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
	MOVLW	    0X84  ;PS asignado al TMR0, PS 1:32
	MOVWF	    OPTION_REG
	BANKSEL	    PIE1
	BSF	    PIE1,TXIE
	BANKSEL	    INTCON
	MOVLW	    0XB0
	MOVWF	    INTCON;Habilita la interrupción por desborde de TMR0
	BANKSEL	    TMR0
	MOVLW	    .100
	MOVWF	    TMR0  ;Carga el TMR0 con un 100 para que desborde a los 5[ms]
	MOVLW	    0X11  
	MOVWF	    AUXC  ;Carga AUXC con b'11101110' para que al rotarlo siempre seleccione de a un display (por bajo)
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
	
;Rutina de teclado por polling
NEXT	MOVLW	    0XEE
	MOVWF	    AUXD  ;Carga AUXD con b'01110111' para que al rotarlo active solo una de las salidas bits <3-0> para decodificar el teclado
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
	
	BSF	    STATUS,C ;Rotación a la izquierda de AUXD sin carry
	BTFSS	    AUXD,7
	BCF	    STATUS,C
	RLF	    AUXD,1
	GOTO	    KEYB     ;Vuelve a hacer la rutina de teclado en un saltando de fila en la matriz
	
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
	MOVLW	    .8
	MOVWF	    DEB1
	
LOOP1	DECFSZ	    DEB1
	GOTO	    LOOP
	GOTO	    RET
LOOP	DECFSZ	    DEB0
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
	
ORDER ;Ordena los datos corriendolos de derecha a izquiera en los displays
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
	
RKEY ;Verifica si se soltó la tecla
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