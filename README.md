# StrangeCart-Doc
StrangeCart project public documentation.

Please see the Wiki for more information.

## Discussion thread
The StrangeCart project started way back in May 2020, when I started this discussion thread:

https://atariage.com/forums/topic/306889-strangecart/

## What is the StrangeCart
The project started as an experiment for the TI-99/4A home computer, first released in 1979: I wanted to both create a hardware cartridge for the TI-99/4A and wanted to make it simultaneously super flexible but also electronics wise very simple, essentially a single chip cartridge. The enabling technology for this idea was to use a relatively fast ARM based microcontroller (MCU) as the main chip, and to implement cartridge functionality in software.

Due to the software implementation, the cartridge and implement virtually all types of TI-99/4A cartridges in software, including the following features:
- ROM memory support
- GROM memory support (this is a TI specific slow but cheap at the time ROM chip)
- Banked ROM memory support
- Combined ROM and RAM support
- System GROM override support

In addition to those features, which existed also back in the hayday of the TI-99/4A, in the early 1980s - but not in a single cartridge, the StrangeCart also implements features which I don't think have been implemented before. The become possible due to coprosessing support, enabling the StrangeCart to run software in parallel to the TI-99/4A's main CPU. As examples of this, there are currently implemented:
- A couple of simple demos, running on the ARM but displaying all output on the TI's screen
- On board BASIC interpreter, implementing a most of the features of the original TI BASIC. Instead of running on the 3MHz CPU of the TI-99/4A in a double interpreter setup, the Basic is implemented in C++ running natively on the ARM. This makes the Basic up to a 1000 times faster from the original TI Basic
- Emulator of the TI-99/4A running on the StrangeCart. Yes, this is a bit strange. The point is that the StrangeCart can run TI software under emulation faster than the original TI-99/4A. At the time of writing the emulator works, but since input and output is not yet integrated with the home computer, this is still work in progress.


## Technical background
This is what I wrote in the opening message at the AtariAge thread: *The microcontroller has two ARM processor cores: one Cortex M0+ core and one Cortex M4F core. I am running them at 96 MHz. In my opinion the really cool thing about this setup and my proof-of-concept software is that the less powerful M0+ core alone is sufficient to serve the bus of the TI-99/4A in real time, leaving the M4F core free for other things. The two cores can communicate via shared memory.*

*The microcontroller chip has 256K of Flash memory and 192K of RAM. Due to these capabilities the board has a bunch of extension headers: if one brings in extra address lines from the expansion connector, the StrangeCart could also implement memory expansion and mass storage expansion. I have provided header pads for the signals which are only present on the expansion connector.*
 
*The most difficult bit in this has been setting up the software properly so that both cores operate properly and the toolchain works. These chips are very complex, with a huge amount of on-chip peripherals. Still, the "bus server" program running on the M0 core is less than 4K bytes in size. I have setup things so that the M4F is the master processor, it configures everything and then boots the M0. The M0 is running from RAM for maximum performance, with interrupts disabled.*

I have made multiple board revisions after the initial prototype, and the current version (StrangeCart V2 rev B) is a two chip design: in addition to the MCU I have added a 16 megabyte serial flash chip as a mass storage chip.

![Architecture picture](https://github.com/Speccery/StrangeCart-Doc/blob/main/StrangeCart%20Architecture.jpg)
