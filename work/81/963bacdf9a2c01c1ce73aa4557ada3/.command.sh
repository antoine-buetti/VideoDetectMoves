#!/bin/bash -ue
mkdir moving_frames_vid2_frames
awk '{counter++; if($1>0) {printf("cp vid2_frames/%08d.jpg traceDiff_vid2_frames/traceDiffFrame_%08d  moving_frames_vid2_frames \n"),counter,counter}}' data_vid2_frames.dat > tmp.sh
bash tmp.sh
