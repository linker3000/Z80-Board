# Z80-Board
A Z80 computer wirewrapped on perfboard.

*This is a work in progress and details are being regularly updated.*

The wirewrapping technique uses standard IC sockets and PCB header pins, so the components and wiring are on the same side of the board; this has many benefits:

* It's easier to see what you are connecting together.
* It creates a very neat and compact layout. 
* Reworking is quicker and easier.
* No messy 'mat of wires' on the underside.
* Wirewrapping IC sockets are becoming expensive and harder to source. 

The construction technique can be seen in the photos: rows of header pins are placed alongside each IC socket and the two are solder-bridged on the copper side. Using perfboard, rather than stripboard, means there's no track cutting needed.

*These notes give a very generalised view of the board's construction; an experienced constructor will be able to follow along, however this is a personal build and there was never an intention to write-up full project construction notes for mass replication.*

![Image](NKZ80montage-small.png)

This Z80 board was inspired by Grant Searle's "9-chip" design - but using a GAL for most of the glue logic takes the chip count to 6! The plan was to build the board in three stages:

1) Get the system up and running with ROM BASIC only.

2) Wire up an 8-bit I/O port with controllable LEDs and sense/switch inputs.

3) Wire up a Compact flash-IDE adaptor to run CP/M from 'disk' and add an onboard 5V regulator & power socket.

The first pics show the board at stage 1.

For more details of what the board can do, and how to setup the compact flash card and CP/M, see Grant's original documentation:

http://searle.hostei.com/grant/cpm/index.html

In the early stages the board was powered via the USB-to-TTL serial adapter, drawing a current of about 170mA - which is probably pushing the poor thing a tad. My adapter often reset when plugged in; probably due to the inrush current. Substituting CMOS parts for the CPU and SIO will reduce supply current; using a CMOS Z80 brings the load down to 100mA.

If you use a discrete 5V supply for the board, remember to keep the GND/0V line of the USB-TTL adapter connected but disconnect its 5V line - do not try to use two power sources at the same time.

IMPORTANT: Note the jumper on SIO pin 18 (CTSA). This pin must be grounded if PORT A is not in use or the line is not being driven. If not, PORT B won't function and you'll get no terminal. 

More pictures here: https://imgur.com/a/rGRR2NM

# Schematic

![Image](schematic.png)

# Components

The core parts are:

* Mostek MK3880N-4 (4Mhz Z80 CPU - NMOS)
* Zilog Z80SIO/0 (Z8440AB1 - NMOS)
* TMS27C128-25 EPROM
* HM628128 1M (128Kx8) SRAM (half-used, as in the original design)
* 74HCT00 quad NAND gate - see note below 
* Lattice GAL20V8B-25LP - programmed using a TL866II device programmer/tester
* Each chip is decoupled by a 100nF ceramic capacitor
* Lots of male header pins for the wirewrapping
* Indicator LEDs and resistors (see schematic)
* IC sockets
* See the schematic for other parts e.g.: the reset circuit, other resistors and connectors. 

NAND gate: This should be a 74HCT part (or can also be a 74AC if you are using a CMOS CPU and SIO). Other bipolar types (74LS, 74F etc.) won't oscillate.

The GAL needs programming - I used the low-cost TL866 'universal programmer' (IMPORTANT: Untick 'Encrypt Ch' otherwise the GAL may not program correctly). The .JED file is ready to upload to the programmer. If you want to edit/change the source .PLD file, you will need a copy of WinCUPL (free from https://www.microchip.com/design-centers/programmable-logic/spld-cpld/tools/software/wincupl) or another CUPL editor.

The GAL chip was later changed to a 22V10 part to provide select pins for the I/O port - see text.

Because 4Mhz parts were used, this board is fitted with a 3.6864Mhz crystal and the serial interface runs at 57,600BPS. If faster spec parts are used then the board should run at the original design clock speed of 7.3728Mhz, with a serial speed of 115,200BPS. You might get away with overclocking a 4Mhz Z80 CPU (YMMV), but the SIO chips are more fussy; a 6Mhz part is apparently OK at the faster speed, but a 4Mhz one is not likely to be happy. 

# I/O port

The original I/O port design is very similar to the digital I/O port of the RC2014 Z80: https://rc2014.co.uk/modules/digital-io/; because of this, I have not put a separate schematic for it here - but see the note immediately below.

**Note:** (02-Sep-2018) The port for this board has been reworked and the design has changed; I will update these notes later. If anyone really is following this board design and building their own, or using the schematic as the basis of a project, contact me for details. The RC2014 port design will work, but it overlaps with the SIO chip at address $00 and can affect operation of serial port A. The new port is at address $08 and is controlled from the GAL (which is now a 22V10) so the 74x138 decoder is not needed, and only 2 diodes are used for address control (on one input of the GAL).

The (original) port comprises the following:

* 74HCT138 3-to-8 decoder. Not used in the new design.
* 74LS245 TTL octal bus transceiver 
* 74F374 octal D-type flip flop driving the LEDs (74LS or HCT374 would be fine)
* 6 x 1N4148 signal diodes as an address decoding OR gate. Only 2 used in the new design.
* 8 x green LEDs
* 8 x 390 ohm resistors
* 8 x 2K2 resistors
* 1 x 10K resistor
* 3 x 100nF ceramic decoupling capacitor. Only 2 used in the new design.

# Other parts

### Compact Flash Adaptor

The CF-IDE adaptor (with 40-pin connector) was bought off eBay.

### Voltage regulator

The switching voltage regulator is a Murata OKI-78SR-5/1.5-W36-C. These units are pin compatible with the classic 7805 linear regulators, but operate at around 90% efficency and can supply up to 1.5A without needing a heatsink; saving precious board space as well as being energy efficient. The regulators are available from RS Components, Farnell/Element 14, Digikey and Mouser.

![Image](z80-6.jpg)

There's a 15uF 35V tantalum decoupling capacitor on the input side of the regulator and a 100uF 16V one on the output; these values are not too critical and low ESR electrolytics of around the same capacitance and voltage could be used. The voltage rating of the input capacitor allows for powering the board from a 19-20V laptop adaptor. The Murata regulator can take up to 36V  on its input, but if you decide to use anything close to that voltage, the input capacitor should be a 50V or 63V type. 

The diode in the voltage regulator input path was originally a 1A part (1N4001), whereas the Murata regulator can supply up to 1.5A (although it limits short circuit current to 10mA); in effect, the diode was used as a safety fuse as well as for polarity protection. Later, the diode was replaced with a 3A part eg: 1N54xx. 

If you do use a 7805 linear regulator it will likely need a suitable heatsink, especially if using a supply voltage above 9V. The decoupling capacitor requirements are also different from the Murata part, so check the data sheet. 7805 linear regulators have a short circuit current limit of around 250-400mA, depending on manufacturer and exact model; this will be enough to damage parts or make things get hot under fault conditions, so you may want to fit a suitable (1A) fuse or polyfuse if you think your board's going to be treated roughly.

Due to the dropout voltage of the regulator (switched or linear), plus the protection diode drop, the minimum board input voltage is around 8-9V. The total current consumption with the CF card in place is 175mA @ 8V, rising to around 230mA with the I/O port fitted.  

### USB-Serial adaptor notes

The resistors between the USB-Serial adaptor and the SIO chip reduce the risk of damaging something if the handshake and signal pins are connected but there's no power to the board. Grant's board used 2K7 resistors and this one originally had 1K parts; those worked fine with an FTDI (probably clone) adaptor (left in picture), but the value had to be reduced to 510R for a CH340G-based one (right in picture) to make the port work.

![Image](serial-usb.jpg)

### More Pictures

A view showing the decoupling caps (the ones for the 40-pin chips are under the sockets), a closeup of the wirewrapping, and then with the I/O port nearly done (LEDs working fine, but 74LS245 input port wiring missing).

![Image](z80-3.jpg)

![Image](z80-4.jpg)

![Image](z80-5.jpg)

Finally (below), here's the nearly-complete board. The I/O port chips are now controlled by the GAL22V10 and so the LS138 address decoder (empty socket at the top of the board) is not needed.

![Image](z80-7.jpg)

---
## Application Software

![Image](cpm.png)
![Image](zork1a.png).
![Image](wordstar.png)

---

# Bonus Programs

SUPER STARTREK

Modified to work on Microsoft Z80 BASIC Ver 4.7b (which boots from ROM). The classic SUPER STARTREK from 1978. The main changes were to restrict line lengths and/or split long lines into multiples, re-writing the conditional statements accordingly, and to remove the print-formatting 'USING' command, which is not supported. 

If you are after a version that runs on mbasic on CP/M, see: https://github.com/RC2014Z80/RC2014/blob/master/BASIC-Programs/Super%20Startrek/startrek.bas

![Image](trek1-800.jpg)

The main program is STARTREK.BAS. TRKINST.BAS prints the instructions and in the original program was chain-loaded upon request,  but that feature has not been implemented so it's best to just read the source if you need guidance.

MAZE

Draws an ASCII maze (eventually, for big ones!)

BUNNY

ASCII bunny (well, 'Rabbit' now)

ELIZA

Early AI - Let Eliza sort out your troubles (not to be taken seriously)

NKLED2.PAS

If you implement the simple I/O port, this program controls the LEDs. Written for Turbo Pascal 3 on CP/M, so you'll need to install that! 

---

All the above code loads via Tera Term using its copy-and-paste feature or by using Grant Searle's file uploader for CP/M: http://searle.hostei.com/grant/cpm/index.html#InstallingApplications 

Let me know if anything needs further modification...and enjoy some retro computing!


