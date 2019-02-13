# Searches for csv files in all sub-directories of a given directory, merges the files
# and puts them in specified output directory.
# Files for merging should have a 2-line-header
#
# Example call from the command-line
# Rscript combine2lineHeaderOutput.R ~/myexp1/cp.out/output objNuc.csv .mer
# Last parameter is optional, defaults to ".mer"


args <- commandArgs(TRUE)

if(sum(is.na(args[1:2])) > 0) {
  stop('Insufficient input parameters. Call: Rscript combine2lineHeaderOutput.R CPoutput_dir CPoutput_file DirSuffix [optional; default .mer')
}

require(data.table)
require(tca)

# params
params = list()

## User-defined input

# Path to CP output
# This directory is the root for a directory that contains sub-directories
# E.g. myexp1/cp.out1/output
params$s.dir.data = args[1]

# File name with CP output, e.g. objNuclei_1line_clean_tracks.csv
# This file will be searched in subdirectories of s.dir.data folder
params$s.file.data = args[2]

# Suffix to add to output directory name for placing merged output
# Default ".mer"
if (is.na(args[3]))
  params$s.dir.suf = ".mer" else
    params$s.dir.suf = args[3]


# Create directory for merged output in the current working directory
# Directory with merged output has the same name as the root output directory but with params$s.file.suf suffix
# First remove trailing / from s.dir.data
params$s.dir.data = gsub('\\/$', '', params$s.dir.data)
params$s.dir.out = paste0(params$s.dir.data, params$s.dir.suf)
ifelse(!dir.exists(file.path(params$s.dir.out)), 
       dir.create(file.path(params$s.dir.out)), 
       FALSE)


# store locations of all csv files in the output folder
s.files = list.files(path = file.path(params$s.dir.data), 
                     pattern = paste0(params$s.file.data, "$"),
                     recursive = TRUE, 
                     full.names = TRUE)
cat("Merging files:\n")
cat(s.files)
cat("\n")

LOCfread = function(inFile) {
  
}

dt.all = do.call(rbind, lapply(s.files, freadCSV2lineHeader))

# write merged dataset
cat(sprintf("Saving output to: %s\n", file.path(params$s.dir.out, params$s.file.data)))

write.csv(dt.all, file = file.path(params$s.dir.out, params$s.file.data), row.names = F) 

