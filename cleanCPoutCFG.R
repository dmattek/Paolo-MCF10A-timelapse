# Cleans 2-line header output from CP
# Converts to a 1-line header
# Removes selected columns based on a config file provided as an argument
#
# Example call from the command-line
# Rscript cleanCPoutCFG.R objNuclei.csv objNuclei_1line.csv lapconfig.csv
# 
# The lapconfig.csv should contain two columns with a header.
# The 1st column should contain parameter name.
# The 2nd column should contain parameter value.
#
# Parameter used from the config file:
# clean_cols - a string (in quotes) with comma-separated column names for removal from the original csv data file, e.g. clean_cols, "Image_Metadata_C,Image_Metadata_Channel"

args <- commandArgs(TRUE)

# input file
s.f.in = args[1]

# output file
s.f.out = args[2]

# Path to config csv file
s.f.cfg = args[3]

if(sum(is.na(c(s.f.in, s.f.out, s.f.cfg))) > 0) {
  stop('Wrong number of parameters! Call: Rscript cleanCPoutCFG.R input_file output_file config_file')
}

## defs
# name of the parameter with columns for removal
s.clean.cols = "clean_cols"

require(tca)
require(data.table)

## read config file
# read the csv file; 2 columns only
dt.cfg = fread(s.f.cfg,select = 1:2)

# convert to a list
l.cfg = split(dt.cfg[[2]], dt.cfg[[1]])

# convert strings to appropriate types
l.cfg = tca::convertStringList2Types(l.cfg)

# read a CSV with a 2-line header; 
# remove repeated columns; 
# remove columns according to the list in s.cols.rm

# check whether config file contains "clean_cols" paramater
if(!(s.clean.cols %in% names(l.cfg))) {
  print(sprintf('Config file does not contain %s parameter; all columns kept.', s.clean.cols))
  s.cols.rm = NULL
} else {
  # split the string with (multiple) column names to remove into a list of strings
  s.cols.rm = unlist(strsplit(l.cfg[[s.clean.cols]], ','))
  print(sprintf("Removing columns: %s", s.cols.rm))
}


# read data csv with a 2-line header, remove columns in s.cols.rm
dt = freadCSV2lineHeader(s.f.in, s.cols.rm)

# save file; no row numbers, no quotes around strings
write.csv(x = dt, file = s.f.out, row.names = F, quote = F)
