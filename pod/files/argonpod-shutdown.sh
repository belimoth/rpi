#!/bin/bash

pythonbin=/usr/bin/python3
argonpodscript=/etc/argonpod/argonpodd.py

if [ ! -z "$1" ]
then
	if [ "$1" = "poweroff" ] || [ "$1" = "halt" ]
	then
		# Change Screen to Black
		setterm -powerdown 1
		#$pythonbin $argonpodscript SHUTDOWN
	fi
fi
