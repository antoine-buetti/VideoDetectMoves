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
    path "${input.baseName}_frames", emit: frames_dir

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
    path "data_${frames_dir.baseName}.dat", emit: data_list
    path "traceDiff_${frames_dir.baseName}", emit: traceDiff_frames_dir


    script:
    """
    TMP_SCRIPT=\$(mktemp)
    N=\$(ls ${frames_dir}/*.jpg | wc -l)

    for i in \$(seq 1 \$((\$N-1))); do
        cmd=\$(printf "compare -metric AE -fuzz ${params.fuzz}%% ${frames_dir}/%08d.jpg ${frames_dir}/%08d.jpg traceDiffFrame_${frames_dir.baseName}_%08d 2>> data_${frames_dir.baseName}.dat ; echo >> data_${frames_dir.baseName}.dat\\n" \$i \$((\$i+1)) \$i)
        echo \$cmd >> \$TMP_SCRIPT
    done

    bash \$TMP_SCRIPT

    # Move all diff pixel frames to dedicated directory
    mkdir traceDiff_${frames_dir.baseName}
    mv traceDiffFrame_${frames_dir.baseName}_* traceDiff_${frames_dir.baseName}/
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
    path "moving_frames_${frames_dir.baseName}", emit: moving_frames_dir, optional: true

    script:
    """
    TMP_SCRIPT=\$(mktemp)
    mkdir moving_frames_${frames_dir.baseName}

    awk -v frames_dir="${frames_dir}" -v traceDiff_dir="${traceDiff_frames_dir}" -v output_dir="moving_frames_${frames_dir.baseName}" -v thresh="${params.thresh_moving}" '
    {
        counter++;
        if(\$1 > thresh) {
            printf("cp %s/%08d.jpg %s/traceDiffFrame_%s_%08d %s/\\n", frames_dir, counter, traceDiff_dir, "${frames_dir.baseName}", counter, output_dir)
        }
    }' ${movement_data_frames} > \$TMP_SCRIPT

    bash \$TMP_SCRIPT
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
    #     log='y',   # log scale on y-axis -> problem if 0 moving frames :)
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


