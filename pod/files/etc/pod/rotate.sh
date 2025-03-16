#!/bin/bash

echo "-----------------------------"
echo " ArgonPOD Rotation Tool"
echo "------------------------------"

get_number () {
	read curnumber
	if [ -z "$curnumber" ]
	then
		echo "-2"
		return
	elif [[ $curnumber =~ ^[+-]?[0-9]+$ ]]
	then
		if [ $curnumber -lt 0 ]
		then
			echo "-1"
			return
		elif [ $curnumber -gt 100 ]
		then
			echo "-1"
			return
		fi
		echo $curnumber
		return
	fi
	echo "-1"
	return
}

if [ -e /boot/firmware/config.txt ] ; then
  FIRMWARE=/firmware
else
  FIRMWARE=
fi
bootconfigfile=/boot${FIRMWARE}/config.txt
calibrationfile=/etc/X11/xorg.conf.d/99-calibration.conf
tmpfile=$INSTALLATIONFOLDER/tmpfile.bak


sudo touch $tmpfile
sudo chmod 666 $tmpfile


configline="dtoverlay=tft9341"

# Get Current Rotation/Mode
tmpresult=`grep "$configline" $bootconfigfile`
currotation=`echo -n $tmpresult | awk -F= '{printf $NF}'`
curmode=$(((currotation/90) + 2))
if [ $curmode -gt 4 ]
then
	curmode=$((curmode-4))
fi

orientationlist=("Landscape" "Portrait" "Landscape-Reversed" "Portrait-Reversed")

loopflag=1
while [ $loopflag -eq 1 ]
do
	echo
	echo "Orientation:"
	tmpmode=0
	while [ $tmpmode -lt 4 ]
	do
		if [ $((curmode-1)) -eq $tmpmode ]
		then
			echo "  "$((tmpmode+1))". "${orientationlist[$tmpmode]}" (Current)"
		else
			echo "  "$((tmpmode+1))". "${orientationlist[$tmpmode]}
		fi
		tmpmode=$((tmpmode+1))
	done
	echo ""
	echo "  0. Cancel"
	echo -n "Enter Number (0-4):"

	newmode=$( get_number )
	if [[ $newmode -ge 0 && $newmode -le 4 ]]
	then
		if [ $newmode -eq $curmode ]
		then
			echo ""
			echo "Orientation already set"
		else
			loopflag=0
		fi
	fi
done

rotation=270
if [ $newmode -eq 0 ]
then
	echo
	echo "Cancelled"
	exit
else
	rotation=$(((newmode-2)*90))
	if [ $rotation -lt 0 ]
	then
		rotation=$((rotation+360))
	fi
fi

grep -v "$configline" $bootconfigfile > $tmpfile
echo "dtoverlay=tft9341:rotate=$rotation" >> $tmpfile
sudo cp $tmpfile $bootconfigfile

# Calibration File / Touch
echo 'Section "InputClass"' > $tmpfile
echo '        Identifier      "calibration"' >> $tmpfile
echo '        MatchProduct    "ADS7846 Touchscreen"' >> $tmpfile
if [ $rotation -eq 0 ]
then
	echo '        Option  "Calibration"   "155 3865 115 3700"' >> $tmpfile
	echo '        Option  "SwapAxes"      "0"' >> $tmpfile
elif [ $rotation -eq 90 ]
then
	echo '        Option  "Calibration"   "3700 115 155 3865"' >> $tmpfile
	echo '        Option  "SwapAxes"      "1"' >> $tmpfile
elif [ $rotation -eq 180 ]
then
	echo '        Option  "Calibration"   "3865 155 3700 115"' >> $tmpfile
	echo '        Option  "SwapAxes"      "0"' >> $tmpfile
else
	# 270
	echo '        Option  "Calibration"   "115 3700 3865 155"' >> $tmpfile
	echo '        Option  "SwapAxes"      "1"' >> $tmpfile
fi
echo 'EndSection' >> $tmpfile
sudo cp $tmpfile $calibrationfile


echo
echo "Please reboot to apply changes"

if [ -f $tmpfile ]
then
	sudo rm $tmpfile
fi
