#!/usr/bin/python3

# For Libreelec/Lakka, note that we need to add system paths
# import sys
# sys.path.append('/storage/.kodi/addons/virtual.rpi-tools/lib')
import RPi.GPIO as GPIO

import sys
import os
import time
from threading import Thread

sys.path.append("/etc/pod/")

POD_CONFIGFILE = "/etc/pod.conf"

PIN_BRIGHTNESS=18
PIN_BUTTONA=16
PIN_BUTTONB=20
PIN_BUTTONC=21
PIN_BUTTOND=26

def button_handle(brightcontroller, buttongpio, buttonlist, systemstate, msg = "OK"):
	buttonidx=-1
	if buttongpio == PIN_BUTTONA:
		buttonidx=0
		#print("K1", msg)
	elif buttongpio == PIN_BUTTONB:
		buttonidx=1
		#print("K2", msg)
	elif buttongpio == PIN_BUTTONC:
		buttonidx=2
		#print("K3", msg)
	elif buttongpio == PIN_BUTTOND:
		buttonidx=3
		#print("K4", msg)
	if len(buttonlist) > buttonidx:
		action=buttonlist[buttonidx]
		try:
			if action == "brightup":
				brightvalue = systemstate["brightvalue"] + 5
				if brightvalue > 100:
					brightvalue = 100
				brightcontroller.start(brightvalue)
				systemstate["brightvalue"]=brightvalue
			elif action == "brightdown":
				brightvalue = systemstate["brightvalue"] - 5
				if brightvalue < 0:
					brightvalue = 0
				brightcontroller.start(brightvalue)
				systemstate["brightvalue"]=brightvalue
			elif action == "brighttoggle":
				brightcontroller.start(systemstate["brighttoggle"])
				if systemstate["brighttoggle"] == 0:
					systemstate["brighttoggle"]=systemstate["brightvalue"]
				else:
					systemstate["brighttoggle"]=0
			elif action == "volup":
				devname=get_audiodevice()
				devvolume=get_audiodevicevolume(devname)
				if devvolume <= 95:
					devvolume = devvolume + 5
				else:
					devvolume = 100
				os.system('/usr/bin/amixer set '+devname+' -- '+str(devvolume)+'%')
			elif action == "voldown":
				devname=get_audiodevice()
				devvolume=get_audiodevicevolume(devname)
				if devvolume >= 5:
					devvolume = devvolume - 5
				else:
					devvolume = 0
				os.system('/usr/bin/amixer set '+devname+' -- '+str(devvolume)+'%')
			elif action == "voltoggle":
				devname=get_audiodevice()
				os.system('/usr/bin/amixer set '+devname+' toggle')
			elif action == "reboot":
				os.system("reboot")
				systemstate["loopcontinue"]=False
			elif action == "shutdown":
				os.system("shutdown now -h")
				systemstate["loopcontinue"]=False
		except Exception as e:
			return systemstate
	return systemstate

def get_audiodevice():
	#/usr/bin/amixer scontrols | sed -n "s/^.*'\(.*\)'.*$/\1/p"
	stream = os.popen('/usr/bin/amixer scontrols | sed -n "s/^.*\'\(.*\)\'.*$/\\1/p" | grep -v apture')
	tmp=stream.read().split("\n")
	if len(tmp)>0:
		return tmp[0]
	return "Master"


def get_audiodevicevolume(devicename):
	#/usr/bin/amixer scontrols | sed -n "s/^.*'\(.*\)'.*$/\1/p"
	stream = os.popen('/usr/bin/amixer get '+devicename+' | grep -o [0-9]*% |sed "s/%//"')
	tmp=stream.read().split("\n")
	if len(tmp)>0:
		return int(tmp[0])
	return 100

# Detect change in value, apart from HIGH/LOW
# Prevent issues when button is pressed/locked
def button_check():
	systemstate={
		"loopcontinue":True,
		"brightvalue":80,
		"brighttoggle":0
	}

	try:
		# Initialize GPIO
		GPIO.setwarnings(False)
		GPIO.setmode(GPIO.BCM)
		GPIO.setup(PIN_BUTTONA, GPIO.IN,  pull_up_down=GPIO.PUD_DOWN)
		GPIO.setup(PIN_BUTTONB, GPIO.IN,  pull_up_down=GPIO.PUD_DOWN)
		GPIO.setup(PIN_BUTTONC, GPIO.IN,  pull_up_down=GPIO.PUD_DOWN)
		GPIO.setup(PIN_BUTTOND, GPIO.IN,  pull_up_down=GPIO.PUD_DOWN)
		GPIO.setup(PIN_BRIGHTNESS, GPIO.OUT)
	except Exception as e:
		return

	try:
		brightcontroller = GPIO.PWM(PIN_BRIGHTNESS,150)

		brightcontroller.start(systemstate["brightvalue"])
	except Exception as e:
		GPIO.cleanup()
		return

	loopctr = 0
	buttonidx = 0

	try:
		tmpconfig=load_buttonconfig(POD_CONFIGFILE)
		buttonlist = []

		if "buttonlist" in tmpconfig:
			buttonlist = tmpconfig["buttonlist"]

		# Default to low
		buttonvalues = [GPIO.LOW, GPIO.LOW, GPIO.LOW, GPIO.LOW]
		while systemstate["loopcontinue"] == True:
			buttonidx = 0
			for buttongpio in [PIN_BUTTONA, PIN_BUTTONB, PIN_BUTTONC, PIN_BUTTOND]:
				tmpval = GPIO.input(buttongpio)
				if loopctr > 0:
					if tmpval != buttonvalues[buttonidx]:
						if tmpval == GPIO.LOW:
							systemstate = button_handle(brightcontroller, buttongpio, buttonlist, systemstate)
				buttonvalues[buttonidx] = tmpval
				buttonidx = buttonidx + 1
			loopctr = loopctr + 1
			if loopctr > 1000:
				# Prevent overflow
				loopctr = 1
			time.sleep(0.01)
	except Exception as e:
		loopctr = 0
		buttonidx = 0


	brightcontroller.stop()
	GPIO.cleanup()


# Load Button Config file
def load_buttonconfig(fname):
	output={}
	try:
		with open(fname, "r") as fp:
			for curline in fp:
				if not curline:
					continue
				tmpline = curline.strip()
				if not tmpline:
					continue
				if tmpline[0] == "#":
					continue
				tmppair = tmpline.split("=")
				if len(tmppair) != 2:
					continue
				if tmppair[0] == "buttonlist":
					output['buttonlist']=tmppair[1].replace("\"", "").split(" ")
	except:
		return {}
	return output


def display_shutdown():
	return

if len(sys.argv) > 1:
	cmd = sys.argv[1].upper()
	if cmd == "SHUTDOWN":
		display_shutdown()
	elif cmd == "SERVICE":
		# Starts the button monitoring threads
		try:
			buttonthread = Thread(target = button_check)
			buttonthread.start()

			# Wait for threads to finish
			buttonthread.join()
		except Exception as e:
			cmd = ""
