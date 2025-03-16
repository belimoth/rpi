#!/bin/bash


buttonconfigfile=/etc/argonpod.conf


echo "-----------------------------"
echo " ArgonPOD Button Setup Tool"
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

get_actionname() {
	if [ "$1" == "brightup" ]
	then
		pagename="Increase Brightness"
	elif [ "$1" == "brightdown" ]
	then
		pagename="Decrease Brightness"
	elif [ "$1" == "brighttoggle" ]
	then
		pagename="Turn screen on/off (via Brightness)"
	elif [ "$1" == "volup" ]
	then
		pagename="Increase Volume"
	elif [ "$1" == "voldown" ]
	then
		pagename="Decrease Volume"
	elif [ "$1" == "voltoggle" ]
	then
		pagename="Mute/Unmute"
	elif [ "$1" == "reboot" ]
	then
		pagename="Reboot"
	elif [ "$1" == "shutdown" ]
	then
		pagename="Shutdown"
	elif [ "$1" == "none" ]
	then
		pagename="No Action"
	else
		pagename="Invalid"
	fi
}


saveconfig () {
	echo "#" > $buttonconfigfile
	echo "# Argon POD Configuration" >> $buttonconfigfile
	echo "#" >> $buttonconfigfile
	echo "buttonlist=\"$1\"" >> $buttonconfigfile
}


numbutton=4
fullcodelist="brightup brightdown brighttoggle volup voldown voltoggle reboot shutdown none"
fullcodearray=($fullcodelist)

codearray=(none none none none)
restartservice=0
updateconfig=1
loopflag=1
while [ $loopflag -eq 1 ]
do
	buttonlist=""
	if [ $updateconfig -eq 1 ]
	then
		if [ -f "$buttonconfigfile" ]
		then
			. $buttonconfigfile
		fi
		if [ ! -z "$buttonlist" ]
		then
			codearray=($buttonlist)
		fi
	fi
	updateconfig=0

	tmpmode=${#codearray[@]}
	while [ $tmpmode -lt $numbutton ]
	do
		codearray[$tmpmode]="none"
		tmpmode=$((tmpmode+1))
	done

	echo
	echo "+-----------------+"
	echo "| [1] [2] [3] [4] |"
	echo "+-----------------+"
	echo "| +-------------+ |"
	echo "| |    Screen   | |"
	echo "| +-------------+ |"
	echo "+-----------------+"
	echo "Choose Button:"
	tmpmode=0
	while [ $tmpmode -lt $numbutton ]
	do
		get_actionname ${codearray[$tmpmode]}
		echo "  "$((tmpmode+1))". Button "$((tmpmode+1))": "$pagename
		tmpmode=$((tmpmode+1))
	done
	echo ""
	if [ $restartservice -eq 1 ]
	then
		echo "  0. Apply Changes"
	else
		echo "  0. Cancel"
	fi
	echo -n "Enter Number (0-4):"

	newmode=$( get_number )
	if [[ $newmode -gt 0 && $newmode -le $numbutton ]]
	then
		echo "--------------------------------"
		echo " Choose Action for Button $newmode"
		echo "--------------------------------"
		echo
		i=0
		for curcode in $fullcodelist
		do
			i=$((i+1))
			get_actionname $curcode
			echo "  $i. $pagename"
		done
		echo
		echo "  0. Cancel"
		echo -n "Enter Number (0-$i):"
		pagenum=$( get_number )
		if [[ $pagenum -ge 1 && $pagenum -le $i ]]
		then
			codearray[$((newmode-1))]=${fullcodearray[$((pagenum-1))]}
			outlist=${codearray[@]}
			saveconfig "$outlist"
			updateconfig=1
			restartservice=1
		fi
	elif [ $newmode -eq 0 ]
	then
		loopflag=0
	fi
done

if [ $restartservice -eq 1 ]
then
	sudo systemctl restart argonpodd.service
fi

echo
echo "Done"
