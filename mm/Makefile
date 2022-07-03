# EP 2021-08-07 created this makefile to build the mm_strange.bin module.
# this is my mini memory module with some extensions.
# EP 2021-10-31 Added layout.xml file to support loading to js99er.net and
# now this creates strange.rpk module.

strange.rpk: mmg.gbc mmr.bin layout.xml
	zip strange.rpk layout.xml mmr.bin mmg.gbc

mm_strange.bin: mmg.gbc mmr.bin
	dd if=/dev/zero of=mm_strange.bin bs=1 count=16384
	dd if=mmr.bin of=mm_strange.bin conv=notrunc bs=1
	dd if=mmg.gbc of=mm_strange.bin conv=notrunc bs=1 seek=8192


mmg.gbc: mmg.gpl mmg2.gpl mmg3.gpl strange.gpl Makefile
	~/bin/xga99.py --aorg 0x6000 mmg.gpl -L mmg.lst
	# Make it 8k in length
	dd if=/dev/zero of=mmg2.gbc bs=1 count=8192
	dd if=mmg.gbc of=mmg2.gbc conv=notrunc
	rm mmg.gbc
	mv mmg2.gbc mmg.gbc

mmr.bin: mmr.asm mmr2.asm Makefile
	# the flag -q is for quieting down the warnings
	~/bin/xas99.py -q -b -a 0x6000 mmr.asm -L mmr.lst
	# would be good here to check that the file size is indeed 4k
	dd if=/dev/zero of=mmr2.bin bs=1 count=8192
	dd if=mmr.bin of=mmr2.bin conv=notrunc 
	rm mmr.bin
	mv mmr2.bin mmr.bin

clean:
	rm -f mmr.bin *.lst *.obj mm_strange.bin *.gbc