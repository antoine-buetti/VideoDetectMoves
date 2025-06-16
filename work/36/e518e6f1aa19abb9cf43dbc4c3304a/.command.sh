#!/bin/bash -ue
N=$(ls UFO_Kalmar_20140401_frames/*.jpg | wc | awk '{print $1}')
    for i in `seq 1 $(($N-1))`; do # last frame -2 because compare 2 a 2
    cmd=$(printf "compare -metric AE -fuzz 25%% UFO_Kalmar_20140401_frames/%08d.jpg UFO_Kalmar_20140401_frames/%08d.jpg traceDiffFrame_%08d 2>> data_UFO_Kalmar_20140401_frames.dat ; echo >> data_UFO_Kalmar_20140401_frames.dat 
" $i $(($i+1)) $i )
    echo $cmd >> tmp.sh
    done
    bash tmp.sh 

    # spostare tutte le frames di diff pixel in dir apposita:
    mkdir traceDiff_UFO_Kalmar_20140401_frames
    mv  traceDiffFrame_* traceDiff_UFO_Kalmar_20140401_frames
