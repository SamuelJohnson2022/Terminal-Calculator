***********************************************************************
*
* Title:          SCI Serial Port and 7-segment Display at PORTB
*
* Objective:      CMPEN 472 Homework 9, in-class-room demonstration
*                 program
*
* Revision:       V3.2  for CodeWarrior 5.2 Debugger Simulation
*
* Date:	          Mar. 29, 2020
*
* Programmer:     Samuel Johnson
*
* Company:        The Pennsylvania State University
*                 Department of Computer Science and Engineering
*
* Program:        Simple SCI Serial Port I/O and Demonstration
*                 Typewriter program and 7-Segment display, at PORTB
*                 
*
* Algorithm:      Simple Serial I/O use, typewriter
*
* Register use:	  A, B: Simple data transfer and manipulation
*                 X,Y: memory location actions
*
* Memory use:     RAM Locations from $3000 for data, 
*                 RAM Locations from $3100 for program
*
* Output:         
*                 Outputs to the terminal through sci port and 7 seg display
*
* Observation:    This is a simple calculator program that allows
*                 a user to perform add, subtract, multiply, and 
*                 divide operations on 3 digit numbers. Additionally, there
*                 is a timer running that counts from 59 - 0 and a typewriter
*                 if you quit the program.
*
***********************************************************************
* Parameter Declearation Section
*
* Export Symbols
            XDEF        pstart       ; export 'pstart' symbol
            ABSENTRY    pstart       ; for assembly entry point
  
* Symbols and Macros
PORTB       EQU         $0001        ; i/o port B addresses
DDRB        EQU         $0003

SCIBDH      EQU         $00C8        ; Serial port (SCI) Baud Register H
SCIBDL      EQU         $00C9        ; Serial port (SCI) Baud Register L
SCICR2      EQU         $00CB        ; Serial port (SCI) Control Register 2
SCISR1      EQU         $00CC        ; Serial port (SCI) Status Register 1
SCIDRL      EQU         $00CF        ; Serial port (SCI) Data Register

CRGFLG      EQU         $0037        ; Clock and Reset Generator Flags
CRGINT      EQU         $0038        ; Clock and Reset Generator Interrupts
RTICTL      EQU         $003B        ; Real Time Interrupt Control

CR          equ         $0d          ; carriage return, ASCII 'Return' key
LF          equ         $0a          ; line feed, ASCII 'next line' character

***********************************************************************
* Data Section: address used [ $3000 to $30FF ] RAM memory
*
            ORG         $3000        ; Reserved RAM memory starting address 
                                     ;   for Data for CMPEN 472 class

                                     ;   outer loop for sec
CCount      DS.B        1            ; Memory used to count the number of chars in buffer
ACount      DS.B        1            ; Memory used to count the number of nums in input numbers

Num1        DS.B        3            ; Memory used to store the ascii characters waiting to be converted
Num2        DS.B        3            ; Memory used to store the ascii characters waiting to be converted

Num1DEC     DS.W        1            ; Memory used to store the decimal value of num1
Num2DEC     DS.W        1            ; Memory used to store the decimal value of num2

DecimalVal  DS.B        3            ; Memory used to store the working address in DoCommand

Buff        DS.B        12           ; Memory used to store inputted text
writingData DS.B        1            ; used to store data that's going to be written 
TempMem     DC.B        5            ; Reserved for use in do command
finalVal    DC.W        1            ; Reserved for storing the final hex value   

ctr2p5m     DS.W        1                 ; interrupt counter for 2.5 mSec. of time
TimerVal    DS.B        1            ; Memory used to count the current timer value in ascii                                
                               
*
***********************************************************************

;*******************************************************
; interrupt vector section
            ORG    $FFF0             ; RTI interrupt vector setup for the simulator
;            ORG    $3FF0             ; RTI interrupt vector setup for the CSM-12C128 board
            DC.W   rtiisr

;*******************************************************

* Program Section: address used [ $3100 to $3FFF ] RAM memory
*
            ORG        $3100        ; Program start address, in RAM
pstart      LDS        #$3100       ; initialize the stack pointer

            LDAA       #%11111111   ; Set PORTB bit 0,1,2,3,4,5,6,7
            STAA       DDRB         ; as output

            LDAA       #%00000000
            STAA       PORTB        ; clear all bits of PORTB

            ldaa       #$0C         ; Enable SCI port Tx and Rx units
            staa       SCICR2       ; disable SCI interrupts

            ldd        #$0001       ; Set SCI Baud Register = $0001 => 2M baud at 24MHz (for simulation)
;            ldd        #$0002       ; Set SCI Baud Register = $0002 => 1M baud at 24MHz
;            ldd        #$000D       ; Set SCI Baud Register = $000D => 115200 baud at 24MHz
;            ldd        #$009C       ; Set SCI Baud Register = $009C => 9600 baud at 24MHz
            std        SCIBDH       ; SCI port baud rate change
            
            ldx   #msg2              ; print the instruction message
            jsr   printmsg
            
            ldaa  #CR                ; move the cursor to beginning of the line
            jsr   putchar            ;   Cariage Return/Enter key
            ldaa  #LF                ; move the cursor to next line, Line Feed
            jsr   putchar            
            
            ldx   #msg15              ; print the instruction message
            jsr   printmsg
            
            ldaa  #CR                ; move the cursor to beginning of the line
            jsr   putchar            ;   Cariage Return/Enter key
            ldaa  #LF                ; move the cursor to next line, Line Feed
            jsr   putchar            
            
            bset   RTICTL,%00011001 ; set RTI: dev=10*(2**10)=2.555msec for C128 board
                                    ;      4MHz quartz oscillator clock
            bset   CRGINT,%10000000 ; enable RTI interrupt
            bset   CRGFLG,%10000000 ; clear RTI IF (Interrupt Flag)
            
            ldx    #0
            stx    ctr2p5m          ; initialize interrupt counter with 0.
            cli                     ; enable interrupt, global
            ldaa   #$59
            staa   TimerVal
            staa   PORTB
            
mainLoop    
            LDX   #Buff              ; Put the address of Buff into X
            CLR   Buff               ; Clear the buffer
            CLR   1, X               ; Clear the buffer
            CLR   2, X               ; Clear the buffer
            CLR   3, X               ; Clear the buffer
            CLR   4, X               ; Clear the buffer
            CLR   5, X               ; Clear the buffer
            CLR   6, X               ; Clear the buffer
            CLR   7, X               ; Clear the buffer
            CLR   8, X               ; Clear the buffer
            CLR   9, X               ; Clear the buffer
            CLR   10, X              ; Clear the buffer
            CLR   11, X              ; Clear the buffer
            CLR   CCount             ; Clear the C count 
            LDY   #TempMem           ; Put the address of Buff into Y
            CLR   Y                  ; Clear the temporary memory
            CLR   1, Y               ; Clear the temporary memory
            CLR   2, Y               ; Clear the temporary memory       
            
            ldx   #msg9               ; Print out prompt character Ecalc>
            jsr   printmsg 
            LDX   #Buff              ; reload buff into x
            
checkLoop   
            ldaa  CCount
            jsr   LEDtoggle          ; Check if we need to change the timer
            cmpa  #12                 ; If the buffer reaches 12, we send an error and reset
                                     ;  Since the max length of a command is 11 + 1 (enter)
            bne   postError1         ; Reset the buffer and associated variables
            
            ldaa  #LF                ; cursor to next line
            jsr   putchar
errorReuse  ldx   #msg14             ; print the error message
            jsr   printmsg
            
            ldaa  #CR                ; move the cursor to beginning of the line
            jsr   putchar            ;   Cariage Return/Enter key
            ldaa  #LF                ; move the cursor to next line, Line Feed
            jsr   putchar
            bra   mainLoop           ; Return to the start
            
           
postError1                       
            jsr   getchar            ; type writer - check the key board
            cmpa  #$00               ;  if nothing typed, keep checking
            beq   checkLoop
            
            jsr   putchar            ; is displayed on the terminal window - echo print
            
            STAA  1,X+               ; Otherwise, save in buffer and increment X to next Byte in buffer
            INC   CCount             ; Increment the buffer counter
            
            cmpa  #$0D               ; Check if its an enter
            bne   checkLoop          ; Go back to checking for characters if not
            ldaa  #LF                ; cursor to next line
            jsr   putchar
            
            jsr   doCommand          ; Call the do command subroutine
            ldaa  #CR                ; move the cursor to beginning of the line
            jsr   putchar            ;   Cariage Return/Enter key
            ldaa  #LF                ; move the cursor to next line, Line Feed
            jsr   putchar
            
            cmpb  #1                 ; Check if the quit command was called
            beq   Typewriter         ; Jump to typewriter mode
            cmpb  #2                 ; Check if the command was invalid
            beq   fourError
            cmpb  #3                 ; Check if it was a address error
            beq   overflowError
            cmpb  #4                 ; Check if it was a data error
            beq   dtError
            cmpb  #5                 ; Check if it was a divide by zero error
            beq   zeroError
            cmpb  #6                 ; Check if it was a divide by zero error
            beq   timeError
            
postError2
            lbra   mainLoop           ; Otherwise, reset the buffers and keep checking for commands
                            
overflowError            
            ldx   #msg7              ; print the error message
            jsr   printmsg
            
            ldaa  #CR                ; move the cursor to beginning of the line
            jsr   putchar            ;   Cariage Return/Enter key
            ldaa  #LF                ; move the cursor to next line, Line Feed
            jsr   putchar
            lbra  mainLoop
fourError            
            ldx   #msg10              ; print the error message
            jsr   printmsg
            
            ldaa  #CR                ; move the cursor to beginning of the line
            jsr   putchar            ;   Cariage Return/Enter key
            ldaa  #LF                ; move the cursor to next line, Line Feed
            jsr   putchar
            lbra  mainLoop            
dtError
            ldx   #msg8              ; print the error message
            jsr   printmsg
            
            ldaa  #CR                ; move the cursor to beginning of the line
            jsr   putchar            ;   Cariage Return/Enter key
            ldaa  #LF                ; move the cursor to next line, Line Feed
            jsr   putchar
            lbra  mainLoop
zeroError
            ldx   #msg11              ; print the error message
            jsr   printmsg
            
            ldaa  #CR                ; move the cursor to beginning of the line
            jsr   putchar            ;   Cariage Return/Enter key
            ldaa  #LF                ; move the cursor to next line, Line Feed
            jsr   putchar
            lbra  mainLoop
timeError
            ldx   #msg16              ; print the error message
            jsr   printmsg
            
            ldaa  #CR                ; move the cursor to beginning of the line
            jsr   putchar            ;   Cariage Return/Enter key
            ldaa  #LF                ; move the cursor to next line, Line Feed
            jsr   putchar
            lbra  mainLoop            
            
Typewriter  ldx   #msg1              ; print the first message, 'Hello'
            jsr   printmsg
            
            jsr   nextline

            ldx   #msg17              ; print the second message
            jsr   printmsg

            jsr   nextline

looop       jsr   getchar            ; type writer - check the key board
            cmpa  #$00               ;  if nothing typed, keep checking
            beq   looop
                                       ;  otherwise - what is typed on key board
            jsr   putchar            ; is displayed on the terminal window - echo print

            staa  PORTB              ; show the character on PORTB

            cmpa  #CR
            bne   looop              ; if Enter/Return key is pressed, move the
            ldaa  #LF                ; cursor to next line
            jsr   putchar
            bra   looop

;subroutine section below

;***********RTI interrupt service routine***************
rtiisr      bset   CRGFLG,%10000000 ; clear RTI Interrupt Flag - for the next one
            ldx    ctr2p5m          ; every time the RTI occur, increase
            inx                     ;    the 16bit interrupt count
            stx    ctr2p5m
rtidone     RTI
;***********end of RTI interrupt service routine********

;****************nextline**********************
nextline    psha
            ldaa  #CR              ; move the cursor to beginning of the line
            jsr   putchar          ;   Cariage Return/Enter key
            ldaa  #LF              ; move the cursor to next line, Line Feed
            jsr   putchar
            pula
            rts
;****************end of nextline***************

;***************LEDtoggle**********************
;* Program: toggle LED if 0.5 second is up
;* Input:   ctr2p5m variable
;* Output:  ctr2p5m variable and LED1
;* Registers modified: CCR
;* Algorithm:
;    Check for 0.5 second passed
;      if not 0.5 second yet, just pass
;      if 0.5 second has reached, then toggle LED and reset ctr2p5m
;**********************************************
LEDtoggle   psha
            pshx

            ldx    ctr2p5m          ; check for 0.5 sec
;            cpx    #200             ; 2.5msec * 200 = 0.5 sec
            cpx    #40             ; 2.5msec * 200 = 0.5 sec
            blo    doneLED          ; NOT yet

            ldx    #0               ; 0.5sec is up,
            ldaa   TimerVal
            deca 
            cmpa   #$FF             ; if it went negative, we set to 59
            bne    LEDPass1
            ldaa   #$59
            inca
            staa   TimerVal
            bra    LEDPass2
LEDPass1
            anda   #$0F             ; check if the second value is F
            cmpa   #10
            blo    LEDPass2         ; If its not a decimal  
            ldaa   TimerVal
            deca
            anda   #$F0
            adda   #$09             ; otherwise set it to 9  
            inca
            staa   TimerVal         
            
                                   
            
LEDPass2    
            ldaa   TimerVal
            deca         
            staa   TimerVal         ; Decrease the timer value every time
            
            stx    ctr2p5m          ;     clear counter to restart


            LDAA   TimerVal
            STAA   PORTB

doneLED     pulx
            pula
            rts
;***************end of LEDtoggle***************

;***********printmsg***************************
;* Program: Output character string to SCI port, print message
;* Input:   Register X points to ASCII characters in memory
;* Output:  message printed on the terminal connected to SCI port
;* 
;* Registers modified: CCR
;* Algorithm:
;     Pick up 1 byte from memory where X register is pointing
;     Send it out to SCI port
;     Update X register to point to the next byte
;     Repeat until the byte data $00 is encountered
;       (String is terminated with NULL=$00)
;**********************************************
NULL           equ     $00
printmsg       psha                   ;Save registers
               pshx
printmsgloop   ldaa    1,X+           ;pick up an ASCII character from string
                                      ;   pointed by X register
                                      ;then update the X register to point to
                                      ;   the next byte
               cmpa    #NULL
               beq     printmsgdone   ;end of strint yet?
               jsr     putchar        ;if not, print character and do next
               bra     printmsgloop

printmsgdone   pulx 
               pula
               rts
;***********end of printmsg********************


;***************putchar************************
;* Program: Send one character to SCI port, terminal
;* Input:   Accumulator A contains an ASCII character, 8bit
;* Output:  Send one character to SCI port, terminal
;* Registers modified: CCR
;* Algorithm:
;    Wait for transmit buffer become empty
;      Transmit buffer empty is indicated by TDRE bit
;      TDRE = 1 : empty - Transmit Data Register Empty, ready to transmit
;      TDRE = 0 : not empty, transmission in progress
;**********************************************
putchar        brclr SCISR1,#%10000000,putchar   ; wait for transmit buffer empty
               staa  SCIDRL                      ; send a character
               rts
;***************end of putchar*****************


;****************getchar***********************
;* Program: Input one character from SCI port (terminal/keyboard)
;*             if a character is received, other wise return NULL
;* Input:   none    
;* Output:  Accumulator A containing the received ASCII character
;*          if a character is received.
;*          Otherwise Accumulator A will contain a NULL character, $00.
;* Registers modified: CCR
;* Algorithm:
;    Check for receive buffer become full
;      Receive buffer full is indicated by RDRF bit
;      RDRF = 1 : full - Receive Data Register Full, 1 byte received
;      RDRF = 0 : not full, 0 byte received
;**********************************************
getchar        brclr SCISR1,#%00100000,getchar7
               ldaa  SCIDRL
               rts
getchar7       clra
               rts
;****************end of getchar**************** 

;****************isHex************************
;* Program: Check if an ascii character is a valid hex value
;* Input:   Ascii Character in register A    
;* Output:  Accumulator B containing the 0 for valid, 1 for not
;*          
;*          
;* Registers modified: B
;* Algorithm:
;    Check if it falls within the correct range of ascii values
;**********************************************
isHex
                cmpa    #$46                  ; Check if the value is outside the upper bound of ascii codes
                bhi     invalid
                cmpa    #$40                  ; Check if the value is A - F
                bhi     valid
                cmpa    #$39
                bhi     invalid               ; Check if the input is a random character
                cmpa    #$29
                bhi     valid                 ; Check if the input is 0 - 9
                
invalid                                       ; If its not within this range, its invalid
                ldab    #1                    ; Load register B with 1 to indicate not valid
                rts
                
valid           
                ldab    #0                    ; Load register B with 0 to indicate valid
                rts
                
;****************end of isHex***************** 

;****************isDeci************************
;* Program: Check if an ascii character is a valid hex value
;* Input:   Ascii Character in register A    
;* Output:  Accumulator B containing the 0 for valid, 1 for not
;*          
;*          
;* Registers modified: B
;* Algorithm:
;    Check if it falls within the correct range of ascii values
;**********************************************
isDeci
                cmpa    #$39
                bhi     invalidD               ; Check if the input is outside the upper boundary
                cmpa    #$2F
                bhi     validD                 ; Check if the input is 0 - 9
                
invalidD                                       ; If its not within this range, its invalid
                ldab    #1                    ; Load register B with 1 to indicate not valid
                rts
                
validD           
                ldab    #0                    ; Load register B with 0 to indicate valid
                rts
                
;****************end of isDeci***************** 

;****************toHex************************
;* Program: Converts an Ascii character to its hex equivalent
;* Input:   ascii value in register A
;* Output:  new hex value in register A
;*          
;*          
;* Registers modified: A
;* Algorithm:
;    converts by subtracting values according to ascii table
;**********************************************
toHex
                cmpa     #$39                  ; check if its a letter or number
                bhi      thAlpha               ;branch to other translation if is letter
                suba     #$30                  ; If its a number, we subtract $30
                rts                            ; then we are done and return
thAlpha                
                suba     #$37                  ; Otherwise, we subtract 37 to get the equivalent
                rts                            ; Return from subroutine
                
;****************end of toHex*****************

;****************toAscii************************
;* Program: Converts an hex character to its ascii equivalent
;* Input:   hex value in register A
;* Output:  new ascii value in register A
;*          
;*          
;* Registers modified: A
;* Algorithm:
;    converts by subtracting values according to ascii table
;**********************************************
toAscii
                cmpa     #9                    ; check if its a letter or number
                bhi      taAlpha               ;branch to other translation if is letter
                adda     #$30                  ; If its a number, we subtract $30
                rts                            ; then we are done and return
taAlpha                
                adda     #$37                  ; Otherwise, we subtract 37 to get the equivalent
                rts                            ; Return from subroutine
                
;****************end of toAscii*****************

;****************toDeci************************
;* Program: Converts ascii values in tempMem to decimal and puts it into writingData
;* Input:   Num1 or Num2 address in reg y
;* Output:  changed Num1DEC and Num2DEC
;*          
;*          
;* Registers modified: A
;* Algorithm:
;    converts to decimal numbers then find the correct hex representation
;**********************************************
toDeci

                psha
                pshb
                pshx
                
                cpy       #Num1                ; Compare the input address to num1
                beq       Num1Deci             ; If they are the same, branch to num1 section
                
                
                ldx       #Num2DEC             ; Load the address of num1DEC into x
                ldaa      Y                    ; Load the 100s place
                jsr       toHex                ; convert to hex (works for 0-9 anyway)
                ldab      #100
                mul                            ; A x B -> D
                std       X                    ; Store D into num1DEC
                iny
                
                ldaa      Y                    ; Load the 10s place
                jsr       toHex                ; convert to hex (works for 0-9 anyway)
                ldab      #10
                mul                            ; A x B -> D
                ldx       Num2DEC              ; Now load the value of Num1DEC to X
                abx                            ; B + X -> X
                iny
                
                ldaa      Y                    ; Load the 1s place
                jsr       toHex                ; convert to hex (works for 0-9 anyway)
                staa      TempMem
                ldab      TempMem              ; get the value in a into b
                abx                            ; Add that value to X
      
                stx       Num2DEC              ; Store the new converted value into Num1DEC
                
                pulx
                pulb
                pula
                rts
Num1Deci               
                ldx       #Num1DEC             ; Load the address of num1DEC into x
                ldaa      Y                    ; Load the 100s place
                jsr       toHex                ; convert to hex (works for 0-9 anyway)
                ldab      #100
                mul                            ; A x B -> D
                std       X                    ; Store D into num1DEC
                iny
                
                ldaa      Y                    ; Load the 10s place
                jsr       toHex                ; convert to hex (works for 0-9 anyway)
                ldab      #10
                mul                            ; A x B -> D
                ldx       Num1DEC              ; Now load the value of Num1DEC to X
                abx                            ; B + X -> X
                iny
                
                ldaa      Y                    ; Load the 1s place
                jsr       toHex                ; convert to hex (works for 0-9 anyway)
                staa      TempMem
                ldab      TempMem              ; get the value in a into b
                abx                            ; Add that value to X
      
                stx       Num1DEC              ; Store the new converted value into Num1DEC
                
                pulx
                pulb
                pula
                rts
                
;****************end of toDeci*****************

;****************addPadding************************
;* Program: Converts a number less than 3 digits to 3 digits
;* Input:   ACount and the address of Num1 or Num2 in Y
;* Output:  changed writingData
;*          
;*          
;* Registers modified: B
;* Algorithm:
;    converts to decimal numbers then find the correct hex representation
;**********************************************
addPadding
               psha
               
               ldab     ACount                ; if at the end it was less than 3 digits, we need to fill in 0s
               cmpb     #3
               beq      returnP
               
               ldaa     1, Y                  ; load the second caharcter into a
               staa     2, Y                  ; move it to the third spot
               ldaa     Y                      ;load the first character into a
               staa     1, Y                  ; move it to the second slot
               ldaa     #$30
               staa     Y                     ; put a zero in the space of old 
               
               cmpb     #2 
               beq      returnP
               ldaa     1, Y                  ; load the second caharcter into a
               staa     2, Y                  ; move it to the third spot
               ldaa     Y                      ;load the first character into a
               staa     1, Y                  ; move it to the second slot
               ldaa     #$30
               staa     Y                     ; put a zero in the space of old
returnP
               pula
               rts                            ; return from subroutine
               
;****************end of addPadding*****************

;****************printAns************************
;* Program: Converts a hex number to decimal ascii
;* Input:   number stored in memory
;* Output:  prints to terminal
;*          
;*          
;* Registers modified: 
;* Algorithm:
;    converts to decimal numbers then find the correct hex representation
;**********************************************
printAns

               ldd      finalVal              ; Get a 16 bit version of the number into D
               ldx      #$0A                  ; Load 10 into x
               ldy      #TempMem              ; Load the memory location of decimal val into y
               
               idiv                           ; D/X with remainder in B (this is last bit)
               stab     1, Y+                 ; Store the remainder into temp mem
               tfr      X, D                  ; Put whats left into D
               ldx      #$0A                  ; Load 10 into x
               
               idiv                           ; D/X with remainder in B (this is last bit)
               stab     1, Y+                 ; Store the remainder into temp mem
               tfr      X, D                  ; Put whats left into D
               ldx      #$0A                  ; Load 10 into x
               
               idiv                           ; D/X with remainder in B (this is last bit)
               stab     1, Y+                 ; Store the remainder into temp mem
               tfr      X, D                  ; Put whats left into D
               ldx      #$0A                  ; Load 10 into x
               
               idiv                           ; D/X with remainder in B (this is last bit)
               stab     1, Y+                 ; Store the remainder into temp mem
               tfr      X, D                  ; Put whats left into D
               ldx      #$0A                  ; Load 10 into x
               
               idiv                           ; D/X with remainder in B (this is last bit)
               stab     Y                     ; Store the remainder into temp mem
               tfr      X, D                  ; Put whats left into D
               ldx      #$0A                  ; Load 10 into x
               
               ; Now we go back and print in reverse order
               
               ldaa     #$30
               adda     1, Y-                 ; convert each character into ascii
               cmpa     #$30
               beq      print2
               ldab     #1                    ; load b with 1 to indicate a non leading 0
               jsr      putchar
print2               
               ldaa     #$30
               adda     1, Y-                 ; convert each character into ascii
               cmpb     #1
               beq      skip2                 ; If there is a non 0 leading number, we prints 0s
               cmpa     #$30
               beq      print3
               ldab     #1                    ; load b with 1 to indicate a non leading 0
skip2          jsr      putchar
print3               
               ldaa     #$30
               adda     1, Y-                 ; convert each character into ascii
               cmpb     #1
               beq      skip3                 ; If there is a non 0 leading number, we prints 0s
               cmpa     #$30
               beq      print4
               ldab     #1                    ; load b with 1 to indicate a non leading 0
skip3          jsr      putchar
print4               
               ldaa     #$30
               adda     1, Y-                 ; convert each character into ascii
               cmpb     #1
               beq      skip4                 ; If there is a non 0 leading number, we prints 0s
               cmpa     #$30
               beq      print5
               ldab     #1                    ; load b with 1 to indicate a non leading 0
skip4          jsr      putchar
print5               
               ldaa     #$30
               adda     1, Y-                 ; convert each character into ascii
               jsr      putchar
                   
               rts

;****************end of printAns*****************

;****************doCommand*********************
;* Program: characters in the buffer
;*             
;* Input:   Buffer    
;* Output:  Executes a subroutine corresponding to the command
;*          Register B will have a value of 1 if quit was called, 2 if command error, 3 if address error, 4 if data error
;*          
;* Registers modified: B
;* Algorithm:
;    Check the buffer and turn on LEDs OR quit
;    This Subroutine checks each of the bits in the buffer and performs
;    A command accordingly
;      
;**********************************************
doCommand      
               psha                           ; Save a  
               pshx                           ; save x
               clr      ACount                ; Clear the counter register for addressing
               
               ldx   #msg5                    ; print the error message
               jsr   printmsg
                
               ldx      #Buff                 ; Load X with the address of Buff
               ldy      #Num1                 ; load the address of converter into Y
               ldaa     1,X+                  ; Load the first character into A, and increment
               cmpa     #$71                  ; Check if the character is an a
               lbeq     quit
               cmpa     #$73                  ; Check if the character is an s
               lbeq      seconds
               
               
               jsr      putchar               ; Print out the characters as we go
num1Loop               
               jsr      isDeci                ; Check if its a valid decimal number
               cmpb     #1                    ; check if its invalid (reg b == 1)
               lbeq     dataError             ; Give a data error if its not
               inc      ACount                ; Increment address counter
               ldab     ACount
               staa     1, Y+                 ; store into tempMem and increment
               cmpb     #4                    ; Max size of a decimal number is 3 digits (256)
               lbeq     commandError             ; If the number would be 4 digits, it's incorrect
               ldaa     1,X+                  ; Load the 3rd character into A, and increment
               jsr      putchar               ; Print out the characters as we go
               cmpa     #$2B                  ; See if the next character is +              
               lbeq     add                   ; if not, Loop back up 
               cmpa     #$2D                  ; See if the next character is -              
               lbeq     sub                   ; if not, Loop back up 
               cmpa     #$2A                  ; See if the next character is *              
               lbeq     mult                  ; if not, Loop back up 
               cmpa     #$2F                  ; See if the next character is /              
               lbeq     divi                  ; if not, Loop back up 
               bra      num1Loop              ; If its none of these, loop back to the top
               
commandError               
               ldab     #2                    ; IF it is none of these, its invalid and we set b to 2 and return
               pulx                           ; Restore x
               pula                           ; Restore a
               rts
ovrError               
               ldab     #3                    ; IF it is none of these, its invalid and we set b to 3 and return
               pulx                           ; Restore x
               pula                           ; Restore a
               rts
dataError               
               ldab     #4                    ; IF it is none of these, its invalid and we set b to 4 and return
               pulx                           ; Restore x
               pula                           ; Restore a
               rts   
divZeroError
               ldab     #5                    ; IF it is none of these, its invalid and we set b to 5 and return
               pulx                           ; Restore x
               pula                           ; Restore a
               rts 

timeFError
               ldab     #6                    ; IF it is none of these, its invalid and we set b to 5 and return
               pulx                           ; Restore x
               pula                           ; Restore a
               rts                

add
               ldy      #Num1
               jsr      addPadding            ; add 0s if the number is less than 3 digits
               ldy      #Num2                 ; Load the address of Num2 into Y
               clr      ACount                ; Clear the counter register for counting
               ldaa     1,X+                  ; start loading the next num           
addLoop        
               jsr      putchar               ; Print out the characters as we go 
               jsr      isDeci                ; Check if its a valid decimal number
               cmpb     #1                    ; check if its invalid (reg b == 1)
               lbeq     dataError             ; Give a data error if its not
               inc      ACount                ; Increment address counter
               ldab     ACount
               cmpb     #4                    ; Max size of a decimal number is 3 digits (256)
               lbeq     commandError             ; If the number would be 4 digits, it's incorrect
               staa     1, Y+                 ; store into tempMem and increment
               ldaa     1,X+                  ; Load the 3rd character into A, and increment
               cmpa     #$0D                  ; See if the next character is the enter 
               bne      addLoop             ; if not, Loop back up
               
               ldy      #Num2                 ; Now we pad the second number
               jsr      addPadding            ; add 0s if the number is less than 3 digits
               jsr      toDeci                ; Covert num1 and num2 to decimal form, using toDeci
               ldy      #Num1
               jsr      toDeci
               
               ldy      #Num1DEC
               ldx      #Num2DEC
               
               ldaa     1, Y                  ; get the lower bits of num1
               ldab     1, X                  ; get the lower bits of num2
               
               aba                            ; adds b and A together
               staa     TempMem
               
               ldaa     Y                     ; get the upper bits of num1

               adca     X                     ; add the upper bits together plus the carry
             
               ldab     TempMem               ; Get the upper bits back
               std      finalVal              ; Store D as the final answer
               ldaa     #$3D                  ; Print out the equal sign
               jsr      putchar
               jsr      printAns      
               
               lbra     cmdEnd                ; Branch to the end of DoCommand
sub
               ldy      #Num1
               jsr      addPadding            ; add 0s if the number is less than 3 digits
               ldy      #Num2                 ; Load the address of Num2 into Y
               clr      ACount                ; Clear the counter register for counting
               ldaa     1,X+                  ; start loading the next num           
subLoop        
               jsr      putchar               ; Print out the characters as we go 
               jsr      isDeci                ; Check if its a valid decimal number
               cmpb     #1                    ; check if its invalid (reg b == 1)
               lbeq     dataError             ; Give a data error if its not
               inc      ACount                ; Increment address counter
               ldab     ACount
               cmpb     #4                    ; Max size of a decimal number is 3 digits (256)
               lbeq     commandError             ; If the number would be 4 digits, it's incorrect
               staa     1, Y+                 ; store into tempMem and increment
               ldaa     1,X+                  ; Load the 3rd character into A, and increment
               cmpa     #$0D                  ; See if the next character is the enter 
               bne      subLoop               ; if not, Loop back up
               
               ldy      #Num2                 ; Now we pad the second number
               jsr      addPadding            ; add 0s if the number is less than 3 digits
               jsr      toDeci                ; Covert num1 and num2 to decimal form, using toDeci
               ldy      #Num1
               jsr      toDeci
               
               ldd      Num1DEC
               subd     Num2DEC
               std      finalVal
               
               cpd      #1000                  ; see if its bigger than 999 and therefore negative
               blo      subFin                ; Otherwise we print out a negative sign and convert from 2s complement
               
               ldaa     #$3D                  ; Print out the equal sign      
               jsr      putchar 
               ldaa     #$2D                  ; Print out the -     
               jsr      putchar 

               ldx      #finalVal
               ldaa     X                     ; load the upper bits into A
               nega 
               deca                           ; Find the 2s complement
               staa     X                     ; store back the upper bits
               ldaa     1, X
               nega                           ; negate the lower bits now
               staa     1, X
               
               jsr      printAns              ; Print out the answer
               lbra     cmdEnd                ; Branch to the end of DoCommand              
subFin         
               ldaa     #$3D                  ; Print out the equal sign      
               jsr      putchar 
               jsr      printAns              ; Print out the answer
               lbra     cmdEnd                ; Branch to the end of DoCommand
mult
               ldy      #Num1
               jsr      addPadding            ; add 0s if the number is less than 3 digits
               ldy      #Num2                 ; Load the address of Num2 into Y
               clr      ACount                ; Clear the counter register for counting
               ldaa     1,X+                  ; start loading the next num           
multLoop        
               jsr      putchar               ; Print out the characters as we go
               jsr      isDeci                ; Check if its a valid decimal number
               cmpb     #1                    ; check if its invalid (reg b == 1)
               lbeq     dataError             ; Give a data error if its not
               inc      ACount                ; Increment address counter
               ldab     ACount
               cmpb     #4                    ; Max size of a decimal number is 3 digits (256)
               lbeq     commandError             ; If the number would be 4 digits, it's incorrect
               staa     1, Y+                 ; store into tempMem and increment
               ldaa     1,X+                  ; Load the 3rd character into A, and increment
               cmpa     #$0D                  ; See if the next character is the enter 
               bne      multLoop             ; if not, Loop back up
               
               ldy      #Num2                 ; Now we pad the second number
               jsr      addPadding            ; add 0s if the number is less than 3 digits
               jsr      toDeci                ; Covert num1 and num2 to decimal form, using toDeci
               ldy      #Num1
               jsr      toDeci
               
               ldd      Num1DEC
               ldy      Num2DEC               ; Load the decimal values of each number into D and X
               emul                           ; D = D*Y
               cpy      #0                    ; Y must be 0 or else there's overflow
               lbne     ovrError
               std      finalVal              ; Store D as the final answer
               ldaa     #$3D                  ; Print out the equal sign
               jsr      putchar
               jsr      printAns      
               
               lbra     cmdEnd                ; Branch to the end of DoCommand
divi
               ldy      #Num1
               jsr      addPadding            ; add 0s if the number is less than 3 digits
               ldy      #Num2                 ; Load the address of Num2 into Y
               clr      ACount                ; Clear the counter register for counting
               ldaa     1,X+                  ; start loading the next num           
diviLoop               
               jsr      putchar               ; Print out the characters as we go
               jsr      isDeci                ; Check if its a valid decimal number
               cmpb     #1                    ; check if its invalid (reg b == 1)
               lbeq     dataError             ; Give a data error if its not
               inc      ACount                ; Increment address counter
               ldab     ACount
               cmpb     #4                    ; Max size of a decimal number is 3 digits (256)
               lbeq     commandError             ; If the number would be 4 digits, it's incorrect
               staa     1, Y+                 ; store into tempMem and increment
               ldaa     1,X+                  ; Load the 3rd character into A, and increment
               cmpa     #$0D                  ; See if the next character is the enter 
               bne      diviLoop              ; if not, Loop back up
               
               ldy      #Num2                 ; Now we pad the second number
               jsr      addPadding            ; add 0s if the number is less than 3 digits        
               jsr      toDeci                ; Convert num2 to a 2byte decimal number
               ldy      #Num1
               jsr      toDeci                ; Convert num1 to a 2byte decimal number
                     
               ldd      Num1DEC
               ldx      Num2DEC               ; Load the decimal values of each number into D and X
               cpx      #0                    ; check for divide by 0 error
               lbeq      divZeroError
               idiv                           ; x = D/X
               stx      finalVal
               ldaa     #$3D                  ; Print out the equal sign
               jsr      putchar
               jsr      printAns      
                     
               lbra     cmdEnd                ; Branch to the end of DoCommand

cmdEnd               
               ldab     #0                    ; Load b with 0 to indicate no error
               pulx                           ; Restore x
               pula                           ; Restore a     
               rts
               
seconds
               ldaa     1,X+                  ; Load the 2nd character into A, and increment
               cmpa     #$20                  ; check for a space
               lbne      dataError
               
               ldaa     1,X+                  ; Load the 2nd character into A, and increment
               jsr      isDeci                  
               cmpb     #0                    ; check if its 0-9
               lbne     timeFError
               ldy      #TempMem                               
               staa     Y                     ; Store it in temporary memory to check the second character
               
               ldaa     1,X+                  ; Load the 2nd character into A, and increment
               cmpa     #$0D                  ; check if its enter
               beq      addPad
               jsr      isDeci                  
               cmpb     #0                    ; check if its 0-9
               lbne     timeFError
               staa     1, Y                     ; Store it in temporary memory
               
               ldaa     1,X+                  ; Load the 5th character into A, and increment
               cmpa     #$0D                  ; check if its enter
               lbne     timeFError             ; make sure there's no more characters
               bra      secEnd
addPad
               ldaa     Y                     ; add a 0 if its only a 1 digit number
               ldab     #$30
               stab     Y
               staa     1, Y
secEnd               
               ldaa     Y
               cmpa     #$35                  ; make sure the first character is less than 6               
               lbhi     timeFError
               suba     #$30                  ; convert to hex
               ldab     #16                   ; load 10 into b
               mul                            ; multiply a and b

               ldaa     1, Y                  ; load the 10s place
               suba     #$30                  ; convert to hex
               aba                            ; add the two values together
               
               staa     TimerVal              ; Store the new value and update the display
               
               staa     PORTB
               bra      cmdEnd                ; return
quit  
               ldaa     1,X+                  ; Load the 2nd character into A, and increment
               cmpa     #$0D                  ; Check if char 2 is a return
               lbne     commandError          ; branch to error if its not
               ldab     #1                    ; Load register b with 1 for quit being called
               pulx                           ; Restore x
               pula                           ; Restore a
               rts                            ; return
;****************end of doCommand**************


;OPTIONAL
;more variable/data section below
; this is after the program code section
; of the RAM.  RAM ends at $3FFF
; in MC9S12C128 chip


msg1           DC.B    'Hello', $00
msg2           DC.B    'You may perform + - * / operations on numbers up to 999', $00
msg3           DC.B    'Enter your command below:', $00
msg4           DC.B    'Error: Invalid command', $00
msg5           DC.B    '      ', $00
msg6           DC.B    'W:      Write the data byte to memory location', $00
msg7           DC.B    '      Overflow Error', $00
msg8           DC.B    '      Invalid input format', $00
msg9           DC.B    'Tcalc>', $00
msg10          DC.B    '      Invalid input format due to 4th digit', $00
msg11          DC.B    '      Divide by Zero Error', $00
msg13          DC.B    'QUIT: Quit menu program, run Type writer program.', $00
msg14          DC.B    '      Invalid input format', $00
msg15          DC.B    'Use the command s [0 - 59] to change the clock timer, q to exit', $00
msg16          DC.B    '      Invalid time format. Correct example => 0 to 59', $00
msg17          DC.B    'You may type below', $00


               END               ; this is end of assembly source file
                                 ; lines below are ignored - not assembled/compiled
