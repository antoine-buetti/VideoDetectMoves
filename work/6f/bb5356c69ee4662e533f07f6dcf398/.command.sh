#!/bin/bash -ue
mkdir "UFO_Kalmar_20140401_frames"
mplayer -nosound -vo jpeg:outdir="UFO_Kalmar_20140401_frames" -speed 100 "UFO_Kalmar_20140401.mp4" -benchmark
