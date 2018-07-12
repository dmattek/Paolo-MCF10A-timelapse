# Cleans 2-line header output from CP
# Converts to a 1-line header
# Removes selected columns based on a config file provided as an argument
#
# Example call from the command-line
# Rscript cleanCPoutCFG.R lapconfig.csv
# 
# The lapconfig.csv should contain two columns with a header.
# The 1st column should contain parameter name.
# The 2nd column should contain parameter value.
#
# Parameter used from the config file:
# clean_cols - a string (in quotes) with comma-separated column names for removal from the original csv data file, e.g. clean_cols, "Image_Metadata_C,Image_Metadata_Channel"

args <- commandArgs(TRUE)

par = list()

# Path to config csv file
par$s.f.cfg = args[1]

# Path to working directory
par$s.wd = args[2]

if(sum(is.na(c(par$s.f.cfg, par$s.wd))) > 0) {
  stop('Wrong number of parameters! Call: Rscript cleanCPoutCFG.R config_file path_to_wd')
}

## defs
# name of the parameter with columns for removal
par$cfg.file_cpout = 'file_cpout'
par$cfg.file_cpout_1line = "file_cpout_1line"
par$cfg.clean_cols = "clean_cols"
par$csvext = '.csv'

require(tca)
require(data.table)

## read config file
# read the csv file; 2 columns only
dt.cfg = fread(par$s.f.cfg, select = 1:2)

# convert to a list
l.cfg = split(dt.cfg[[2]], dt.cfg[[1]])

# convert strings to appropriate types
l.cfg = tca::convertStringList2Types(l.cfg)

# read a CSV with a 2-line header; 
# remove repeated columns; 
# remove columns according to the list in s.cols.rm


# check whether config file contains "file_cpout" paramater
if(par$cfg.file_cpout %in% names(l.cfg)) {
  par$file_cpout = l.cfg[[par$cfg.file_cpout]]
} else {
  stop(sprintf('Config file does not contain %s parameter, please provide!.', par$cfg.file_cpout))
}

# check whether config file contains "file_cpout_1line" paramater
if(par$cfg.file_cpout_1line %in% names(l.cfg)) {
  par$file_cpout_1line = l.cfg[[par$cfg.file_cpout_1line]]
} else {
  stop(sprintf('Config file does not contain %s parameter, please provide!.', par$cfg.file_cpout_1line))
}

# check whether config file contains "clean_cols" paramater
if(!(par$cfg.clean_cols %in% names(l.cfg))) {
  print(sprintf('Config file does not contain %s parameter; all columns kept.', par$cfg.clean_cols))
  par$clean_cols = NULL
} else {
  # split the string with (multiple) column names to remove into a list of strings
  par$clean_cols = unlist(strsplit(l.cfg[[par$cfg.clean_cols]], ','))
  print(sprintf("Removing columns: %s", par$clean_cols))
}


# read data csv with a 2-line header, remove columns in s.cols.rm
dt = tca::freadCSV2lineHeader(file.path(par$s.wd, par$file_cpout), par$clean_cols)

# save file; no row numbers, no quotes around strings
write.csv(x = dt, file = file.path(par$s.wd, par$file_cpout_1line), row.names = F, quote = F)
