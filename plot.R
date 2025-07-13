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
         log='y',   # log scale on y-axis
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
