#!/bin/bash

if [ ! -z "$1" ]
then
	if [ "$1" = "poweroff" ] || [ "$1" = "halt" ]
	then
		setterm -powerdown 1
		# /usr/bin/python3 /etc/argonpod/argonpodd.py SHUTDOWN
	fi
fi
