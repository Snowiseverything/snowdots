#!/bin/bash
########################################################################
##  SnowDots — CombineAudio                             Version: v1.0.0    ##
##  Last Edited: 2026-05-10                                           ##
########################################################################
pactl load-module module-combine-sink sink_name=combined slaves=alsa_output.usb-C-Media_Electronics_Inc._USB_Audio_Device-00.analog-stereo,bluez_output.2C_BE_EB_42_DB_77.1
