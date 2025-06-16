#!/bin/bash -ue
N=$(ls vid2_frames/*.jpg | wc | awk '{print $1}')
    for i in `seq 1 $(($N-1))`; do # last frame -2 because compare 2 a 2
    cmd=$(printf "compare -metric AE -fuzz 25%% vid2_frames/%08d.jpg vid2_frames/%08d.jpg traceDiffFrame_%08d 2>> data_vid2_frames.dat ; echo >> data_vid2_frames.dat 
" $i $(($i+1)) $i )
    echo $cmd >> tmp.sh
    done
    bash tmp.sh 

    # spostare tutte le frames di diff pixel in dir apposita:
    mkdir traceDiff_vid2_frames
    mv  traceDiffFrame_* traceDiff_vid2_frames
