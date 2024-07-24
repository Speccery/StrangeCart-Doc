# grommy2 README
Erik Piehl (C) 2023-11-19
Project started in 2022.

### version 0.7.21
Updated 2024-07-24 to reflect version 0.7.21. This version fixed the firmware flash command 06, which was broken in earlier versions. The new version still has not been tested much. Main changes:
- Locked GRAM area to address 0x20003000 on the ARM side.
- Command 7: Added execution mode option to command 7 (run ARM code from main loop).
- Command 7: Forces bit 0 of execution address to 1 to ensure marking the code as Thumb code.
- Command 6: Firmware update command 6 fixed. Needs more testing but appears to work.
- If the serial port of the grommy2 is connected to a terminal, some status information can be seen. Added a couple of commands which can be issued with a terminal program.
- Reduced the memory footprint of the firmware, and decided to make the firmware software max size 16 kilobytes. Current size is under 14 kilobytes, with room for additional reduction. The firmware can be pretty easily made smaller by not using the STM32 library code as is, but instead make versions having only the functionality needed by the grommy2.

## grommy2 board introduction
The grommy2 board is a modern replacement for the special GROM chips used by the TI-99/4A home computers. The GROM chips contain most of the operating system of the TI-99/4A and the BASIC interpreter. The GROM chips contain byte code in a language called GPL, explained [here](https://www.unige.ch/medecine/nouspikel/ti99/gpl.htm).

A grommy2 can be used to replace the system GROM chips. The grommy2 enables many different use cases:
- Fixing a TI with defective GROM chip(s)
- Run any of the TI operating system versions, at least as far as the GROMs are concerned. 
- Extend the system GROMs to 8k each, as the grommy2 serves the entire 8K of address space instead of the regular 6K for each chip, enabling additions to the standard GPL code.
- Create your own improved version of the GROM code and run it on the real iron.
- Make the GROM area writable and modify existing GROM contents.
- Store multiple operating system versions.

A couple of special use cases can also be enabled:
- Use grommy2 as 24K extra RAM (from an assembly program)
- Run ARM Cortex M0 code on the grommy2

### GROM memory map with standard GROMs
System GROM memory layout with standard chips below. There are 2k holes between the data areas.
| Address | Data |
| --- | --- |
| 0000..17FF | GROM chip #1 data|
| 1800..1FFF | Chip #1 Dummy data|
| 2000..37FF | GROM #2 data|
| 3800..3FFF | Chip #2 Dummy data|
| 4000..57FF | GROM #3 data|
| 5800..5FFF | Chip #3 Dummy data|

### grommy2 GROM memory map
On the TI-99/4A there are 3 GROM chips on the motherboard. A grommy2 board replaces all three with a single board. Each of the original GROM chips has a capacity of 6 kilobytes, but they occupy a 8k of GROM address space. The topmost 2k of a standard GROM chip is not used and goes wasted. Thus with the standard GROM chips a TI-99/4A computer provides 18k of GROM memory in the bottom 24k of GROM address space, but with the grommy2 the full 24k becomes usable. This enables extensions to GROM code.

| Address | Data |
| --- | --- |
| 0000..1FFF | Entire chip #1 area usable |
| 2000..3FFF | Entire chip #2 area usable |
| 4000..5FEF | Almost whole chip #3 area usable |
| 5FF0..5FFF | grommy2 command interface |

### GROMmy board versions
During the development process I tried multiple different microcontrollers and board configurations. There are currently three different main versions of the GROMmy board. Of these the grommy2 is the main project.
![img](https://content.invisioncic.com/r322239/monthly_2022_10/image.jpeg.4b96d551ca369f0b18d8ebd442ac6819.jpeg)

## grommy2 architecture
The grommy2 board uses the STM32G070KB microcontroller to emulate the GROM chips. The firmware running on the microcontroller responds to the system GROM area.

The microcontroller is a very capable low cost chip. It has 128k of flash memory and 36k of SRAM memory. The chip sports a 32-bit ARM Cortex-M0+ CPU core. On the grommy2 the chip is run at its maximum clock speed of 64MHz.

### Flash ROM usage
The flash ROM usage is at the moment built from four 24k blocks:
- firmware block (size 16k)
- default GROM block (starts from 0x08004000)
- user GROM #1
- user GROM #2
- Unused area, 128k - 16k - 3*24k = 40k

### Serial port
UART1 of the microcontroller is used for some debugging features. It communicates at 115200bps 8N1.
It also supports some commands which can be issued by a terminal program, here functionality as version 0.7.21.
| Command | Function |
| --- | --- |
| s | Show number of characters received by the serial port, and counts of GROM reads and writes. |
| r | Reset bank number to zero (system GROM) and turn off shadow memory. |
| d | Hexdump the beginning of a few key areas of memory |
| l | Flash the LED quickly 10 times |
| xy | Execute code at offset 0x4000 in the GRAM buffer |
| xz | Execute code at offset 0x0000 in the GRAM buffer |
| v | Show version number of the firmware |


### Interrupts
Handling of GROM traffic is interrupt driven, not polled. This makes software development for the ARM core easier. Currently the main loop runs with interrupts enabled and just handles some debug output as well as responses to a few single character long serial port commands.

### Reset
TI-99/4A reset does not show up on the pins of the GROM. Thus the grommy2 state is unaffected by resets of the computer.

## Memory
### Memory banks
The grommy2 provides in total four 24K memory banks covering the system GROM area. One of these is active for reads at a time. The banks stored in flash memory are non-volatile, i.e. they hold their contents even when power is off. The flash memory banks can be reprogrammed in circuit, i.e. while the grommy2 is inside the TI-99/4A.

| Bank | Type | Writable | Description |
| --- | --- | --- | --- | 
| #0 | Flash | Read only | Normal TI-99/4A system GROMs. This is the default bank. |
| #1 | Flash | Read only | User system GROM bank 1. |
| #2 | Flash | Read only | User system GROM bank 2. |
| #3..#7 | - | - | reserved, not present in grommy2 |
| #8 | SRAM | Read/write | GRAM area stored in RAM. By default read only, but writes can be enabled. The RAM area works as a shadow area: when writes are enabled, the written data goes to this RAM, regardless what GROM bank is chosen for reads. |


## Command interface
Commands are implemented by writing a 16 byte string of bytes to GROM space addresses 5FF0..5FFF. The writes need to be continuous, if a GROM read operation is done or GROM write operation to another address the command is ignored. 

### Return values
**The return values have not been tested much.** After a command is run, the status is returned in the same area, i.e. at 5FF0 in the GROM space.Basically the format is as follows:
- 5FF0 & 5FF1: The ascii characters 'OK'
- 5FF2 "main" return code, typically 1 for success, 0 for failure. **untested**
- 5FF3 Currently active ROM bank (0,1,2 or 8)
- 5FF4 GRAM shadow mode (0 or 1)

The version query command returns nearly 16 bytes as follows, from 5FF0 onwards:
- 5FF0 & 5FF1: 'OK'
- 5FF2 Return code
- 5FF3 Currently active ROM bank (0,1,2 or 8)
- 5FF4 GRAM shadow mode (0 or 1)
- 5FF8 major version
- 5FF9 minor version
- 5FFA build number (two digits)
- 5FFB Year of build (last two digits,i.e. 23 for 2023)
- 5FFC Month of build (1..12)
- 5FFD Day of month of build (1..31)
Setting of these values is not yet automated.

### GPL command example code
In the GPL language, a command can simply be sent to the grommy2 like this:
```
       MOVE  >0010,@>8340,G@>5FF0    Copy PAD @8340 to GRAM @5FF0.
```

I have created a special version of the Easybug debugger, which is part of the mini memory cartridge. In that code the GPL code to send commands goes like this:
```
       MOVE  >0030,@>8340,V@>100D         save >8340-8370 to VDP RAM
       MOVE  >0010,G@GROMMY_DAT,@>8340  place parameter string in PAD
       ST    @>839A,@>8340                Copy command byte
       ST    @>839A,@>8341                The second byte is its complement
       XOR   >FF,@>8341
       ST    @>839B,@>8342                Copy p2.
       MOVE  >0010,@>8340,G@>5FF0         Copy from PAD @8340 to GRAM @5FF0. 
       MOVE  >0030,V@>100D,@>8340         restore >8340-8370
       B     G@G70E5          wait for another command
GROMMY_DAT 
       DATA   >00FF,>003F,>0000,>0000
       TEXT 'EPGROMMY'
```
In the above a section of scratch pad RAM is made available by storing 48 bytes of scratchpad to VDP RAM temporarily, then 16 bytes are copied from Easybug GROM to scractchpad. The memory locations >839A and >839B contain two parameters: the command byte and parameter byte "p2". The command and its complement are written, then followed by the p2 parameter. After that the whole command is sent to the grommy2 to do it's thing.

Note that this code copies to VDP RAM 48 bytes, but only 16 bytes are really needed. I was testing with some assembler code running from the scratchpad - a pattern used by Easybug quite a bit - but then realize a single GPL instruction can be used to issue the whole 16 byte command.

### Assembler example code
The following code issues a grommy2 command from assembler. Should be correct but I did most of the testing with GPL code. The 16 bytes of command bytes are assumed to be at >8340.
```
    LI 1,>5FF0      * GROM Destination Address
    LI 2,>9C02      * GROM Addr reg
* write GROM address    
    MOVB 1,*2
    SWPB 1
    MOVB 1,*2
* Now address should be set, copy data
    LI  3,>8340     * Source where the data to write to GROM is
    DECT 2          * point to GROM data register
!   MOVB *3+,*2     * Move a byte to GROM
    CI  3,>8350     * 16 bytes written?
    JNE -!          * No, loop back to MOVB
    B   *11         * Return
```

### Command definitions
These are the supported commands. Note that the command byte must be issued twice, so that the 2nd byte is the complement. For example for command #1 (choose GROM bank) which takes on parameter, the command entry would be as follows:
```
01 -> 5FF0 Command byte select bank
FE -> 5FF1 Complement of 01 (i.e. 01 XOR FF)
p2 -> 5FF2 p2 specifies the bank (0,1,2 or 8)
p3 -> 5FF3 p3 Not used for this command
00, 00, 00, 00 -> 5FF4..5FF7 not used but must be written
'EPGROMMY' -> 5FF8..5FFF Command id string (8 bytes in ASCII)
``````
Once the final byte is written, the Y of the string, the command is checked and executed if valid.

Below p4..p7 are additional paramaters, which mostly are zero and marked as 0* if all of them a zero. They are followed with the string 'EPGROMMY'.
| Command | p2 | p3 | p4 | p5..p7 | Description | Tested |
| --- | --- | --- | --- | --- | --- | --- |
| 00 FF | 00 | 00 | 0 | 0* | Query grommy2 version | Yes |
| 01 FE | p2 | 00 | 0 | 0* | Select GROM read bank p2=0,1,2 or 8 | Yes |
| 02 FD | p2 | 00 | 0 | 0* | Copy bank p2=0,1 or 2 to GRAM i.e. bank 8 | Yes |
| 03 FC | p2 | 00 | 0 | 0* | Shadow RAM mode on (p2=1) or off (p2=0). When shadow RAM is on, writes to GROM area go to the shadow RAM i.e. bank 8 | Yes |
| 04 FB | p2 | 3F | 0 | 0* | Program flash bank 1 (p2=1) or flash bank 2 (p2=2) with the contents of GRAM i.e. bank 8. p3 is a bit mask which chooses which 4k pages are programmed. The value of 3F chooses all six 4k pages making up the 24k area. Bit 0 (LSB) controls writes to 0..FFF, bit 1 to 1000..1FFF and so on. | Yes |
| 05 FA | p2 | 00 | 0 | 0* | Compare GRAM with flash bank 0,1 or 2 depending p2 | No |
| 06 F9 | 12 | 34 | 0 | 0* | Program new firmware with the contents of GRAM i.e. bank 8 | Yes |
| 07 F8 | lo | hi | M | 0* | Execute contents of GRAM from offset hi:lo as ARM Cortex M0 code. p4 chooses execution mode, when set to 0 the code is executed immediately, same as for older firmware versions. Version 0.7.21 allows this to be set to 1, in which case the code will not be executed immediately (from interrupt context) but rather from the main program outside of interrupt context. If execution is done outside of interrupt context, it is not possible to set return value reliably. | Yes |

### Access from modified version of Easybug
I have a version of the Mini Memory cartridge which has some modifications:
- The G command now supports writes to GROM area.
- New command X, followed by a hexadecimal 16 bit value, issues a grommy2 command. The high byte is the command and the low byte is parameter p2.

#### Example Easybug commands
| Cmd | Description |
| --- | --- |
| X0000 | get version |
| X0100 | choose bank for reads , 00 in this case |
| X0200 | copy bank 00 to RAM |
| X0301 | set RAM shadow mode on |
| X0108 | select RAM bank for reads |
| X0401 | burn RAM bank to flash bank 1 |
| X0201 | copy bank 01 to RAM |

## Further reading
The GROMmy2 board is discussed at the 
[AtariAge forums](https://forums.atariage.com/topic/341084-ti-grommy-the-system-grom-replacement/).



