#!/bin/bash -ue
mkdir "vid2_frames"
mplayer -nosound -vo jpeg:outdir="vid2_frames" -speed 100 "vid2.mp4" -benchmark
