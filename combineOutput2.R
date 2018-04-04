# Searches for csv files in all sub-directories of a given directory, merges the files
# and puts them in specified output directory.
# FIles for merging should have a 1-line-header

require(data.table)

args <- commandArgs(TRUE)

# params
params = list()

## User-defined input

# Path to CP output
# This directory is the root for a directory that contains sub-directories
# E.g. myexp1/cp.out1/output
if (is.na(args[1]))
  params$s.dir.data = '.' else
    params$s.dir.data = args[1]

# Core of the file name with CP output, e.g. objNuclei_1line_clean_tracks.csv
if (is.na(args[2]))
  params$s.file.data = 'output.csv' else
    params$s.file.data = args[2]

# Create directory for merged output in the current working directory
params$s.dir.out = paste0(params$s.dir.data, '.mer')
ifelse(!dir.exists(file.path(params$s.dir.out)), 
       dir.create(file.path(params$s.dir.out)), 
       FALSE)


# store locations of all csv files in the output folder
s.files = list.files(path = file.path(params$s.dir.data), 
                     pattern = params$s.file.data, 
                     recursive = TRUE, 
                     full.names = TRUE)

dt.all = do.call(rbind, lapply(s.files, fread))
                               
# write merged dataset
write.csv(dt.all, file = file.path(params$s.dir.out, params$s.file.data), row.names = F) 

