#!/bin/sh
#
# 360 AP6PCM03 first-boot setup. Run once by S30customizer, before
# S40network and S70vendor, so the wifi profile and the sensor name
# are in the environment before either of them looks.

# IR-cut filter on GPIO 59/60, IR lamp on 14, speaker amplifier on 63.
# Speaker output at 16 kHz: the IMP SDK rejects audio-output frames over
# 20 ms of the channel rate, and majestic pushes fixed 640-byte frames,
# which only fit from 16 kHz up -- at 8 kHz every frame is refused and the
# speaker stays silent.
cli -s .nightMode.irCutPin1 59
cli -s .nightMode.irCutPin2 60
cli -s .nightMode.backlightPin 14
# Day/night by the picture: the master switch must be on for any automatic
# switching, and the exposure-based default trigger never fires on this
# sensor pipeline -- a numeric gain threshold does (day idles at ~1.4x,
# darkness saturates past 70x, the IR-lit night scene settles near 13x).
cli -s .nightMode.lightMonitor true
cli -s .nightMode.autoNightGain 8
cli -s .audio.speakerPin 63
cli -s .audio.srate 16000
cli -s .audio.outputVolume 95

# The GC4653 is mounted upside-down in this shell.
cli -s .image.mirror true
cli -s .image.flip true

# ATBM6031 SDIO wifi on MSC1 port A, power switch on GPIO 53.
fw_setenv wlandev atbm603x-t31-ap6pcm03

# PTZ: four shared coil pins and the H/V select on GPIO 62. ptz_control is
# the WebUI's switch (#227): gpio-motors plus pins still renders no pad
# until it names "gpio".
fw_setenv ptz_gpio "49 50 57 58 62"
fw_setenv ptz_control gpio

# The sensor is known, skip the sinfo probe.
fw_setenv sensor gc4653

exit 0
