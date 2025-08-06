#!/usr/bin/env nextflow

params.input_dir="$projectDir/input/"
params.outdir="results"
params.fuzz=25
params.thresh_moving=0

workflow {
    log.info """\
    Movement Finder in Fixed-camera Videos
    ===================================
    input        : ${params.input_dir}
    outdir       : ${params.outdir}
    fuzz         : ${params.fuzz}
    thresh_moving: ${params.thresh_moving}
    ===================================
    """
    .stripIndent()

    // Create input channel with file basenames as metadata
    input_ch = Channel.fromPath("${params.input_dir}/*.mp4")
        .map { file -> [file.baseName, file] }

    // Process frames and maintain the relationship
    get_frames(input_ch)

    // Process movement detection
    movement_spotter(get_frames.out.frames_dir)

    // Combine the outputs properly using the basename as key
    combined_ch = movement_spotter.out.data_list
        .join(get_frames.out.frames_dir)
        .join(movement_spotter.out.traceDiff_frames_dir)

    // Process moving frames
    get_all_moving_frames(combined_ch)

    // Plot results
    plot(movement_spotter.out.data_list)
}

process get_frames {
    tag "mplayer"

    input:
    tuple val(basename), path(input)

    output:
    tuple val(basename), path("${basename}_frames"), emit: frames_dir

    script:
    """
    mkdir "${basename}_frames"
    mplayer -nosound -vo jpeg:outdir="${basename}_frames" -speed 100 "$input" -benchmark
    """
}

process movement_spotter {
    tag "imagemagick"
    publishDir params.outdir, mode:'copy', pattern: 'data_*.dat'

    input:
    tuple val(basename), path(frames_dir)

    output:
    tuple val(basename), path("data_${basename}.dat"), emit: data_list
    tuple val(basename), path("traceDiff_${basename}"), emit: traceDiff_frames_dir

    script:
    """
    TMP_SCRIPT=\$(mktemp)
    N=\$(ls ${frames_dir}/*.jpg | wc -l)

    for i in \$(seq 1 \$((\$N-1))); do
        cmd=\$(printf "compare -metric AE -fuzz ${params.fuzz}%% ${frames_dir}/%08d.jpg ${frames_dir}/%08d.jpg traceDiffFrame_${basename}_%08d 2>> data_${basename}.dat ; echo >> data_${basename}.dat\\n" \$i \$((\$i+1)) \$i)
        echo \$cmd >> \$TMP_SCRIPT
    done

    bash \$TMP_SCRIPT

    # Move all diff pixel frames to dedicated directory
    mkdir traceDiff_${basename}
    mv traceDiffFrame_${basename}_* traceDiff_${basename}/
    """
}

process get_all_moving_frames {
    tag "ubuntu"
    publishDir params.outdir, mode:'copy'

    input:
    tuple val(basename), path(movement_data_frames), path(frames_dir), path(traceDiff_frames_dir)

    output:
    tuple val(basename), path("moving_frames_${basename}"), emit: moving_frames_dir, optional: true

    script:
    """
    TMP_SCRIPT=\$(mktemp)
    mkdir moving_frames_${basename}

    awk -v frames_dir="${frames_dir}" -v traceDiff_dir="${traceDiff_frames_dir}" -v output_dir="moving_frames_${basename}" -v thresh="${params.thresh_moving}" '
    {
        counter++;
        if(\$1 > thresh) {
            printf("cp %s/%08d.jpg %s/traceDiffFrame_%s_%08d %s/\\n", frames_dir, counter, traceDiff_dir, "${basename}", counter, output_dir)
        }
    }' ${movement_data_frames} > \$TMP_SCRIPT

    bash \$TMP_SCRIPT
    """
}

process plot {
    tag "R_plot"
    publishDir params.outdir, mode:'copy'

    input:
    tuple val(basename), path(data_movement)

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

    # Set up the plot
    plot(frame_numbers, movement_values,
         type='b',  # 'b' for both points and lines
         main='${basename}',
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
