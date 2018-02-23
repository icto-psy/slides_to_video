## This script converts the slides in a webcollege export file to a continuous video file. 
## The conversion from jpeg to mp4 uses ffmpeg, which needs to be installed before running the script.
## See https://ffmpeg.zeranoe.com/builds/ for more information. 

library(tidyverse)
library(xml2)
library(stringr)

# Specify the path to unzipped mediasite folder
path_to_unzipped_mediasite_folder <- "../../Movies/wsrLectures/Wetenschappelijk & Statistisch Redeneren incl. Tes.p2g/"

# Specify output folder
path_output <- "../../Movies/wsrLectures/Wetenschappelijk & Statistisch Redeneren incl. Tes.p2g/"



# Load the xml file containing the meta information. (Needs to be specified)
data <- read_xml(paste0(path_to_unzipped_mediasite_folder,"MediasitePresentation_70.xml"))

# Get the slide onset times (in milliseconds)
slide_time_vec <-
  data %>% xml_find_all(xpath = "//Slides/Slide/Time") %>% xml_text() %>% as.numeric()

# Get the total video time.
video_time <-
  data %>% xml_find_all(xpath = "//PresentationContent/Length") %>% xml_text() %>% as.numeric()

# Specify the path to the images/content 
path_to_content <- paste0(path_to_unzipped_mediasite_folder,"Content/")

image_paths <-
  list.files(path_to_content, pattern = "slide_[0-9]{4}_full.jpg", full.names = TRUE) 

# Add jpg to png conversion for mac here.

# Debug mode - shorten render
image_paths <- image_paths[1:100]
  
# Write input.txt file, that is used for ffmpeg conversion
slide_duration_vec <- numeric(length(slide_time_vec))

## Set the first slide time to be zero. This leads to the first slide being shown from the beginning of the video.
slide_time_vec[1] <- 0

## Starting by the second slide onset time, calculate the difference between the previous onset and the current onset.
## This produces a vector with the durations of each slide in milliseconds. 
for(i in 2:length(slide_time_vec)) {
  slide_duration_vec[i - 1] <- slide_time_vec[i] - slide_time_vec[i - 1]
}

## Set the duration of the last slide to be the difference between the total length of the presentation video and 
## the last slide duration. This causes the last slide to be shown to the very end of the presentation. 
slide_duration_vec[length(slide_duration_vec)] <-
  video_time - slide_time_vec[length(slide_time_vec)]

## Convert to seconds.
slide_duration_vec <- slide_duration_vec / 1000

## Prepare the text output
text_output <- character(length(image_paths))

for(i in 1:length(image_paths)) {
  text_output[i] <-
    paste0("file ",
           "'",
           image_paths[i],
           "'",
           "\r",
           paste0("duration ", slide_duration_vec[i]))
}
## Write the input.txt file needed for ffmpeg to work. 
write.table(
  "input.txt",
  x = text_output,
  quote = FALSE,
  eol = "\r",
  row.names = FALSE,
  col.names = FALSE
)

# Run ffmpeg.
system2(command = "ffmpeg",
        args = list("-f concat ",
                    "-safe 0 ",
                    "-i input.txt ",
                    # "-pix_fmt rgb24 ",                # Extra for mac
                    # "-c:v libx264 -pix_fmt yuv410p ", # Extra for mac
                    "out.mp4"))

# Move output to specified folder
file.copy("out.mp4", path_output)

## Remove input.txt, leaving a clean workspace. 
file.remove(c("input.txt", "out.mp4"))

