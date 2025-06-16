#!/bin/bash -ue
mkdir moving_frames_UFO_Kalmar_20140401_frames
awk '{counter++; if($1>0) {printf("cp UFO_Kalmar_20140401_frames/%08d.jpg traceDiff_UFO_Kalmar_20140401_frames/traceDiffFrame_%08d  moving_frames_UFO_Kalmar_20140401_frames \n"),counter,counter}}' data_UFO_Kalmar_20140401_frames.dat > tmp.sh
bash tmp.sh
