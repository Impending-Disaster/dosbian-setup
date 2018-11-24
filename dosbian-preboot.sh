#!/bin/sh

file1="$HOME/dosbian-preboot.sh"
file2="$HOME/dosbian-setup.sh"

if [ ! -f "$file1" ] || [ ! -f "$file2" ]; then
	echo DOSbian setup scripts must be in the HOME directory
	exit 1
fi
## CHECK IF THE MT32 ROM EXISTS IN THE EPXECTED PATH
## IF NOT, PROVIDE A HINT
if [ ! -f "$HOME/mt32-rom-data/MT32_CONTROL.ROM" ] || [ ! -f "$HOME/mt32-rom-data/MT32_PCM.ROM" ]; then
	echo MT32 ROM Data was not found in the expected path \(~/mt32-rom-data\)
	echo The DOSbian setup script can automatically prepare the ROM files
	echo if you place them in your HOME directory under the /mt32-rom-data subdirectory
	echo MT32_CONTROL.ROM and MT32_PCM.ROM are expected by the script for MT-32 emulation
	echo Press any key to continue or CTRL+C to abort
	echo If you cancel now, will be able to safely re-run the dosbian-preboot script
	read
fi

## INSTALL SUDO AND REBOOT SINCE IT'S REQUIRED
apt-get install -y sudo

## WITH A FRESH DEBIAN INSTALL UID 1000 IS GOING TO BE THE UNPRIVILIGED USER THAT WAS CREATED DURING THE STARTUP PROCESS
## WE'RE GOING TO GET THAT USER'S NAME FOR FURTHER USE
SUDOUSER=`awk -v uid=1000 -F":" '{ if($3==uid){print $1} }' /etc/passwd`

## ADD THE UNPRIVILEGED USER TO THE SUDO GROUP
usermod -a -G sudo $SUDOUSER

## PLACE THE NEEDED FILES IN THE ROOT OF THAT USER'S HOME DIRECTORY
mv dosbian-setup.sh /home/$SUDOUSER/
mv mt32-rom-data /home/$SUDOUSER/

## SET SYSTEM TO AUTOBOOT TO SUDOUSER
sed -i "s/noclear\ /noclear\ -a\ $SUDOUSER\ /" /lib/systemd/system/getty@.service

## BACK UP THE SUDOUSER PROFILE FILE
cp /home/$SUDOUSER/.profile /home/$SUDOUSER/profile.bak

## REPAIR THE SUDOUSER PERMISSIONS
chown -R $SUDOUSER:$SUDOUSER /home/$SUDOUSER

## INSERT THE INSTALLATION SCRIPT INTO ROOT'S AUTORUN
echo "./dosbian-setup.sh | tee dosbian-log.log" >> /home/$SUDOUSER/.profile

reboot now