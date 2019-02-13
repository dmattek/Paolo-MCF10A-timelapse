require(data.table)
require(tca)


# params
params = list()

# name of the folder with merged CP output
params$s.dir.data = 'output.mer'

# name of the folder with plots
params$s.dir.plots = 'plots'

# file with merged output
params$s.file.data = 'objNuclei_tracks.csv'

# switch variable for data output
# set FALSE if you don't want processed data to be written to files
params$b.data.out = TRUE

# get directory from the command line
args <- commandArgs(TRUE)

if (is.na(args[1]))
  params$s.currdirr = '.' else
    params$s.currdirr = paste0(getwd(), '/', args[1])


cat('Setting current directory to:\n')
cat(params$s.currdirr, '\n\n')
setwd(params$s.currdirr)

# setting path manually
params$s.currdirr = '~/Projects/Olivier/Paolo/2018-01-14_2018-01-18_merged/cp.out'

# Create directory for plots in the currenty working directory
s.path.tmp = file.path(params$s.currdirr, params$s.dir.plots)
if(!dir.exists(s.path.tmp))
  dir.create(s.path.tmp) else 
    cat('Directory\n', s.path.tmp, '\nalready exists!')


# load data
dt = fread(file.path(params$s.currdirr, params$s.dir.data, params$s.file.data))
dt[, idunique := paste0(well, '_', site, '_', id)]

dt.small = dt[sample(nrow(dt), 100000)]

plotTraj(dt.small, 'realtime', '1/y', 
         group.arg = 'idunique',
         facet.arg = 'well', facet.ncol.arg = 4, summary.arg = F)
