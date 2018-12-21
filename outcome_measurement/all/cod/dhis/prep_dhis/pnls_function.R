# Prep the COD DHIS2 PNLS data - step 2 (after original prep and merge)
# Drops out duplicate categories and prepares elements for division
# Caitlin O'Brien-Carelli
# 11/14/18
# when time allows rewrite as a function

# ----------------------------------------------
# Set up R

rm(list=ls())
library(data.table)
library(jsonlite)
library(httr)
library(ggplot2)
library(dplyr)
library(stringr) # to extract meta data from file names
# --------------------

# shell script
# sh /share/singularity-images/rstudio/shells/rstudio_qsub_script.sh -p 1247 -s 10 -P snis_download

# --------------------
# set working directories

# detect if operating on windows or on the cluster 
root = ifelse(Sys.info()[1]=='Windows', 'J:', '/home/j')

# set the directory for input and output
dir = paste0(root, '/Project/Evaluation/GF/outcome_measurement/cod/dhis/')

#-------------------------
# function 

x = readRDS(paste0(dir, 'prepped/pnls_drc_01_2017_07_2018_prepped.rds'))

# reqrite as a function
# pnls_subset = function(x) {
  
# subset the pnls data set to only the relevant elements for analysis
# save a smaller subset with less elements

# drop unecessary variables
x[ , c('type', 'drug', 'tableau', 'coordinates',
          'opening_date', 'last_update', 'org_unit_type', 'month'):=NULL]

# create a variable that contains only the last word
x[ , last:=word(element, -1)]

# drop anything containing soutien as the last word
x = x[!grep('soutien', last)]

# drop out elements that end in 'sex' (remainder include sex and age)
x = x[!grep('sex', last)]

# drop out elements that end in 'sex' (remainder include sex and age)
x = x[!grep('age', last)]

#---------------------------------------------

#------------------
# classify the elements

# create an element easier to grep
x[ , element1:=tolower(element)]

# drop diacritical marks
fix_diacritics <- function(x) {
  replacement_chars = list('S'='S', 's'='s', 'Z'='Z', 'z'='z', '�'='A', '�'='A', '�'='A', '�'='A', '�'='A', '�'='A', '�'='A', '�'='C', '�'='E', '�'='E',
                           '�'='E', '�'='E', '�'='I', '�'='I', '�'='I', '�'='I', '�'='N', '�'='O', '�'='O', '�'='O', '�'='O', '�'='O', '�'='O', '�'='U',
                           '�'='U', '�'='U', '�'='U', '�'='Y', '�'='B', '�'='Ss', '�'='a', '�'='a', '�'='a', '�'='a', '�'='a', '�'='a', '�'='a', '�'='c',
                           '�'='e', '�'='e', '�'='e', '�'='e', '�'='i', '�'='i', '�'='i', '�'='i', '�'='o', '�'='n', '�'='o', '�'='o', '�'='o', '�'='o',
                           '�'='o', '�'='o', '�'='u', '�'='u', '�'='u', '�'='y', '�'='y', '�'='b', '�'='y')

  replace_me <- paste(names(replacement_chars), collapse='')
  replace_with <- paste(replacement_chars, collapse = '')
  return(chartr(replace_me, replace_with, x))

}

# run the function to eliminate diacritical marks
x[ , element1:=fix_diacritics(element1)]
x[ ,last:=NULL]
#-------------------------------

# return the subset
# return(x)
  
# save the cleaned output
saveRDS(x, paste0(dir, 'prepped/pnls_drc_01_2017_07_2018_prepped_subset.rds'))