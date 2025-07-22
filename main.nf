#!/usr/bin/env nextflow

params.input_dir="$projectDir/input/"
params.outdir="results"
params.fuzz=25
params.thresh_moving=0

workflow {
/*
 * pipeline input parameters
 */
log.info """\
    Movement Finder in Fixed-camera Videos
    ===================================
    input        : ${params.input_dir}
    outdir       : ${params.outdir}
    fuzz         : ${params.fuzz}
    thresh_moving: ${params.thresh_moving}

    Example usage: nextflow run main.nf  --input your_folder_with_mp4_video_files  --outdir results  --fuzz 25  --thresh_moving 0
    Output: "plot_...png" showing a profile of the video and how much movement was detected. "moving_frames_..." containing the snapshots extracted where the movement occurred, and the pixels that were tracked.

    The parameter fuzz 15% means that pixels within 25% color difference are treated as equal. You can increase it to make it even more tolerant (a lower fuzz is more sensitive but more prone to noise).
    ===================================
    """
    .stripIndent()

    input_ch = Channel.fromPath("${params.input_dir}/*.mp4")
    input_ch.view()

    get_frames(input_ch)
    get_frames.out.view()
    movement_spotter(get_frames.out.frames_dir)
    movement_spotter.out.traceDiff_frames_dir.view()
    get_all_moving_frames(movement_spotter.out.data_list, get_frames.out.frames_dir,movement_spotter.out.traceDiff_frames_dir)
    get_all_moving_frames.out.moving_frames_dir.view()
    plot(movement_spotter.out.data_list)

}


process get_frames {
    tag "mplayer"

    input:
    path input

    output:
    path '*_frames', emit: frames_dir

    script:
    """
    mkdir "${input.baseName}_frames"
    mplayer -nosound -vo jpeg:outdir="${input.baseName}_frames" -speed 100 "$input" -benchmark
    """
}

process movement_spotter {
    tag "imagemagick"
    publishDir params.outdir, mode:'copy', pattern: 'data_*.dat'

    input:
    path frames_dir

    output:
    path 'data_*.dat', emit: data_list
    path 'traceDiff_*', emit: traceDiff_frames_dir

    // stdout

    script:
    """
    N=\$(ls ${frames_dir}/*.jpg | wc | awk '{print \$1}')
    for i in `seq 1 \$((\$N-1))`; do # last frame -2 because compare 2 a 2
    cmd=\$(printf "compare -metric AE -fuzz ${params.fuzz}%% ${frames_dir}/%08d.jpg ${frames_dir}/%08d.jpg traceDiffFrame_%08d 2>> data_${frames_dir}.dat ; echo >> data_${frames_dir}.dat \n" \$i \$((\$i+1)) \$i )
    echo \$cmd >> tmp.sh
    done
    bash tmp.sh 

    # spostare tutte le frames di diff pixel in dir apposita:
    mkdir traceDiff_${frames_dir}
    mv  traceDiffFrame_* traceDiff_${frames_dir}
    """
}


process get_all_moving_frames {
    tag "ubuntu"
    publishDir params.outdir, mode:'copy'

    input:
    path movement_data_frames
    path frames_dir
    path traceDiff_frames_dir

    output:
    path 'moving_frames_*', emit: moving_frames_dir

    script:
    """
    mkdir moving_frames_${frames_dir}
    awk '{counter++; if(\$1>${params.thresh_moving}) {printf("cp ${frames_dir}/%08d.jpg ${traceDiff_frames_dir}/traceDiffFrame_%08d  moving_frames_${frames_dir} \\n"),counter,counter}}' ${movement_data_frames} > tmp.sh
    bash tmp.sh
    """
}




process plot {
    tag "R_plot"

    publishDir params.outdir, mode:'copy'

    input:
    path data_movement

    output:
    path "plot_${data_movement}.png"
    
    script:
    """
    #!/usr/bin/env Rscript

    # Read the data (single column, no header)
    data <- read.table('${data_movement}', header=FALSE)

    # Create frame numbers (1, 2, 3, ...)
    frame_numbers <- 1:nrow(data)
    movement_values <- data[,1]

    # Create the plot
    png('plot_${data_movement}.png', width=800, height=600)

    # Set up the plot with log scale on y-axis
    plot(frame_numbers, movement_values,
         type='b',  # 'b' for both points and lines
    #     log='y',   # log scale on y-axis
         main='${data_movement.baseName}',
         xlab='Frame Number',
         ylab='Movement',
         pch=16,    # solid circles for points
         col='blue')

    # Add grid for better readability
    grid()

    # Close the device
    dev.off()

    cat('Plot saved as plot_${data_movement}.png\\n')
    """
}


