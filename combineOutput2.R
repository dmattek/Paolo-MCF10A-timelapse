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
params$s.dir.data = args[1]

# Core of the file name with CP output, e.g. objNuclei_1line_clean_tracks
params$s.file.core = args[2]

# extension of files with CP output
params$s.file.pattern = '.csv'

if (is.na(args[1]))
  params$s.currdirr = '.' else
    params$s.currdirr = paste0(getwd(), '/', args[1])


if (is.na(args[2]))
  params$s.file.core = 'output'
  
# Create directory for merged output in the current working directory
params$s.dir.output = paste0(params$s.dir.data, '.mer')
ifelse(!dir.exists(file.path(params$s.currdirr, params$s.dir.output)), 
       dir.create(file.path(params$s.currdirr, params$s.dir.output)), 
       FALSE)


# store locations of all csv files in the output folder
s.files = list.files(path = file.path(params$s.currdirr, params$s.dir.data), 
                     pattern = paste0(params$s.file.core, params$s.file.pattern), 
                     recursive = TRUE, 
                     full.names = TRUE)

dt.all = do.call(rbind, lapply(s.files, fread))
                               
# write merged dataset
if (params$b.data.out) {
  write.csv(dt.all, file = file.path(params$s.currdirr, params$s.dir.output, paste0(params$s.file.core, params$s.file.pattern)), row.names = F) 
}
