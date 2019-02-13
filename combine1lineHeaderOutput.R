# Searches for csv files in all sub-directories of a given directory, merges the files
# and puts them in specified output directory.
# Files for merging should have a 1-line-header
#
# Example call from the command-line
# Rscript combine1lineHeaderOutput.R ~/myexp1/cp.out/output objNuc.csv .mer
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

# Create vector with columns to remove based on the input parameter
params$s.col.rem = unlist(strsplit(opt$remcols, ','))

# 
cat(sprintf("Processing data in: %s\n", params$s.dir.data))
cat(sprintf("Saving output to  : %s\n\n", file.path(params$s.dir.out, params$s.file.data)))
cat(sprintf("Removing columns  :\n %s\n\n", opt$s.col.rem))


# store locations of all csv files in the output folder
s.files = list.files(path = file.path(params$s.dir.data), 
                     pattern = paste0(params$s.file.data, "$"),
                     recursive = TRUE, 
                     full.names = TRUE)
cat("Merging files:\n")
cat(s.files)
cat("\n")

dt.all = do.call(rbind, lapply(s.files, fread))

# Remove columns according to input params
if (length(params$s.col.rem) > 0 )
  dt.all[, c(params$s.col.rem) := NULL]

# check whether the list of columns to remove provided as the f-n parameter
# contains column names in the data table
if (!is.null(params$s.col.rem)) {
  loc.col.rem = intersect(names(dt.all), params$s.col.rem)
  
  # remove columns if the list isn't empty
  if (length(params$s.col.rem) > 0)
    dt.all[, (params$s.col.rem) := NULL]
}


# write merged dataset
write.csv(dt.all, file = file.path(params$s.dir.out, params$s.file.data), row.names = F) 

