DOSbian Setup Script
by ImpendingDisaster

====================
   Preamble
====================

This started with me wanted to play DOS games on a laptop.
While it is certainly possible to do this with real 486-and-older
hardware, there is a lot of effort necessary to acquire the right
hardware and we live in a world where there are suitable alternatives
in software that can run perfectly well on inexpensive refurbished
modern devices.

I did this as a personal project but I figured I could document everything
and turn it into a script that could be easily run by someone who knows
less than me about setting up and building the right packages to have a
great emulated DOS experience.

====================
   Stated Goal
====================

The purpose of this script is to turn a BLANK laptop or desktop into a
dedicated DOS emulation machine after having installed a fresh Debian Stretch.

====================
   Installation
====================

DEBIAN SETUP

You have to download and prepare media with the Debian Stretch NETINST image.
https://www.debian.org/distrib/netinst
Choose the appropriate image for your computer, usually amd64 for modern 
machines but you may need to use i386 for a really old computer but keep in mind
that I did not test this script with that image.
We use the NETINST image as it is very thin so we have a clean setup with which
to work.
Install using the "Install" option and not the "Graphical Install" option.

When presented with those options, deselect the "Debian Desktop Environment" and
"Print server" options as we won't be needing them.

DOSBIAN SETUP

1. Log in as root

2. Get the dosbian-setup scripts
   a) (wget method here)
   b) (git method here)

3. If you can, ensure your MT-32 ROM files are in /root/mt32-rom-data as the
   script expects.
   
4. Run the following command to make the scripts executable:
   chmod +x dosbian-setup.sh dosbian-preboot.sh

5. Run the dosbian-preboot.sh script
   ./dosbian-preboot.sh

The script will do the following:
   1) Check if you have the MT-32 roms available
   2) Installs "sudo" which lets us manage privileges much better
   3) Adds your unprivileged user to the "sudo" group, effectively making them
      an Administrator
   4) Sets that user to automatically log in
   4) Sets that user to automatically launch the debian-setup.sh script after
      rebooting

The debian-setup.sh script will take care of the rest. Your computer will
automatically reboot at the end of the process and will henceforth automatcally
logon as the "dosbox" user which is set to launch into DOSBox (via X Window).

====================
   Software
====================

To start, I chose Debian as my starting point as I am more comfortable with it,
having used it when I was experimenting with Wine and subsequenly using
Raspbian for other projects.

More specifically, these scripts use Debian Stretch but hopefully they will
stand the test of time.

The key component of the emulated DOS environment is DOSBox, a popular DOS
emulator with many features that would be desirable on a "fast" device, such
as CPU cycle limits so you can slow down your device if a game runs too fast.
It also offers nice options for display postprocessing, support for emulated
SoundBlaster and Gravis Ultrasound.

https://www.dosbox.com/

We have to build DOSBox from source as the package available in the Debian repo
is 0.74 and is missing a very nice dynamic recompiler available in 0.74-2

For MIDI support, we are installing TiMidity, and the FluidG3 soundfont.
I chose TiMidity because the popular alternative, FluidSynth, did not seem
to have the right levels for all instruments and sounded strange. Thankfully
we can get TiMidity and the FluidG3 soundfont from the Debian repo. The FluidG3
soundfont sounds very nice with very high-quality instrument samples. If we
need OPL3, there is a soundfont avilable but we can also choose SB16 to take
over music in most cases.

We are also installing a second MIDI handler, called Munt, which emulates the
Roland MT-32 (and CM-32L which I have not configured). While the emulator will
be installed by the script, sadly, you will have to acquire some required files
yourself as they may not be completely legal to distribute:
(MT32_CONTROL.ROM and MT32_PCM.ROM for MT-32 emulation, or
CM32L_CONTROL.ROM and CM32L_PCM.ROM for CM-32L emulation)
The script will automatically install them if they are in the /root directory
in a subdirectory called "mt32-rom-data".

https://sourceforge.net/projects/munt/

