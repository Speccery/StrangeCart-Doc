*=====================================
* MINI-MEMORY   ROM DISASSEMBLY
* -----------
*               Th. Nouspikel 1999
*=====================================
       AORG >6000
*
* EPEP modified for xas99.py
* Changes prefixed with EPEP at least initially
*
A6000  DATA >AA00,>0000,>0000
       DATA >0000,>0000,>0000
       DATA >0000,>0000
A6010  DATA A605A             XML >70 (LINK)
A6012  DATA A62CA             XML >71 (calls LOADER)
A6014  DATA A618C             XML >72 (CFI)
A6016  DATA STRANGECODE       XML >73 Now used by StrangeCart: used to be none
 
A6018  DATA >7092,A60F6       GPLLNK
A601C  DATA >7092,A60C8       XMLLNK
A6020  DATA >7092,A6110       KSCAN
A6024  DATA >7092,A6126       VSBW
A6028  DATA >7092,A6132       VMBW
A602C  DATA >7092,A6140       VSBR
A6030  DATA >7092,A614C       VMBR
A6034  DATA >7092,A615A       VWTR
A6038  DATA >7098,A61E4       DSRLNK
A603C  DATA >70D8,A62EC       LOADER
A6040  DATA >70F8,A660E       NUMASG
A6044  DATA >70F8,A66FE       NUMREF
A6048  DATA >70F8,A6768       STRASG
A604C  DATA >70F8,A6888       STRREF
A6050  DATA >70F8,A6966       ERR
 
A6054  DATA >0064             100
A6056  DATA >2000             eq bit
A6058  DATA >2E00             .
*
*-------------------------------------
* LINK to a subprogram  Name in >834A-834F, size in >8350
*-------------------------------------
A605A  MOV  11,@>702E         save return point
       MOVB @>8349,1          check flags
       COC  @A6056,1
       JEQ  A60BC
       MOV  @>8350,0          name length
       JEQ  A6090             0: same as before
       BL   @A65DA
       JMP  A60B0
A6074  CI   1,>8000           all labels done?
       JEQ  A60AC             yes: error 15
       MOV  1,0               currently compared label
       LI   2,>834A           check name
       C    *0+,*2+
       JNE  A60A6
       C    *0+,*2+
       JNE  A60A6
       C    *0+,*2+
       JNE  A60A6
       MOV  *0,@>7020         match: save address
A6090  LWPI >70B8             user workspace
       MOV  @>7020,0          get address
       JEQ  A60AC             none: error 15
       BL   *0                execute program
       LWPI >83E0             GPL workspace
       MOV  @>702E,11         get return point
       B    *11               return to caller
 
A60A6  AI   1,>0008           next label
       JMP  A6074
 
A60AC  LI   0,>0F00           error 15
A60B0  MOVB 0,@>8322          save error code
       LWPI >83E0             GPL workspace
       B    @A6974            set CND flag in >837C, to GPL interpreter
 
A60BC  SZCB @A6056,@>8349
       LWPI >7092
       RTWP
*
*-------------------------------------
* XMLLNK  XML to call in data word
*-------------------------------------
A60C8  MOV  *14+,@>83E2       get XML code or address in GPL R1
       LWPI >83E0             GPL workspace
       MOV  11,@>70A8         save R11 for later
       MOV  1,2               get data word
       CI   1,>8000           was it an address?
       JH   A60EA             yes: call it directly
       SRL  1,12              no: table and proc #
       SLA  1,1               make up table address
       SLA  2,4
       SRL  2,11              make up proc offset
       A    @>0CFA(1),2       address in table
       MOV  *2,2              get vector
A60EA  BL   *2                execute routine
       LWPI >7092             back to our workspace
       MOV  11,@>83F6         restore GPL R11
       RTWP                   return to caller
*
*-------------------------------------
* GPLLNK  call a GPL subroutine, address in data word
*-------------------------------------
A60F6  MOVB @>8373,1          subroutine stack pointer
       SRL  1,8               make it a word
       MOV  *14+,@>8304(1)    place data word on it
       SOCB @A6056,@>8349     set flag
       LWPI >83E0             GPL workspace
       MOV  @>702E,11         get return point
       B    *11               branch to it
*
*-------------------------------------
* KSCAN Scan the keyboard
*-------------------------------------
A6110  LWPI >83E0             GPL workspace
       MOV  11,@>70A8         save GPL R11
       BL   @>000E            scan keyboard
       LWPI >7092             back to our workspace
       MOV  11,@>83F6         restore GPL R11
       RTWP                   return to caller
*
*-------------------------------------
* VDP access subroutines
*-------------------------------------
A6126  BL   @A616C            VSBW set address to write to R0
       MOVB @>0002(13),@>8C00  ; write 1 byte from R1h
       RTWP
*
A6132  BL   @A616C            VMBW set address to write to R0
A6136  MOVB *1+,@>8C00        write 1 byte, ptr in R1
       DEC  2
       JNE  A6136             more to come
       RTWP
*
A6140  BL   @A6172            VSBR set address to read from R0
       MOVB @>8800,@>0002(13)  ; read 1 byte in R1h
       RTWP
*
A614C  BL   @A6172            VMBR set address to read from R0
A6150  MOVB @>8800,*1+        write 1 byte, ptr in R1
       DEC  2
       JNE  A6150             more to come
       RTWP
 
A615A  MOV  *13,1             VWTR get R0h
       MOVB @>0001(13),@>8C02 ; pass R0l
       ORI  1,>8000           write-to-register command flag
       MOVB 1,@>8C02          pass it
       RTWP
 
A616C  LI   1,>4000           set VDP to write: command flag
       JMP  A6174
A6172  CLR  1                 set VDp to read: no flag
A6174  MOV  *13,2             get address from R0
       MOVB @>7097,@>8C02     pass R2l
       SOC  1,2               add flag
       MOVB 2,@>8C02          pass it
       MOV  @>0002(13),1      get caller's R1
       MOV  @>0004(13),2      get caller's R2
       B    *11
*
*-------------------------------------
* CIF Convert integer to floating point (from FAC to FAC)
*-------------------------------------
A618C  LI   4,>834A           FAC pointer
       MOV  *4,0              get integer
       MOV  4,6
       CLR  *6+               clear FAC
       CLR  *6+
       MOV  0,5               # is 0?
       JEQ  A61E2             yes: we are done
       ABS  0                 sign will be done later
       LI   3,>0040           exponent 0
       CLR  *6+               clear remaining of FAC
       CLR  *6
       CI   0,100             2-digit number?
       JL   A61D2             yes: put them to FAC and return
       CI   0,10000           3-digit number?
       JL   A61C2             yes
       INC  3                 no: raise exponent
       MOV  0,1
       CLR  0
       DIV  @A6054,0          divide by 100
       MOVB @>83E3,@>0003(4)  place remainder (R1l) in FAC
A61C2  INC  3                 raise exponent
       MOV  0,1
       CLR  0
       DIV  @A6054,0          divide by 100
       MOVB @>83E3,@>0002(4)  place remainder in FAC (R1l)
A61D2  MOVB @>83E1,@>0001(4)  place result in FAC (R0l)
       MOVB @>83E7,*4         place exponent in FAC (R3l)
       INV  5                 check sign
       JLT  A61E2             positive
       NEG  *4                negative: negate first word
A61E2  B    *11
*
*-------------------------------------
* DSRLNK Call DSR or subprogram
*-------------------------------------
A61E4  MOV  *14+,5            get data word: >0008 = DSR, >000A = subprogram
       SZCB @A6056,15         clear Eq bit
       MOV  @>8356,0          get name ptr
       MOV  0,9
       AI   9,>FFF8           point to status/error byte in PAB
       BLWP @A602C            VSBR
       MOVB 1,3               name size
       SRL  3,8               make it a word
       SETO 4                 character counter
       LI   2,>708A           name buffer
A6202  INC  0
       INC  4
       C    4,3               whole name done?
       JEQ  A6216             yes
       BLWP @A602C            no: read a char with VSBR
       MOVB 1,*2+             save it on buffer
       CB   1,@A6058          is it . ?
       JNE  A6202             no: next char
A6216  MOV  4,4               yes: did we find any char before the dot?
       JEQ  A62BE             empty name: error 0
       CI   4,>0007           check name size
       JGT  A62BE             8 char or more: error 0
       CLR  @>83D0            buffer for CRU address
       MOV  4,@>8354          save name size
       MOV  4,@>7034          again for internal use
       INC  4
       A    4,@>8356          point at end-of-name
       MOV  @>8356,@>7036     save for recall
       LWPI >83E0             GPL workspace
       CLR  1                 call counter
       LI   12,>0F00          CRU
A6242  MOV  12,12             first CRU?
       JEQ  A6248             yes: skip
       SBZ  0                 no: turn previous card off
A6248  AI   12,>0100          next card
       CLR  @>83D0            reset buffer
       CI   12,>2000          last card done?
       JEQ  A62BA             yes: error 0
       MOV  12,@>83D0         save current CRU
       SBO  0                 turn card on (if any)
       LI   2,>4000
       CB   *2,@A6000         check if valid header (>AA)
       JNE  A6242             no: next card
       A    @>70A2,2          yes: get first link (sub or DSR)
       JMP  A6272
A626C  MOV  @>83D2,2          address of 'next link' word
       SBO  0                 make sure card is on
A6272  MOV  *2,2              next link
       JEQ  A6242             no more: next card
       MOV  2,@>83D2          save address (ptr to next link)
       INCT 2
       MOV  *2+,9             program address
       MOVB @>8355,5          name size
       JEQ  A6296             no name: execute
       CB   5,*2+             same size?
       JNE  A626C             no: next link
       SRL  5,8               yes: make it a word
       LI   6,>708A           name buffer
A628E  CB   *6+,*2+           check name
       JNE  A626C             mismatch: next link
       DEC  5
       JNE  A628E             next char
A6296  INC  1                 occurences counter
       MOV  1,@>7038          save it for recall
       MOV  9,@>7032          save program address
       MOV  12,@>7030         save CRU
       BL   *9                call DSR/subprogram
       JMP  A626C             keep scanning
       SBZ  0                 done: turn card off
       LWPI >7098             DSRLNK workspace
       MOV  9,0               status/error byte in PAB
       BLWP @A602C            VSBR: read it
       SRL  1,13              keep only error bits
       JNE  A62C0             error
       RTWP                   no error: return to caller
 
A62BA  LWPI >7098             back to DSRLNK workspace
A62BE  CLR  1                 error #0
A62C0  SWPB 1
       MOVB 1,*13             pass error code in caller's R0
       SOCB @A6056,15         set eq bit
       RTWP                   return to caller
*
*-------------------------------------
* XML >71 calls the loader
*-------------------------------------
A62CA  MOV  11,@>702E         save return point
       LWPI >70B8             get our workspace
       BLWP @A603C            call the loader
       LWPI >83E0             back to GPL workspace
       JEQ  A62E2             an error occured
       MOV  @>702E,11         get return point
       B    *11               return to GPL
A62E2  MOVB @>70B8,@>8322     pass error code
       B    @A6974            return to GPL interpreter with Cnd bit set
*
*-------------------------------------
* LOADER loads a DF80 tagged object file
*-------------------------------------
A62EC  CLR  @>7020
       SZCB @A6056,15         clear eq bit
       MOV  @>8356,0          name ptr
       BLWP @A6038            DSKLNK
       DATA >0008             for DSRs
       JEQ  A6364             an error occured
       AI   0,-9              PAB ptr
       LI   1,>0200           opcode for "read"
       BLWP @A6024            VSBW
       INC  0                 status/err byte in PAB
       MOV  0,@>702C          save address for later
       MOV  @>7022,7          first free address in cartridge RAM
       MOV  7,5               save it
       CLR  12                compressed flag
       BL   @A6574            get next char
       CI   3,>0001           is it >01?
       JNE  A636C             no
       INC  12                yes: set compressed flag
       CLR  3                 correct tag to >00
       JMP  A6370
 
A632A  CI   3,>0046       |J| is it tag F ?
       JNE  A636C             no
       CLR  2             |F| force end-of-record
 
A6332  BL   @A65C2            read next char (on next record)
       CI   3,>003A           is it : ?
       JNE  A632A
       MOV  @>702C,0      |:|
       DEC  0                 PAB ptr
       LI   1,>0100           opcode for  'close'
       BLWP @A6024            VSBW
       BL   @A6574            call DSR
       MOV  @>7020,0          auto-start address
       JEQ  A6362             none: back to caller
       BL   @A65DA
       JMP  A6364
       MOV  14,@>0016(13)     put return address in caller's R11
       MOV  @>7020,14         get program address
A6362  RTWP                   branch to it with caller's workspace
 
A6364  MOVB 0,*13             pass error code in caller's R0
       SOCB @A6056,15         set eq bit
A636A  RTWP                   tag L jumps here
*
A636C  BL   @A655E            check if tag is valid
A6370  CLR  4
       MOVB @A65F8(3),4       jump offset
       SRL  4,7               in words
       MOV  8,@>702A          save CRC
       BL   @A6530            get a number
       B    @A632A(4)         jump to tag routine
*
A6384  INC  0             |0| module size
       ANDI 0,>FFFE           make it even
       MOV  @>7022,4          first free address in high mem
       A    0,4               is there room enough?
       JOC  A63A2             no: try elsewhere
       C    4,@>7024          passed last free address?
       JH   A63A2             yes: try elsewhere
       MOV  @>7022,5          no: load into high memory
       MOV  4,@>7022          update first free address
       JMP  A63CC
 
A63A2  MOV  @>7026,4          first free address in low mem
       A    0,4               add module size?
       C    4,@>7028          passed last free address
       JH   A63B8             yes: try elsewhere
       MOV  @>7026,5          no: load into low memory
       MOV  4,@>7026          update first free address
       JMP  A63CC
 
A63B8  MOV  @>701C,4          first free address in cartridge RAM
       A    0,4               add module size
       C    4,@>701E          passed last free address?
       JHE  A63DC             yes: error
       MOV  @>701C,5          no: load into cartridge RAM
       MOV  4,@>701C          update first free address
 
A63CC  MOV  5,7               addjust loading ptr
A63CE  LI   9,>0008       |I| skip 8 chars
A63D2  BL   @A65C2            read a byte
       DEC  9
       JNE  A63D2             one more
       JMP  A6332
 
A63DC  LI   0,>0800           error: "memory full"
       JMP  A6364
 
A63E2  A    5,0           |2| add segment address
       MOV  0,@>7020      |1| save autostart address
       JMP  A6332             next tag
 
A63EA  A    0,@>702A      |7| add CRC to calculated CRC
       JEQ  A6332             ok: next tag
A63F0  LI   0,>0B00           error 11
A63F4  JMP  A6364             tag K jumps here
 
A63F6  A    5,0           |A| add segment address
       MOV  0,7           |9| set new loading ptr
       JMP  A6332             next tag
 
A63FC  A    5,0           |C| add segment address
       MOVB 0,*7+         |B| load value into memory
       MOVB @>70D9,*7+        R0 lsb
       JMP  A6332             next tag
 
A6406  A    5,0           |3| add segment address
       BL   @A6502        |4| create entry in symbol table
       MOV  0,0               get link to first ref address
       JEQ  A6466             none: forget that label
A6410  AI   6,>FFF8           previous label in table
       C    6,4               none
       JH   A6446             compare names, solve ref if found, else goto A6410
 
       LI   6,A6FFE           top of symbol table
A641C  AI   6,-8              previous label
       CI   6,A6F06           end of RAM reached?
       JEQ  A6440             yes: undifined label
       C    *4,*6             compare label names
       JNE  A641C
       C    @>0002(4),@>0002(6)
       JNE  A641C
       C    @>0004(4),@>0004(6)
       JNE  A641C
       MOV  @>0006(6),3       found: get its value
       JMP  A645E             solve ref and removed new entry
 
A6440  NEG  *4                set label as undefined
A6442  B    @A6332            read next tag
*
* Solve REF if label already DEFined ptr in R4
* ----------------------------------
*
A6446  C    *4,*6             compare labels
       JNE  A6410
       C    @>0002(4),@>0002(6)
       JNE  A6410
       C    @>0004(4),@>0004(6)
       JNE  A6410
       MOV  @>0006(6),3       found: get its value
A645E  MOV  *0,9              get link to next ref
       MOV  3,*0              update ref
       MOV  9,0               use link as ptr
       JNE  A645E             more
A6466  AI   4,>0008           forget that label
       MOV  4,@>701E          update table bottom (last free address)
       JMP  A6442             to next tag
 
A6470  A    5,0           |5| add segment address
       BL   @A6502        |6| create entry in symbol table
A6476  AI   6,-8              previous label in table
A647A  C    6,4               did we check them all?
       JEQ  A64D0             yes: make sure it does not exist, then next tag
       MOV  *6,10             get first to chars
       JGT  A6484             defined
       NEG  10                undefined, restore initial chars
A6484  C    *4,10             compare names
       JNE  A6476
       C    @>0002(4),@>0002(6)
       JNE  A6476
       C    @>0004(4),@>0004(6)
       JNE  A6476
       MOV  *6,10             found: was it undefined?
       JGT  A64F2             no: error 12
       MOV  @>0006(6),3       yes: get link to next ref address
A64A0  MOV  *3,9              get next link
       MOV  0,*3              replace it with label value
       MOV  9,3               use next link
       JNE  A64A0             more
       MOV  6,9               shift symbol table to remove ref
       S    4,9               number of bytes to shift
       MOV  6,10              source=  undef label)
       AI   10,>0008          dest= next label upwards
       MOV  6,3               source ptr
A64B4  DECT 3
       DECT 10
       MOV  *3,*10            copy 1 word 8 bytes above
       DECT 9
A64BC  JNE  A64B4             more to do
       AI   4,>0008           adjust table bottom ptr
       MOV  4,@>701E          last free address
       JMP  A647A             look for more undefined REFs
 
A64C8  LI   0,>0A00    |DEGH| error code 10: "illegal tag"
       B    @A6364            return with error code in R0 and eq bit set
*
* Make sure label does no exist yet ptr in R4
* ---------------------------------
*
A64D0  LI   6,A6FFE           top of predefined symbol table
A64D4  AI   6,-8              previous label
       CI   6,A6F06
       JEQ  A6442             next tag
       C    *4,*6             compare label names
       JNE  A64D4
       C    @>0002(4),@>0002(6)
       JNE  A64D4
       C    @>0004(4),@>0004(6)
       JNE  A64D4
A64F2  MOV  4,@>0002(13)      found: pass address in caller's R1
       LI   0,>0C00           error 12: "label declared twice"
       B    @A6364            return with error code in R0 and Eq bit set
A64FE  B    @A63DC            to error 8
*
* Create entry in symbol table
* ----------------------------
*
A6502  MOV  11,10
       LI   9,>0006           6 chars per label name
       MOV  @>701E,6          last free address (symbol table bottom)
       AI   6,-8              grow downwards by 1 label
       MOV  6,4               save it
       C    6,@>701C          passed first free address?
       JL   A64FE             yes: error 8
       MOV  6,@>701E          update table bottom
A651C  BL   @A65C2            read 1 char
       MOVB @>70DF,*6+        save it onto table (R3 lsb)
       DEC  9
       JNE  A651C             next char
       MOV  0,*6              save label value
       LI   6,>8000           top of table ptr
       B    *10
*
* Read an integer from file either as 2 bytes or as 4 chars
* -------------------------
*
A6530  MOV  11,10
       CLR  0
       MOV  12,12             compressed?
       JEQ  A6548             no
       BL   @A65C2            yes: read a byte
       MOVB @>70DF,0          save it (R3 lsb)
       BL   @A65C2            read another byte
       A    3,0               make it a word
       B    *10
A6548  LI   9,>0004           make a number out of 4 chars
A654C  BL   @A65C2            read 1 char
       BL   @A655E            decode hex nibble
       SLA  0,4               1 nibble to the left
       A    3,0               add new nibble
       DEC  9
       JNE  A654C             next char
       B    *10
*
* Convert hex nibble to value range 0-9, A-P (for tags)
* ---------------------------
*
A655E  AI   3,>FFD0           substract '0'
       CI   3,>000A           in range 0-9?
       JL   A6572             yes
       AI   3,-7              adjust A-above
       CI   3,>0019           higher than 'P'
       JH   A64C8             yes: error 10
A6572  B    *11
*
* Read next byte (from next record if needed)
* --------------
*
A6574  LWPI >83E0             recall DSR
       LI   0,>7030           ptr to saved values
       MOV  *0+,12            card CRU
       MOV  *0+,9             DSR address
       MOV  *0+,@>8354        name size
       MOV  *0+,@>8356        name ptr
       MOV  *0,1              occurence
       SBO  0                 turn card on
       CB   @>4000,@A6000     make sure it's there
       JNE  A65CE             no valid header
       BL   *9                call DSR
       JMP  A65CE             refused
       SBZ  0                 turn card off
       LWPI >70D8             back to loader's workspace
       MOV  @>702C,0          status/error byte in PAB
       LI   1,>70D9           address of R0 lsb
       LI   2,>0004           load 4 bytes
       BLWP @A6030            VMBR
       SB   0,0
       SRL  0,5               keep only error bits
       JNE  A65D4             an error occured
       SRL  2,8               number of chars (PAB+4)
       MOV  1,0               data buffer address (PAB+2)
       LI   1,>703A           buffer in cartridge RAM
       BLWP @A6030            VMBR: download record
       CLR  8                 reset checksum
 
A65C2  DEC  2                 next byte
       JLT  A6574             no more: load new record
       MOVB *1+,3             get it from cpu buffer
       SRL  3,8               make it a word
       A    3,8               add it to checksum
       B    *11
 
A65CE  LWPI >70D8             back to loader's workspace
       CLR  0                 error code 0
A65D4  SWPB 0
       B    @A6364            pass error code to caller's R0, return with eq bit
*
* Check for undefined labels
* --------------------------
*
A65DA  LI   1,>8008           top of symbol table +1 label
A65DE  AI   1,>FFF8           previous label
       C    @>701E,1          did we reach bottom of table?
       JEQ  A65EE             yes: return with ok
       MOV  *1,0              is this label undefined
       JLT  A65F2             yes: return with error
       JMP  A65DE             keep scanning
A65EE  INCT 11                skip a jump if ok
       B    *11
 
A65F2  LI   0,>0D00           error code 13: "undefined symbol"
       B    *11               return to the jump
*
A65F8  BYTE >2D               tag 0
       BYTE >5D,>5C           tag 1+2
       BYTE >6E,>6F           tag 3+4
       BYTE >A3,>A4           tag 5+6
       BYTE >60,>04           tag 7+8
       BYTE >67,>66           tag 9+A
       BYTE >6A,>69           tag B+C
       BYTE >CF,>CF           tag D+E  error 10
       BYTE >03               tag F
       BYTE >CF,>CF           tag G+H  error 10
       BYTE >52               tag I    skip 8 chars
       BYTE >00               tag J    tag in data word
*                             tags K to P branch to crazy locations!
*
** EPEP       COPY "DSK1.MMR2/S"
      COPY 'MMR2.ASM'
