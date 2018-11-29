#!/bin/sh

file1="dosbian-preboot.sh"
file2="dosbian-setup.sh"

if [ ! -f "$file1" ] || [ ! -f "$file2" ]; then
	echo DOSbian setup scripts must be together and you must cd into the directory where they are located
	exit 1
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
if [ -d mt32-rom-data ]; then mv mt32-rom-data /home/$SUDOUSER/
elif [ -d $HOME/mt32-rom-data ]; then mv $HOME/mt32-rom-data /home/$SUDOUSER/
fi

## SET SYSTEM TO AUTOBOOT TO SUDOUSER
sed -i "s/noclear\ /noclear\ -a\ $SUDOUSER\ /" /lib/systemd/system/getty@.service

## BACK UP THE SUDOUSER PROFILE FILE
cp /home/$SUDOUSER/.profile /home/$SUDOUSER/profile.bak

## REPAIR THE SUDOUSER PERMISSIONS
chown -R $SUDOUSER:$SUDOUSER /home/$SUDOUSER

## INSERT THE INSTALLATION SCRIPT INTO THE SUDOUSER'S AUTORUN
echo "./dosbian-setup.sh | tee dosbian-log.log" >> /home/$SUDOUSER/.profile

reboot now