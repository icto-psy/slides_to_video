#devtools::install_github("leonawicz/mapmate")
library(tidyverse)
library(xml2)
library(mapmate)
library(stringr)

data <- read_xml("input/MediasitePresentation_70.xml")

# Load XML file
# Extract file times
# Get picture names
slide_number_xml <- data %>% xml_find_all(xpath = "//Slides/Slide/Number")
slide_time_xml <- data %>% xml_find_all(xpath = "//Slides/Slide/Time")

slide_number_vec <- slide_number_xml %>% xml_text()
slide_time_vec <- as.numeric(slide_time_xml %>% xml_text())

image_paths <- list.files("input/Content/",pattern = "slide_[0-9]{4}_full.jpg",full.names = TRUE) 
tmp_paths <- paste0("temp/imgs/",list.files("input/Content/",pattern = "slide_[0-9]{4}_full.jpg"))
# copy files for ffmpeg
file.copy(image_paths, "temp/imgs/", recursive = FALSE,
          copy.mode = TRUE, copy.date = FALSE)

# Write file that is necessary for conversion

slide_duration_vec <- numeric(length(slide_time_vec))

for(i in 2:length(slide_time_vec)){
  slide_duration_vec[i - 1] <- slide_time_vec[i] - slide_time_vec[i-1]
}

slide_duration_vec <- slide_duration_vec/1000

#