#!/usr/bin/env Rscript

# Read the data (single column, no header)
data <- read.table('data_UFO_Kalmar_20140401_frames.dat', header=FALSE)

# Create frame numbers (1, 2, 3, ...)
frame_numbers <- 1:nrow(data)
movement_values <- data[,1]

# Create the plot
png('plot_data_UFO_Kalmar_20140401_frames.dat.png', width=800, height=600)

# Set up the plot with log scale on y-axis
plot(frame_numbers, movement_values, 
     type='b',  # 'b' for both points and lines
     log='y',   # log scale on y-axis
     main='data_UFO_Kalmar_20140401_frames',
     xlab='Frame Number',
     ylab='Movement',
     pch=16,    # solid circles for points
     col='blue')

# Add grid for better readability
grid()

# Close the device
dev.off()

cat('Plot saved as plot_data_UFO_Kalmar_20140401_frames.dat.png\n')
