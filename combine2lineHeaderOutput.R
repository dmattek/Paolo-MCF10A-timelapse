# Searches for csv files in all sub-directories of a given directory, merges the files
# and puts them in specified output directory.
# Files for merging should have a 2-line-header
#
# Example call from the command-line
# Rscript combine2lineHeaderOutput.R ~/myexp1/cp.out/output objNuc.csv .mer
# Last parameter is optional, defaults to ".mer"

require(data.table)
require(tca)
require(optparse)

# parser of command-line arguments from:
# https://www.r-bloggers.com/passing-arguments-to-an-r-script-from-command-lines/

option_list = list(
  make_option(c("-o", "--dirout"), type="character", default="output", 
              help="directory with entire output [default= %default]", metavar="character"),
  make_option(c("-f", "--fileout"), type="character", default="objNuclei.csv", 
              help="csv with 2-line header output [default= %default]", metavar="character"),
  make_option(c("-s", "--suffout"), type="character", default=".mer", 
              help="suffix to add to the output directory, to make directory with merged output [default= %default]", metavar="character"),
  make_option(c("-r", "--remcols"), type="character", default="NULL", 
              help="quoted, comma-separated list with column names to remove [default= %default]", metavar="character")
); 

opt_parser = OptionParser(option_list=option_list);
opt = parse_args(opt_parser);


# params
params = list()

## User-defined input

# Path to CP output
# This directory is the root for a directory that contains sub-directories
# E.g. myexp1/cp.out1/output
params$s.dir.data = opt$dirout

# File name with CP output, e.g. objNuclei_1line_clean_tracks.csv
# This file will be searched in subdirectories of s.dir.data folder
params$s.file.data = opt$fileout

# Suffix to add to output directory name for placing merged output
# Default ".mer"
params$s.dir.suf = opt$suffout

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

dt.all = do.call(rbind, lapply(s.files, freadCSV2lineHeader, in.col.rem = opt$remcols))

# write merged dataset
cat(sprintf("Saving output to: %s\n", file.path(params$s.dir.out, params$s.file.data)))

write.csv(dt.all, file = file.path(params$s.dir.out, params$s.file.data), row.names = F) 

