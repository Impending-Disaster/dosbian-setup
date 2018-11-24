#!/bin/sh
SCREENRESOLUTION="1024x768"

## REMOVE ROOT SCRIPT AUTOMATION
mv profile.bak .profile

## DOWNLOAD THE DOSBOX AND MUNT PACKAGES
## THIS DOUBLES AS A 'WAIT FOR NETWORK'
echo DOSbian setup will begin shortly
until [ -f dosbox-0.74-2.tar.gz ]; do
	echo Attempting to download DOSBOX, press CTRL+C to abort
	wget https://sourceforge.net/projects/dosbox/files/dosbox/0.74-2/dosbox-0.74-2.tar.gz
	sleep 2
done

until [ -f munt_2_3_0.tar.gz ]; do
	echo Attempting to download MUNT, press CTRL+C to abort
	wget https://github.com/munt/munt/archive/munt_2_3_0.tar.gz
	sleep 2
done

until [ -f FD12FLOPPY.zip ]; do
	echo Attempting to download FREEDOS, press CTRL+C to abort
	wget www.ibiblio.org/pub/micro/pc-stuff/freedos/files/distributions/1.2/FD12FLOPPY.zip
	sleep 2
done

## INSTALLING THE BASE UTILITIES WE'LL NEED
sudo apt-get install -y alsa-utils pulseaudio timidity fluid-soundfont-gm zip unzip pmount rsync

## DISABLE TIMIDITY BECAUSE IT HAS TO RUN IN USER-MODE WITH PULSEAUDIO
sudo systemctl disable timidity

## SET THE TIMIDITY SOUNDFONT TO FLUIDR3 BECAUSE IT'S AWESOME
sudo sed -i 's/source \/etc\/timidity\/freepats.cfg/#source \/etc\/timidity\/freepats.cfg/' /etc/timidity/timidity.cfg
sudo sed -i 's/#source \/etc\/timidity\/fluidr3_gm.cfg/source \/etc\/timidity\/fluidr3_gm.cfg/' /etc/timidity/timidity.cfg

## MUNT 2.3.0 INSTALL
sudo apt-get install -y build-essential cmake portaudio19-dev libx11-dev libxt-dev libxpm-dev libglib2.0-dev
if [ ! -f munt_2_3_0.tar.gz ]; then
	echo MUNT source archive is missing, aborting
	exit 1
fi

tar -xzf munt_2_3_0.tar.gz
mkdir munt-build
cd munt-build
cmake -DCMAKE_BUILD_TYPE=Release -Dmunt_WITH_MT32EMU_QT:BOOL=OFF ../munt-munt_2_3_0
make -j 4
sudo make install
cd ../munt-munt_2_3_0/mt32emu_alsadrv
make
sudo make install

## IF THE MT32 ROM DATA IS PRESENT IN THE HOME DIRECTORY, COPY IT TO /USR/SHARE
if [ -d $HOME/mt32-rom-data ]; then
	sudo cp -r $HOME/mt32-rom-data /usr/share/
fi

cd ~

## DOSBOX 0.74-2 INSTALL
sudo apt-get install -y libsdl1.2-dev libsdl-sound1.2-dev
if [ ! -f dosbox-0.74-2.tar.gz ]; then
	echo DOSBOX source archive is missing, aborting
	exit 1
fi
tar -xzf dosbox-0.74-2.tar.gz
cd dosbox-0.74-2
./configure
make
sudo make install

cd ~

## INSTALL XORG AS A DOSBOX LAUNCH REQUIREMENT
sudo apt-get install -y xorg

## USER CREATION AND CONFIGURATION
sudo useradd -G cdrom,floppy,audio,input,dip,video,plugdev,netdev,bluetooth -s /bin/bash dosbox
sudo mkdir /home/dosbox
sudo mkdir /home/dosbox/dos_root
echo Enter the dosbox user password:
sudo passwd dosbox

## SET UP SUDOERS SO DOSBOX CAN SHUTDOWN/RESTART
sudo sed -i '/root/ a dosbox	ALL=(ALL) NOPASSWD: /sbin/shutdown, /sbin/reboot, /sbin/poweroff' /etc/sudoers

## SET UP DOSBOX AUTOLOGIN
sudo sed -i "s/noclear\ -a\ $USER/noclear\ -a\ dosbox/" /lib/systemd/system/getty@.service

## SET UP FREEDOS BINARIES
## IT HAS A GOOD SET OF UTILITIES WE CAN USE, LIKE EDIT
if [ -f FD12FLOPPY.zip ]; then
	unzip FD12FLOPPY.zip
	mkdir floppy
	sudo mount -o loop FLOPPY.img floppy
	sudo cp -r floppy/FDSETUP/BIN /home/dosbox/dos_root/FREEDOS
	sudo umount floppy
fi

## FIX OWNERSHIP OF PROFILE ITEMS
## WE DO IT ONCE HERE TO MAKE THE SUDO DOSBOX COMMAND WORK AND ONCE MORE AT THE END
sudo chown -R dosbox:dosbox /home/dosbox

## ATTEMPT TO LAUNCH DOSBOX AND FAIL
## IT WILL GENERATE THE DOSBOX CONFIG FILE
sudo -u dosbox dosbox

sudo chown -R $USER:$USER /home/dosbox

## USER PROFILE CONFIGURATION
## WE ARE STARTING MIDI PROVIDERS IN USER DAEMON MODE
## AND THEN CHECKING TO MAKE SURE THEY ARE PLUGGED INTO ALSA
PROFILETEXT="
echo Starting DOSbox, press CTRL+C to cancel and escape to shell

sleep 5

echo Checking for an attached storage device

pmount /dev/sdb1

if [ -d /media/sdb1 ]; then
	echo Attached storage device found, checking for dos_root directory
	if [ -d /media/sdb1/dos_root ]; then
		echo Found dos_root on attached device, copying files now...
		rsync -ruhv /media/sdb1/dos_root/ /home/dosbox/dos_root/
		pumount /dev/sdb1
		sleep 5
		echo Copy complete! You can now remove your attached storage device.
	else
		echo No dos_root found on attached device.
		pumount /dev/sdb1
		sleep 5
		echo You can now remove your attached storage device.
	fi
else
	echo No attached storage device found.
fi

sleep 5

timidity -iAD -Os &

until [[ -n \"\$(aconnect -o | grep 128\:\ \'TiMidity)\" ]]; do
	echo WAITING FOR TIMIDITY
	sleep 1
done

if [ -f /usr/share/mt32-rom-data/MT32_CONTROL.ROM ] && [ -f /usr/share/mt32-rom-data/MT32_PCM.ROM ]; then
	mt32d -i 12 &

	until [[ -n \"\$(aconnect -o | grep 129\:\ \'MT-32)\" ]]; do
		echo WAITING FOR MUNT
		sleep 1
	done
fi

startx

clear

sudo shutdown now"
echo "$PROFILETEXT" >> /home/dosbox/.profile

## CONFIGURE XORG TO LAUNCH DOSBOX ON START
echo dosbox > /home/dosbox/.xsession

if [ -f /home/dosbox/.dosbox/dosbox-0.74-2.conf ]; then
	## TWEAK DOSBOX CONFIGURATION
	sed -i 's/fullscreen=false/fullscreen=true/' /home/dosbox/.dosbox/dosbox-0.74-2.conf
	sed -i "s/fullresolution=original/fullresolution=$SCREENRESOLUTION/" /home/dosbox/.dosbox/dosbox-0.74-2.conf
	sed -i 's/output=surface/output=openglnb/' /home/dosbox/.dosbox/dosbox-0.74-2.conf
	sed -i 's/aspect=false/aspect=true/' /home/dosbox/.dosbox/dosbox-0.74-2.conf
	sed -i 's/core=auto/core=dynamic/' /home/dosbox/.dosbox/dosbox-0.74-2.conf
	## UNSAFE SED FOR THE MIDICONFIG BECAUSE I DON'T KNOW HOW TO EOL
	sed -i 's/midiconfig=/midiconfig=128:0/' /home/dosbox/.dosbox/dosbox-0.74-2.conf
	
	## TWEAK AUTOEXEC PARAMS IN DOSBOX CONFIG FILE
	DOSBOXTEXT="
@ECHO OFF
mount C ~/dos_root > NUL
C:
AUTOEXEC.BAT
"
	echo "$DOSBOXTEXT" >> /home/dosbox/.dosbox/dosbox-0.74-2.conf
else
	echo The DOSBOX configuration file is missing
	echo There were probably DOSBOX build/install errors
	echo or DOSBOX failed to fake-launch to create the config
	echo The script will exit now to prevent your system from rebooting into DOSBOX so you can review
	exit 1
fi

## SET UP SOME FUN DOSBIAN SCRIPTS
mkdir /home/dosbox/dos_root/DOSBIAN

## SETTING UP SOME USEFUL BATCH FILES
## FIRST AN AUTOEXEC.BAT FILE SO WE CAN HANDLE OUR DEFAULTS FROM WITHIN DOSBOX
AUTOEXECTEXT="
PATH=%PATH%;C:\FREEDOS;C:\DOSBIAN
DEFAULTS.BAT
"
echo "$AUTOEXECTEXT" > /home/dosbox/dos_root/AUTOEXEC.BAT

## BATCH FILE TO CHANGE TO THE TIMIDITY PROVIDER
TIMIDITYTEXT="
@ECHO OFF
ECHO Setting TiMidity as the MIDI provider
MIDICONFIG 128:0
"
echo "$TIMIDITYTEXT" > /home/dosbox/dos_root/DOSBIAN/TIMIDITY.BAT

## BATCH FILE TO CHANGE TO THE MUNT PROVIDER
MT32TEXT="
@ECHO OFF
ECHO Setting MUNT as the MIDI provider
MIDICONFIG 129:0
"
echo "$MT32TEXT" > /home/dosbox/dos_root/DOSBIAN/MT32.BAT

## BATCH FILE TO EASILY RETUR TO DEFAULT SETTINGS AFTER MESSING WITH THEM
DEFAULTTEXT="
@ECHO OFF
ECHO Setting DOSBOX to chosen defaults
REM Change these as needed; for example on my laptop I needed SB Mixer off so I could balance MIDI
CPUTYPE AUTO
CORE DYNAMIC
CYCLES AUTO
REM SBMIXER FALSE
REM MIXER SB 40:40
"
echo "$DEFAULTTEXT" > /home/dosbox/dos_root/DOSBIAN/DEFAULTS.BAT

## FIX OWNERSHIP OF PROFILE ITEMS
sudo chown -R dosbox:dosbox /home/dosbox

echo DOSbian installation and configuration complete. Rebooting in 10 seconds. Press CTRL+C to cancel.
#sleep 10
#sudo reboot now