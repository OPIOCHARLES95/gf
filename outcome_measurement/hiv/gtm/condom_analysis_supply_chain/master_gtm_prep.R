# ----------------------------------------------
# Irena Chen
# 5/25/18
# Master prep file for GTM HIV supply chain data 
# ----------------------------------------------
  ###### Set up R / install packages  ###### 
# ----------------------------------------------
rm(list=ls())
library(data.table)
library(reshape2)
library(stringr)
library(lubridate)
library(readxl)
library(stats)
library(rlang)
library(zoo)
library(readr)
# ----------------------------------------------
###### Call directories and load the prep data  ###### 
# ----------------------------------------------
# file path where the files are stored
local_dir <- "J:/Project/Evaluation/GF/outcome_measurement/gtm/HIV/"

# ----------------------------------------------
  ###### Load the prep file  ###### 
# ----------------------------------------------
file_list <- data.table(read_excel(paste0(local_dir, "prep_file_list.xlsx")))
file_list$start_date <- ymd(file_list$start_date)
file_list$file_name <- as.character(file_list$file_name)

# ----------------------------------------------
######For loop that appends each data file to our database  ###### 
# ----------------------------------------------
for(i in 1:length(file_list$file_name)){
  if(file_list$type[i]=="condom"){
    hivData <- prep_condom_data(paste0(local_dir, file_list$file_name[i]), file_list$sheet[i]
                               , ymd(file_list$start_date[i]), file_list$period[i])
  }
  if(i==1){
   sc_database <-hivData 
  } else {
    sc_database <- rbind(hivData, sc_database)
  }
  print(i)
}


sc_database$condom_consumption <- as.numeric(sc_database$condom_consumption)
sc_database$condom_stockage <- as.numeric(sc_database$condom_stockage)
# ----------------------------------------------
###### Add more variables that track indicators: 
# ---------------------------------------------

## vector dictionary of special characters to regular characters
unwanted_array = list(    'S'='S', 's'='s', 'Z'='Z', 'z'='z', '�'='A', '�'='A', '�'='A', '�'='A', '�'='A', '�'='A', '�'='A', '�'='C', '�'='E', '�'='E',
                          '�'='E', '�'='E', '�'='I', '�'='I', '�'='I', '�'='I', '�'='N', '�'='O', '�'='O', '�'='O', '�'='O', '�'='O', '�'='O', '�'='U',
                          '�'='U', '�'='U', '�'='U', '�'='Y', '�'='B', '�'='Ss', '�'='a', '�'='a', '�'='a', '�'='a', '�'='a', '�'='a', '�'='a', '�'='c',
                          '�'='e', '�'='e', '�'='e', '�'='e', '�'='i', '�'='i', '�'='i', '�'='i', '�'='o', '�'='n', '�'='o', '�'='o', '�'='o', '�'='o',
                          '�'='o', '�'='o', '�'='u', '�'='u', '�'='u', '�'='y', '�'='y', '�'='b', '�'='y' )

##get rid of special characters in the dataset (necessary if we want to map these to the shapefiles)
sc_database$department <- gsub("\\*", "",sc_database$department) 
sc_database$department <- trimws(sc_database$department, "r")

##function to get rid of the special characters and standardize the departments to the shapefiles that we have 
standardize_depts <- function(department){
  x <- department
  if(grepl("Guat", x)){
    x <- "Guatemala"
  } else if (grepl("Peten", x)){
    x <- "Peten"
  } else {
    x <- x
  }
  return(x)
}


sc_database$department <- chartr(paste(names(unwanted_array), collapse=''),
                             paste(unwanted_array, collapse=''),
                             sc_database$department)
sc_database$standardized_dept <- mapply(standardize_depts, sc_database$department)



# ----------------------------------------------
##export as CSV 
# ----------------------------------------------
write.csv(sc_database, paste0(local_dir, "prepped_data/", "condom_prepped_data.csv"))
  