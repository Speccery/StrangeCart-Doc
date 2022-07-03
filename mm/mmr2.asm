* MiniMemory ROM code, modified by Erik Piehl extensively for use
* with StrangeCart 2021-2022.

A660C  BYTE >65               string flag
A660D  BYTE >20               Cnd bit
*
*---------------------------------------
* NUMASG assign a value to a numeric variable
*---------------------------------------
A660E  MOV  *13,0             get user's R0: element #
       MOV  @>0002(13),1      get user's R1: parameter #
       BL   @A6658
       MOVB *3,3              get param type
       JEQ  A66EE             error 22
       SRL  3,8               make it a word
       DECT 3
       JNE  A6652             array
       MOV  0,0               not array: element must be 0
       JNE  A66EE             error 22
       MOV  5,3               entry in value stack
       INCT 3                 skip ptr to entry in symbol table
       BL   @A693A            read 1 byte into R1 from VDP at R3
       JNE  A66E6             must be >0000 for numeric variables
       INCT 3
       BL   @A68FE            read a word into R1
       MOV  1,3               this is pointer to value
A6638  MOV  3,4               make it destination in VDP mem
       LI   3,>834A           source is FAC
       LI   2,>0004           4 words
A6642  MOV  *3,1              get 1 word
       BL   @A691A            write it in VDP at R4
       INCT 3                 i.e. copy FAC into symbol value
       INCT 4
       DEC  2
       JGT  A6642             two more bytes to go
       RTWP
 
A6652  BL   @A667C
       JMP  A6638
*
* Get parameter info R1=param number
* ------------------ R3 will point to type byte
*                    R5 to address in value stack
A6658  MOV  1,1
       JEQ  A66EE             can't be used for param 0: error 22
       SLA  1,8               make it a byte
       CB   @>8312,1
       JLT  A66EE             error 22
       SRL  1,8               make i a word
       MOV  1,5
       SLA  5,3               8 bytes per param
       AI   5,>0008           plus 1 param for subprogram name
       A    @>8310,5          value stack base
       MOV  1,3
       DEC  3
       AI   3,>7002           param type bytes start at >7002
       B    *11
*
* Find an element in a numeric array  R3 will point to its value
* ----------------------------------
A667C  MOV  11,9              save return point
       DECT 3                 check param type
       JNE  A66E6             error 22
       MOV  5,3               address on value stack
       BL   @A68FE            read a word into R1
       MOV  1,3               ptr to entry in symbol table
       BL   @A693A            read 1 byte into R1
       JLT  A66E6             string flag is set: error 22
       BL   @A669C            set array pointers
       S    4,0               remove option base from requested element
       SLA  0,3               each element is 8 bytes
       A    0,3               point to the one we want
       B    *9
*
* Find an element in an array R3 will be ptr to first element
* --------------------------- R7 offset of the requested element
A669C  MOV  11,10             save return address
       SLA  1,5               keep only # of dimensions
       SRL  1,13              make it a word
       MOV  1,8               save it
       MOVB @>8343,4          option base
       SRL  4,8               make it a word
       JEQ  A66B2             base 1
       DEC  0                 base 0: compensate
       JLT  A66F6             illegal element: error 23
       INC  0                 restore it
A66B2  LI   6,>0001
       MOV  5,3               address in value stack
       AI   3,>0004           ptr to value
       BL   @A68FE            read 1 word into R1
       MOV  1,3
       DECT 3
A66C4  INCT 3
       BL   @A68FE            read 1 word into R1
       INC  1                 number of elements in this dimension
       S    4,1               substract option base
       MPY  1,6               total number of elements
       MOV  6,6               overflow?
       JNE  A66F6             yes: error 23
       MOV  7,6               current total
       DEC  8
       JGT  A66C4             more dimensions to come
       DEC  6
       A    4,6               compensate for option base
       C    0,6               compare with requested element
       JGT  A66F6             not in array: error 23
A66E2  INCT 3                 ptr to first element
       B    *10
*
A66E6  LI   0,>1500           error code 21
       B    @A696C            return to GPL with code in >8322 and Cnd bit set
A66EE  LI   0,>1600           error code 22
       B    @A696C            return to GPL with code in >8322 and Cnd bit set
A66F6  LI   0,>1700           error code 23
       B    @A696C            return to GPL with code in >8322 and Cnd bit set
*
*---------------------------------------
* NUMREF gets the value of a numeric variable
*---------------------------------------
A66FE  MOV  *13,0             get user's R0: element #
       MOV  @>0002(13),1      get user's R1: parameter #
       BL   @A6658            get param info pointers
       MOVB *3,3              get param type
       SRL  3,8
       JNE  A672A             variable or array
       MOV  0,0               constant: element must be 0
       JNE  A6764             error 22
       LI   2,>0008           8 bytes per float
       LI   4,>834A           FAC
       MOV  5,3               address in value stack
A671C  BL   @A68FE            read 1 word into R1
       MOV  1,*4+             copy it to FAC
       INCT 3
       DECT 2
       JGT  A671C             more to come
       RTWP
 
A672A  DECT 3                 param type
       JNE  A675A             array
       MOV  0,0               not an array: element must be 0
       JNE  A6764             else error 22
       MOV  5,3               address in value stack
       INCT 3
       BL   @A693A            get second word into R1
       JNE  A6760             this word must be >0000 for numeric variables
       INCT 3
       BL   @A68FE            get next word into R1
       MOV  1,3               this is a pointer to the value
A6744  LI   4,>834A           FAC
       LI   2,>0004           8 bytes = 4 words
A674C  BL   @A68FE            read 1 word into R1 from VDP at R3
       MOV  1,*4+             copy it to FAC
       INCT 3
       DEC  2
       JGT  A674C             more to come
       RTWP
 
A675A  BL   @A667C            point to element
       JMP  A6744             copy it to FAC
 
A6760  B    @A66E6            to error 21
A6764  B    @A66EE            to error 22
*
*---------------------------------------
* STRASG assigns a value to a string variable
*---------------------------------------
A6768  MOV  *13,0             get user's R0: element #
       MOV  @>0002(13),1      get user's R1: param #
       MOV  @>0004(13),9      get user's R2: string ptr
       BL   @A6658            get param info pointers
       MOVB *3,3              get param type
       SRL  3,8
       DEC  3
       JEQ  A67CE             can't be a string constant: error 22
       DECT 3
       JNE  A67FE             array
       MOV  0,0               not an array: element must be 0
       JNE  A67CE             else error 22
       MOV  5,3               address in value stack
       INCT 3                 skip ptr to entry in symbol table
       BL   @A693A            read 1 byte into R1
       CB   1,@A660C          is it the string flag (>65)?
       JNE  A67C6             no: error 21
       LI   6,>0008           entry is 8 bytes
       LI   4,>834A           place it to FAC
       MOV  5,3               address in value stack
A679E  BL   @A68FE            read 1 word into R1
       MOV  1,*4+             save it to FAC
       INCT 3
       DECT 6
       JGT  A679E             more to come
       BL   @A6828            create entry in string space, copy string
       AI   5,>0004           pointer to value
       MOV  5,4
       MOV  *6,1              address in string space
       BL   @A691A            write it to value entry
       INCT 4                 size
       MOV  @>830C,1          string size
       BL   @A691A            write it to value entry
       RTWP
 
A67C6  LI   0,>1500           error code 21
       B    @A696C            return to GPL with code in >8322 and Cnd bit set
A67CE  LI   0,>1600           error code 22
       B    @A696C            return to GPL with code in >8322 and Cnd bit set
*
* Find an element in a string array R1 will be a ptr to the string
*----------------------------------
A67D6  MOV  11,2              save return point
       DECT 3                 check param type
       JNE  A67C6             error 21 if not string array
       MOV  5,3               address in value stack
       BL   @A68FE            read 1 word into R1
       MOV  1,3               this is ptr in symbol table
       BL   @A693A            read first byte into R1
       JLT  A67EE             string flag set?
       B    @A67C6            no: error 21
A67EE  BL   @A669C            yes: set array pointers
       S    4,0               compensate for option base
       SLA  0,1               each element is 2-byte long (ptr to string)
       A    0,3
       BL   @A68FE            read 2 bytes into R1
       B    *2
 
A67FE  BL   @A67D6            STRASG continued, for string arrays
       LI   6,>834A           FAC
       MOV  3,*6+             entry in symbol table
       MOVB @A660C,*6+        string flag (>65)
       MOVB 4,*6+             dimensions
       MOV  1,*6+             ptr to value
       MOV  1,3
       JNE  A6818             no value yet: empty string
       CLR  *6                size = 0
       JMP  A6822
A6818  DEC  3                 point to size byte
       BL   @A693A            read it into R1
       SRL  1,8               make it a word
       MOV  1,*6              place it on FAC
A6822  BL   @A6828            assign string
       RTWP
*
* Create an entry for a string in TI-Basic tables
* ----------------------------
A6828  MOV  11,2              save return point
       LWPI >83E0             GPL workspace
       LI   11,>1EAA          address of XML >17 (push FAC on value stack)
       BL   *11               call XML >17
       LWPI >70F8             back to our workspace
       MOVB *9,6              get size byte
       SRL  6,8               make it a word
       MOV  6,@>830C          param for G@>0018
       MOV  6,@>8350          place it in FAC
       BLWP @A6018            call GPLLNK
       DATA >0038             string space allocation routine (remove from stac)
       LI   6,>834A           FAC: entry of string
       LI   4,>001C           flag for string constant
       MOV  4,*6+
       MOVB @A660C,*6+        flag for string (>65)
       MOVB 4,*6+             >00: for non-arrays
       MOV  @>831C,*6         address returned by G@>0018
       MOV  @>830C,8          string size
       JEQ  A6876             empty string: assign it
       MOV  *6,4              address in string space
       MOV  9,3               address passed by user
       INC  3                 skip size byte
A686A  MOVB *3+,1             get 1 byte
       BL   @A694E            write it to VDP at R4
       INC  4                 update pointer
       DEC  8
       JGT  A686A             more to do
A6876  LWPI >83E0             GPL workspace
       LI   11,>1788          address of XML >15 main routine
       BL   *11               call XML >15: assign variable
       LWPI >70F8             back to our workspace
       MOV  2,11              return point (saved upon entering A6828)
       B    *11
*
*---------------------------------------
* STRREF gets the value of a string variable
*---------------------------------------
A6888  MOV  *13,0             get user's R0: element #
       MOV  @>0002(13),1      get user's R1: param #
       BL   @A6658            get param info ptr
       MOVB *3,3              get param type
       SRL  3,8
       DEC  3
       JEQ  A689E             string constant
       DECT 3
       JNE  A68E4             array
A689E  MOV  0,0               not an array: element must be 0
       JNE  A68F2             else error 22
       MOV  @>0004(13),0      get user's R2: buffer address
       MOV  5,3               address in value stack
       INCT 3                 skip ptr to entry in symbol table
       BL   @A693A            read 1 byte into R1
       CB   1,@A660C          is it string flag (>65)?
       JNE  A68EE             no: error 21
       INCT 3
       BL   @A68FE            read next word into R1
A68BA  MOV  1,1               pointer to value
       JEQ  A68CC
       MOV  1,6               save it
       DEC  1                 point to length byte
       MOV  1,3
       BL   @A693A            get length byte into R1
       CB   *0,1              is there room enough in buffer?
       JL   A68F6             no: error 37
A68CC  MOVB 1,*0+             copy string size into buffer
       JEQ  A68E2             empty string: done
       MOV  6,3               ptr to string in string space
       SRL  1,8               make size a word
       MOV  1,5
A68D6  BL   @A693A            read 1 byte into R1
       MOVB 1,*0+             copy it into buffer
       INC  3                 update ptr
       DEC  5
       JGT  A68D6             more to come
A68E2  RTWP
 
A68E4  BL   @A67D6            string array: find the element
       MOV  @>0004(13),0      get user's R2: buffer ptr
       JMP  A68BA             copy string into buffer
 
A68EE  B    @A66E6            to error 21
A68F2  B    @A66EE            to error 22
A68F6  LI   0,>2500           error 37
       B    @A696C            return to GPL with code in >8322 and Cnd bit set
*
* Read 2 bytes from VDP into R1, address in R3
* ---------------------
A68FE  SWPB 3                 set VDP to read
       MOVB 3,@>8C02
       SWPB 3
       MOVB 3,@>8C02
       NOP
       MOVB @>8800,1          get two bytes into R1
       SWPB 1
       MOVB @>8800,1
       SWPB 1
       B    *11
*
* Write 2 bytes to VDP from R1, address in R4
* --------------------
A691A  SWPB 4                 set VDP to write
       MOVB 4,@>8C02
       SWPB 4
       ORI  4,>4000           set flag for 'write' command
       MOVB 4,@>8C02
       NOP
       MOVB 1,@>8C00          write two bytes to VDP
       SWPB 1
       MOVB 1,@>8C00          write byte
       SWPB 1
       B    *11
*
* Read 1 byte from VDP into R1, address in R3
* --------------------
A693A  SWPB 3                 set VDP for read
       MOVB 3,@>8C02
       SWPB 3
       MOVB 3,@>8C02
       NOP
       MOVB @>8800,1          read 1 byte
       B    *11
*
* Write 1 byte to VDP from R1, address in R4
* -------------------
A694E  SWPB 4                 set address to write
       MOVB 4,@>8C02
       SWPB 4
       ORI  4,>4000           flag for 'write' command
       MOVB 4,@>8C02
       NOP
       MOVB 1,@>8C00
       B    *11
*
*---------------------------------------
* ERROR generates a TI-Basic error
*---------------------------------------
A6966  MOV  *13,@>8322        get error code from user's R0
       JMP  A6970
 
A696C  MOV  0,@>8322          pass error code
A6970  LWPI >83E0             GPL workspace
A6974  SOCB @A660D,@>837C     set Cnd bit
       B    @>0070            to GPL interpreter
*
*---------------------------------------
* Bytes >697E to >6F0D all contain >00
*---------------------------------------
*     BSS  >0588
*------------------------------------------
* EP: Except in my case I put code in here.
* This is where XML >73 lands.
* It appears the low registers at least are 
* safe to change.
*------------------------------------------
STRANGECODE
      MOV   @>834A,@VDP_DESTA ; Copy the input parameter to StrangeCart address space
      MOVB  @>834D,1          ; Check 834D from our GPL code to see if this is call run.
      ANDI  1,>FF00           ; zero out low byte.
      SWPB  1                 ; Move index to low byte
      CI    1,7               ; index >= max command?
      JHE   !                 ; Yes: go back to GPL
      SLA   1,1               ; no: multiply index by 2
      LI    2,STRANGECMDS     ; Jump table base
      A     1,2               ; Add base
      MOV   *2,2              ; Fetch target address.    
      B     *2                ; jump to routine
!     B     @A6970            ; Get back to GPL
STRANGECMDS
      DATA  CMD_LIST          ; 0
      DATA  CMD_RUN           ; 1
      DATA  CMD_CARTS         ; 2
      DATA  CMD_CARTLOAD      ; 3
      DATA  CMD_VSYNC         ; 4
      DATA  CMD_DIR           ; 5
      DATA  CMD_GRAM          ; 6

HEX2SCR
      MOV 11,@>7006           ; Save return address to >7006
      LI  4,>80               ; Screen address where to write to.
      LI  1,>8E00             ; '.'+96, write the period character
      BL  @A694E              ; Set VDP address, and write byte from R1
      MOV @>834A,2            ; Load value to be printed to R2
      LI  3,4                 ; 4 digits to write.
!     MOV 2,1
      BL  @HEXDIG
      SLA 2,4
      DEC 3
      JNE  -!
      MOV  @>7006,11
      B   *11                ; Return
      

HEXDIG ; Write the highest nibble of 1 in hex to VDP memory
      SRL   1,4               Shift to low nibble of byte
      CI    1,>0900           Is the value 9 or lower
      JLE   !                 Yes: branch
      AI    1,>0700           No: Add 7 to high byte of R1
!     AI    1,>9000         Add screen offset 60 and 30 to get ASCII of 0
      MOVB  1,@>8C00
      B     *11

* Copy VDP screen, first 768 bytes, to mini memory
SCR2MM  
      LI    5,VDP_BUF         Mini memory address, we dump VRAM here.
      LI    6,VDP_BUF2         End address
      CLR   3               VDP address
      BL    @A693A          Set it and read first byte to R1.
!     MOVB  1,*5+           Store to MM RAM
      MOVB @>8800,1         read next byte from VDP
      C     5,6             Did we reach the end of transfer?
      JNE   -!              No: continue loop
      B     @A6970          Yes: Get back to GPL

* Copy from mini memory RAM to VDP screen
MM2SCR_CMD
      MOV   11,@RUN_R11     Save return address
      BL    @MM2SCR
BACK2GPL
      MOV   @RUN_R11,11     Restore return address
      B     @A6970        Yes: Get back to GPL

MM2SCR
      MOV   11,7          Save return address
      LI    5,VDP_BUF       Source address
      LI    6,VDP_BUF2       End address

      LI    4,>0040       Destination address in VDP RAM in R4 (bytes reversed, and write flag)
      MOVB  4,@>8C02      Set low byte of address to write
      SWPB  4
      MOVB  4,@>8C02      High byte of address to write

      LI    4,>8C00       VDP data write port addr to R4
!     MOV   *5+,3         Load 2 bytes of data to write to VDP
      MOVB  3,*4          Copy 1st byte to VDP RAM
      SWPB  3
      MOVB  3,*4          Copy 2nd byte to VDP RAM
      C     5,6           Are we at the end?
      JNE   -!            No: continue loop
      B     *7            Return

*******************************************************************
* CMD_LIST
* List a BASIC program (and also serve other listings)
*******************************************************************
* We issue a command to ask for the list, and then just dump it to
* VDP memory, and wait for further instructions.
CMD_LIST
      LI    1,'L'*256       Basic list command
CMD_LL_SETUP
      MOV   11,@RUN_R11     Save return address
      MOV   1,@LIST_VAR     Store for later
; Enter our generic listing routine
CMD_LIST2
      CLR   @WAIT_FLAG      Clear wait flag.
      MOV   @LIST_VAR,1     Fetch listing command
      MOVB  1,@RUN_CMD      Command to strange cart.
!     MOV   @WAIT_FLAG,1    Read wait flag. Is it zero?
      JEQ   -!              Yes: continue to wait.
* Check wait flag. 1 = done to screen and return.
* 2 = copy to screen and wait for more data.      
      BL    @MM2SCR         Copy to screen.
      MOV   @WAIT_FLAG,1    Read wait flag
      CI    1,>0200         Is the wait flag 2?
      JEQ   CMD_LIST2       Yes go again.
      CLR   @WAIT_FLAG      No: we are ready. Reset wait flag.
      JMP   BACK2GPL        Return to GPL

*******************************************************************
* CMD_CARTS
* List carts
*******************************************************************
CMD_CARTS
      LI    1,'C'*256       'C' << 8 is our command for cart listing
      JMP   CMD_LL_SETUP

*******************************************************************
* CMD_DIR
* List disk contents
*******************************************************************
CMD_DIR
       LI     1,'D'*256
       JMP    CMD_LL_SETUP

*******************************************************************
* CMD_CARTLOAD
* Load the selected cartridge.
*******************************************************************
CMD_CARTLOAD
       LI     1,'*'*256      * is the command for cart loading.
CMD_CL_SETUP
      MOV   11,@RUN_R11     Save return address
      MOV   1,@LIST_VAR     Store for later
; Enter our generic listing routine
CMD_CARTLOAD2
      CLR   @WAIT_FLAG      Clear wait flag.
      MOV   @LIST_VAR,1     Fetch listing command
      MOVB  1,@RUN_CMD      Command to strange cart.
!     MOV   @WAIT_FLAG,1    Read wait flag. Is it zero?
      JEQ   -!              Yes: continue to wait.
* Check wait flag. 1 = done to screen and return.
* 2 = copy to screen and wait for more data.      
      BL    @MM2SCR         Copy to screen.
      MOV   @WAIT_FLAG,1    Read wait flag
      CI    1,>0200         Is the wait flag 2?
      JEQ   CMD_CARTLOAD2   Yes go again.
      CLR   @WAIT_FLAG      No: we are ready. Reset wait flag.
      LIMI  0
      BLWP  @>0000          Reset the console.  

*******************************************************************
* CMD_RUN
* We arrive here to run a basic program.
*******************************************************************
* Equates for various memory locations
* For the CMD_RUN commands
LIST_VAR    EQU   >77FC     ; LIST parameter temp storage
RUN_R11     EQU   >77FE     ; R11 temporary storage (return address)
VDP_BUF     EQU   >7800     ; VDP 32*24 buffer
VDP_BUF2    EQU   >7B00     ; working buffer
WREGS       EQU   >7FC0     ; Temp workspace for KSCAN
VDP_DESTA   EQU   >7FE0     ; VDP Destination address (from strangecart)
SYS_SRC_A   EQU   >7FE2     ; Source address for data transfer (from strangecart)
SYS_SRC_END EQU   >7FE4     ; End of data address  (from strangecart)
KSCAN_FLAG  EQU   >7FE6     ; BYTE pass KSCAN result to StrangeCart
KSCAN_KEY   EQU   >7FE7     ; BYTE keyscan code to StrangeCart
OLDR11      EQU   >7FE8     ; R11 storage during KSCAN call
OLDHOOK     EQU   >7FEA     ; Store old interrupt vector.
ISRCOUNT    EQU   >7FEC     ; Counts interrupts.
RUN_CMD     EQU   >7FF0     ; Command strange cart.
WAIT_FLAG   EQU   >7FF2     ; Wait for strangecart, commands from it.

***
CMD_RUN: 
      MOV   11,@RUN_R11     Save return address
CMD_RUN2
      MOV   @>834A,@VDP_DESTA ; Copy the input parameter to StrangeCart address space
      CLR   @WAIT_FLAG        Clear wait flag.
      LI    1,'R'*256     'R' << 8 is our command for cart listing
      MOVB  1,@RUN_CMD      Command to strange cart.
      LIMI  2               ; Enable interrupts
!     MOV   @WAIT_FLAG,1      Read wait flag. Is it zero?
      JEQ   -!            Yes: continue to wait.
      LIMI  0
* Check wait flag. 
* 1 = copy to screen and return.
* 2 = copy to screen and wait for more data.      
* 3 = write to VDP memory from given address, and wait for more data.
* 4 = write to VDP register and wait for more data.
* 5 = perform KSCAN and wait for more data.
* 6 = VDP VCHAR
* 7 = JOYST read joysticks
* 8 = copy from VDP RAM
* 9 = write series to a specified memory location (e.g. sound chip)
* 10 = copy block from system to system RAM
      MOV   @WAIT_FLAG,1  Read wait flag
      ANDI  1,>FF00       Make sure LS byte zero
      SRL   1,7           Shift to low byte, now WAIT_FLAG*2
      DECT  1             Make zero based
      AI    1,RUN_JUMPS   add jump table base
      MOV   *1,1          Fetch target address from table
      B     *1            Jump there
RUN_JUMPS: 
       DATA CMD_MM2SCR_ONCE, CMD_MM2SCR_LOOP    ; 1,2
       DATA CMD_VDPWR, CMD_VDPREG, CMD_KSCAN    ; 3,4,5
       DATA CMD_VCHAR, CMD_JOYST, CMD_VDPRD     ; 6,7,8
       DATA CMD_WRSERIES, CMD_COPY              ; 9, 10

CMD_MM2SCR_ONCE: 
       BL     @MM2SCR       Copy to screen
       CLR    @WAIT_FLAG    Ready, reset wait flag.
       JMP    BACK2GPL      Return to GPL
CMD_MM2SCR_LOOP:
       BL     @MM2SCR       Copy to screen
       JMP    CMD_RUN2      And continue to run.

CMD_VDPWR:
      MOV   @VDP_DESTA,4    Get destination address to R4
      MOV   @SYS_SRC_A,5    Source address to R5
      MOV   @SYS_SRC_END,6  End of data address to R6

      ORI   4,>4000       Set mem write flag
      SWPB  4
      MOVB  4,@>8C02      Set low byte of address to write
      SWPB  4
      MOVB  4,@>8C02      High byte of address to write and write flag

      LI    4,>8C00       VDP data write port addr to R4
!     MOVB  *5+,3         1 Byte to write to VDP
      MOVB  3,*4          Copy byte to VDP RAM
      C     5,6           Are we at the end?
      JNE   -!            No: continue loop
      JMP   CMD_RUN2      Wait for next command.

CMD_VDPREG:
      MOV   @VDP_DESTA,0      Get register number and data
      ORI   0,>8000       Set register write flag
      SWPB  0   
      MOVB  0,@>8C02      Low byte is data to write
      SWPB  0       
      MOVB  0,@>8C02      High byte is register number + flag
      JMP   CMD_RUN2

CMD_KSCAN: 
      MOVB  @VDP_DESTA,1     Get keyboard scanning mode parameter
      ANDI  1,>FF00         Is it zero?
      JEQ   !               Yes: don't set keyboard scanning mode.
      MOVB  1,@>8374        Set keyboard scanning mode
!     BLWP 	@KSCAN
      ; Copy result of scan for strangecart to look at.
      MOVB 	@>837C,@KSCAN_FLAG  Check flag for key pressed (>20)
      MOVB 	@>8375,@KSCAN_KEY       Get key code
      JMP   CMD_RUN2

KSCAN  DATA WREGS,KSCAN1
 
KSCAN1 LWPI >83E0           can't change WS with BLWP as R13-R15 are in use
       MOV  11,@OLDR11      save GPL R11
       BL   @>000E          call keyboard scanning routine
       MOV  @OLDR11,11      restore GPL R11
       LWPI WREGS
       RTWP

CMD_VCHAR:
      MOV   @VDP_DESTA,4    Get destination address to R4
      MOV   @SYS_SRC_A,5    Source address to R5
      MOV   @SYS_SRC_END,6  End of data address to R6

      ORI   4,>4000       Set mem write flag
      LI    7,>8C02       VDP command register pointer

!     SWPB  4
      MOVB  4,*7          Set low byte of address to write
      SWPB  4
      MOVB  4,*7          High byte of address to write and write flag
      AI    4,>20         Go to next line in VDP RAM
      MOVB  *5+,@>8C00    1 Byte to write to VDP
      C     5,6           Are we at the end?
      JNE   -!            No: continue loop
      JMP   CMD_RUN2      Wait for next command.

CMD_JOYST:                ; Read joysticks
      MOV   12,3          Save old R12
      LI    12,>0024      Column decoder CRU
      LI    1,>0600       Column 6, joystick 1
      LDCR  1,3           Select the column
      LI    12,>0006      CRU address of keyboard rows
      STCR  1,5           Read joystick position and fire button to R1
      LI    12,>0024      Column decoder CRU
      LI    2,>0700       Column 7, joystick 2
      LDCR  2,3           Select the column
      LI    12,>0006      CRU address of keyboard rows
      STCR  2,5           Read joystick position and fire button to R2
      MOVB  2,@KSCAN_FLAG  Save joystick2 status
      MOVB  1,@KSCAN_KEY   Save joystick1 status
      MOV   3,12           Restore R12
      B     @CMD_RUN2      Wait next command

CMD_VDPRD:                 ; Read from VDP RAM
      MOV   @VDP_DESTA,4    Get destination address to R4 (in system RAM)
      MOV   @SYS_SRC_A,5    Source address to R5 (in VDP RAM)
      MOV   @SYS_SRC_END,6  End of data address to R6 (in VDP RAM)
      ; Setup VDP address for reads from R5
      SWPB  5
      MOVB  5,@>8C02      Set low byte of address to read
      SWPB  5
      MOVB  5,@>8C02      High byte of address to read 
      S     6,5           Count of bytes to read.
!     MOVB  @>8800,*4+    Read a byte from VDP read to port to RAM
      DEC   6             Decrement count
      JNE   -!            Continue if not done.
      B     @CMD_RUN2     Jump back

CMD_WRSERIES:  ; Write a series of bytes to given address in system memory
       ; Useful for example when writing to the sound chip.
      MOV   @VDP_DESTA,4    destination in system memory
      MOV   @SYS_SRC_A,5    Source address to R5
      MOV   @SYS_SRC_END,6  End of data address to R6
!     MOVB  *5+,*4          Move data byte
      C     5,6             At the end?
      JNE   -!              No: loop back to next byte
      B     @CMD_RUN2     Jump back

CMD_COPY:           ; copy block from system RAM to system RAM. Same as above but with dest increment.
      MOV   @VDP_DESTA,4    destination in system memory
      MOV   @SYS_SRC_A,5    Source address to R5
      MOV   @SYS_SRC_END,6  End of data address to R6
!     MOVB  *5+,*4+         Move data byte
      C     5,6             At the end?
      JNE   -!              No: loop back to next byte
      B     @CMD_RUN2      Jump back

*******************************************************************
* CMD_VSYNC
* Do VSYNC. Install ISR if necessary.
*******************************************************************
CMD_VSYNC
       MOV    @>83C4,1      ; Fetch current ISR pointer.
       LI     2,VSYNC_ISR   ; pointer to our ISR
       C      1,2           ; Does current ISR match our ISR?
       JEQ    !             ; Yes: skip
       ; No: Install our ISR
       MOV    1,@OLDHOOK    ; Save old ISR hook
       MOV    2,@>83C4      ; Install our ISR.
       CLR    @ISRCOUNT     ; Zero interrupt counter.
       B      @A6970        ; Get back to GPL, don't wait on the first call.
!      ; Now wait for interrupt.
       MOV    @ISRCOUNT,1   ; Read current ISRCOUNT
       LIMI   2
!      C      @ISRCOUNT,1   ; Is ISRCOUNT still the same
       JEQ    -!            ; Yes: wait
       LIMI   0
       B      @A6970        ; No: Get back to GPL

VSYNC_ISR INC @ISRCOUNT
       MOV    @OLDHOOK,2
       JEQ    !             ; If old hook is zero,return from ISR
       B      *2            ; Jump to old hook
!      B      *11           ; Return from ISR      

*******************************************************************
* CMD_GRAM.
* If parameter is > 255 initialize GRAM.
* Enable writes as per mask in the lower 8 bits.
* The parameter is already copied to @VDP_DESTA
*******************************************************************
CMD_GRAM:
       MOV   11,@RUN_R11     Save return address
       MOV    @VDP_DESTA,0
       CI     0,>100        ; Parameter >= 100
       JHE    GRAM_INIT     ; Yes: initialize GRAM
; Not an init command. Just pass the bitmask to strangecart.
CMD_GRAM2:
       BL     @ISSUE_A_CMD
; Command processed by StrangeCart. Get back to GPL.
       CLR   @WAIT_FLAG
       B     @BACK2GPL

ISSUE_A_CMD:
       LI     1,'A'*256     ; Command for GRAM
       CLR    @WAIT_FLAG   
       MOVB   1,@RUN_CMD    ; Issue command to StrangeCart
!      MOV    @WAIT_FLAG,1  ; Read wait flag
       JEQ    -!            ; If it is zero, loop back
       B      *11

GRAM_INIT:    ; Initialize system GRAM.
       LI     3,>707        ; Enable sysgram for writing only.
       MOV    3,@VDP_DESTA
       BL     @ISSUE_A_CMD
; Ok now GRAM is writable and we can copy system GROM to GRAM.
; First let's remember our current GROM address in R3.
       MOVB   @2(13),3         ; GROM address read, high byte.
       MOVB   @2(13),@>83E7    ; GROM address read, low byte to R3. So dirty.
       DEC    3                ; Adjust to correct the address.
       CLR    2                ; our GROM address counter
!      ; Loop to copy two bytes from GROM to GRAM per loop iteration.
       MOVB   2,@>0402(13)         ; Write GROM address high byte.
       MOVB   @>83E5,@>0402(13)    ; Write GROM address low byte.
       MOVB   *13,4                ; Read a byte from GROM
       MOVB   *13,5                ; and another one
       MOVB   2,@>0402(13)         ; Write GROM address again, high byte
       MOVB   @>83E5,@>0402(13)    ; and low byte
       MOVB   4,@>0400(13)         ; copy 1st byte to GRAM
       MOVB   5,@>0400(13)         ; and write another to GRAM.
       INCT   2                    ; addr += 2
       CI     2,>6000              ; End of system GROM?
       JNE    -!                   ; No: copy next 2 bytes
; Now we have copied GROM to GRAM. What remains is to set the original
; value provided to us, but only the low 8 bits. Thus we enable reading from GRAM.
; But first restore GROM pointer.
       MOVB   3,@>0402(13)
       MOVB   @>83E7,@>0402(13)
; Let's adjust the parameter then.
       ANDI   0,>00FF              ; Mask off high bits of our parameter.
       MOV    0,@VDP_DESTA
       JMP    CMD_GRAM2            ; Issue one more 'A' command and return.

*---------------------------------------
**      BSS  >04E6-68      Remember to adjust this to make cart fit into 4k. 
      BSS  >6F06-$
A6F06  BSS  >0008
*
*---------------------------------------
* Default symbol table
*---------------------------------------
A6F0E  TEXT 'UTLTAB'          utility table for loader
       DATA >7020
       TEXT 'PAD   '          scratch-pad memory
       DATA >8300
       TEXT 'GPLWS '          GPL workspace
       DATA >83E0
       TEXT 'SOUND '          soud port
       DATA >8400
       TEXT 'VDPRD '          VDP read-data port
       DATA >8800
       TEXT 'VDPSTA'          VDP status-read port
       DATA >8802
       TEXT 'VDPWD '          VDP write-data port
       DATA >8C00
       TEXT 'VDPWA '          VDP write-address port
       DATA >8C02
       TEXT 'SPCHRD'          speech synthesizer read-data port
       DATA >9000
       TEXT 'SPCHWT'          speech synthesizer write-data port
       DATA >9400
       TEXT 'GRMRD '          GRAM/GROM read-data port
       DATA >9800
       TEXT 'GRMRA '          GRAM/GROM read-address port
       DATA >9802
       TEXT 'GRMWD '          GRAM write-data port
       DATA >9C00
       TEXT 'GRMWA '          GRAM/GROM write-address port
       DATA >9C02
       TEXT 'SCAN  '          keyboard scanning routine in console ROM
       DATA >000E
 
       TEXT 'XMLLNK'          subroutines provided by the cartridge
       DATA A601C
       TEXT 'KSCAN '
       DATA A6020
       TEXT 'VSBW  '
       DATA A6024
       TEXT 'VMBW  '
       DATA A6028
       TEXT 'VSBR  '
       DATA A602C
       TEXT 'VMBR  '
       DATA A6030
       TEXT 'VWTR  '
       DATA A6034
       TEXT 'DSRLNK'
       DATA A6038
       TEXT 'LOADER'
       DATA A603C
       TEXT 'GPLLNK'
       DATA A6018
       TEXT 'NUMASG'
       DATA A6040
       TEXT 'NUMREF'
       DATA A6044
       TEXT 'STRASG'
       DATA A6048
       TEXT 'STRREF'
       DATA A604C
       TEXT 'ERR   '
       DATA A6050
 
A6FFE  DATA >FB4C             checksum (?)
*
A7000  END
