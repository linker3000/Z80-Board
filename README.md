# Z80-Board
Z80 computer wirewrapped on perfboard

![Image](NKZ80montage-small.png)

This Z80 board was inspired by Grant Searle's "9-chip" design - but using a GAL for most of the glue logic takes the chip count to 6! This board does not yet have the compact flash/IDE interface fitted. For more details of what the board can do, see Grant's original documentation:

Original inspiration: http://searle.hostei.com/grant/cpm/index.html

More pictures here: https://imgur.com/a/rGRR2NM

# Schematic

![Image](schematic.png)

# Components

These parts were used for initial testing:

* Mostek MK3880N-4 (4Mhz Z80 CPU - NMOS)
* Zilog Z80SIO/0 (Z8440AB1 - NMOS)
* TMS27C128-25 EPROM
* HM628128 1M (128Kx8) SRAM ('half-used' as in the original design - probably because the part is cheap or was to hand)
* 74HCT00 Quad NAND gate - this MUST be an 74HCT part; the clock circuit is not likely to work with anything else (74LS, HC etc.)
* Lattice GAL20V8B-25LP - programmed using a TL866II device prorammer/tester

The board in the photo is powered via the USB-to-TTL adapter, drawing a current of about 170mA - which is probably pushing the poor adapter a tad. Subtituting CMOS parts for the CPU and SIO will reduce supply current; using a CMOS Z80 brings the load down to 100mA.

If you choose (probably somewhat wisely) to use a separate 5V supply for the board, remember to keep the GND/0V line of the USB-TTL adapter connected, but disconnect its 5V line - do not try to use two power sources at the same time.

You may find that the USB-TTL adapter resets when plugged into the board; this seems to be due to the inrush current. 

Because 4Mhz parts were used to test the design, this board is fitted with a 3.6864Mhz crystal and the serial interface runs at 57,600BPS. If faster spec parts are used then the board should run at the original clock speed of 7.3728Mhz, with a serial speed of 115,200BPS. You might get away with overclocking a 4Mhz Z80 CPU (for a while at least!), but the SIO chips are more fussy. 

# Bonus Game

Also in the repo is the classic SUPER STARTREK from 1978, modified to run on this platform. The major changes were to restrict line lengths to below 80 characters and to remove the print-formatting 'USING' command, which is not supported. Most changes involved splitting long lines into multiples and re-writing the conditional statements accordingly.

The main program is STARTREK.BAS. TRKINST.BAS prints the instructions and in the original program was chain-loaded upon request,  but that feature has not been implemented so it's best to just read the source if you need guidance.

The code loads via Tera Term using its copy-and-paste feature. PuTTY causes buffer overflows.

Let me know if anything needs further modification...and enjoy some retro gaming!
