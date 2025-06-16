Analyse MP4 videos looking for a movements based on changes in pixels from one frame to the next.

The pipeline first converts the MP4 video into frames using the container "olmesm/mplayer-docker".

The frames are further passed onto a subsequent process that analyses the pixel changes with the container "vulhub/imagemagick:7.0.10-36-php"

The procedure was used to scan video footage in differente situations, e.g., spotting bird nesting behaviour, or shooting stars and strange moving things in the sky.

Nextflow handles multiple videos in the input directory in parallel.

Example usage: nextflow run main.nf  --input your_folder_with_mp4_video_files  --outdir results  --thresh_moving 0

Output: "plot_...png" showing a profile of the video and how much movement was detected. "moving_frames_..." containing the snapshots extracted where the movement occurred, and the pixels that were tracked.

Last modification date: Mo 16 Jun 2025 08:39:06 CEST

Antoine Buetti (antoine.buetti@gmail.com)

