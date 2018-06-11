# Loads CP output (1-line header) and the output of MATLAB's LAP implementation
# The matlab output from xxx_conn.csv is the output of tracksFinal(1:end).tracksFeatIndxCG
# that contains indices of objects from every frame that form a tracks

require(data.table)

args <- commandArgs(TRUE)

# params
params = list()

## User-defined input

# Path to CP output
# This directory is the root for all following directories
# E.g. myexp1/cp.out1/output/out_0001
params$s.dir.data = args[1]

#params$s.dir.data = '/Volumes/imaging.data/Paolo/MCF10A_TimeLapse/2018-03-26_MCF10Amutants_H2B-miRFP_ERKKTR-Turq_FoxO-NeonGreen_40xAir_T5min_Stim15min-1ngmlEGF_24h-starving+CO2/cp.out2/output/out_0001'

# Core of the file name with CP output, e.g. objNuclei_1line
params$s.file.core = args[2]
#params$s.file.core = 'objNuclei_1line'

# Directory, relative to root, to LAP output, e.g. tracksXY_objNuclei_1line
params$s.dir.tracks = args[3]
#params$s.dir.tracks = 'trackXY_objNuclei_1line'

# minimum track length
params$tracklen = as.integer(args[4])
#params$tracklen = 10

cat("Working directory: ", params$s.dir.data, "\n")
cat("CP out file core : ", params$s.file.core, "\n")
cat("LAP output dir   : ", params$s.dir.tracks, "\n")
cat("Minimum track len: ", params$tracklen, "\n")

## Create paths based on user input

# file with output from CP segmentation (must be a 1-line header file)
params$s.file.data.cp = paste0(params$s.file.core, '.csv')

# suffix for the output file with clean tracks
params$s.file.track.suff = '_clean_tracks.csv'


# column names
params$s.well = 'Image_Metadata_Well'
params$s.site = 'Image_Metadata_Site'
params$s.time = 'Image_Metadata_T'
params$s.objnum.con = 'ObjectNumber'
params$s.objnum.cp = paste0(params$s.file.core, '_ObjectNumber')
params$s.track = 'track_id'
params$s.trackuni = paste0(params$s.track, "_uni")


# switch variable for data output
# set FALSE if you don't want processed data to be written to files
params$b.data.out = TRUE


cat('Setting current directory to:\n')
cat(params$s.dir.data, '\n\n')
setwd(params$s.dir.data)

# file with track connectivities
s.track.files = list.files(file.path(params$s.dir.data, params$s.dir.tracks), "*.csv")

params$s.file.data.con = s.track.files[s.track.files %like% 'conn']
params$s.file.data.seq = s.track.files[s.track.files %like% 'seq']


# load data
dt.cp  = fread(file.path(params$s.dir.data, params$s.file.data.cp))
dt.con = fread(file.path(params$s.dir.data, params$s.dir.tracks, params$s.file.data.con))
dt.seq = fread(file.path(params$s.dir.data, params$s.dir.tracks, params$s.file.data.seq))



# Continue!
# adjust the script for situations where Metadata_Well is missing

# Matlab output is entirely numeric
# Metadata_Well column contains numbers that enumnerate consecutive wells from the original table

# check whether CP output contains MEtadata_Well

v.wells = unique(dt.cp[[params$s.well]])
if (is.na(v.wells)) {
  v.wells = 0
  b.well = 0
} else {
  b.well = 1
}

print(v.wells)

dt.wells = data.table(tmp1 = v.wells, 
                      tmp2 = 1:length(v.wells))
setnames(dt.wells, c(params$s.well, paste0(params$s.well, '_num')))

# add a column with proper well names
print(dt.con)
print(dt.wells)
dt.con = merge(dt.con, dt.wells)

print("merge 1")
print(b.well)
# merge connectivities with data
# dt.con holds the output from MATLAB with object numbers that belong to individual tracks
# Each of these object numbers is merged with data from CP output
print(names(dt.con))
print(names(dt.cp))
if (b.well)
  dt.concp = merge(dt.con, dt.cp, 
      by.x = c(params$s.well, params$s.site, params$s.time, params$s.objnum.con), 
      by.y = c(params$s.well, params$s.site, params$s.time, params$s.objnum.cp), 
      all.x = T) else
  dt.concp = merge(dt.con, dt.cp,
      by.x = c(params$s.site, params$s.time, params$s.objnum.con),
      by.y = c(params$s.site, params$s.time, params$s.objnum.cp),
      all.x = T)

if (b.well)
  setkeyv(dt.concp, c(params$s.well, params$s.site, params$s.track)) else
  setkeyv(dt.concp, c(params$s.site, params$s.track))

# add unique track id
if (b.well)
  dt.concp[, (params$s.trackuni) := paste0(get(params$s.well), '_', get(params$s.site), '_', get(params$s.track))] else
dt.concp[, (params$s.trackuni) := paste0(get(params$s.site), '_', get(params$s.track))]

# calculate length of tracks (end - start); might include breaks
dt.tracklen = dt.concp[, .N, by = c(params$s.trackuni)]

# list of track ids that are longer than the threshold params$tracklen
v.longtrackid = dt.tracklen[N > params$tracklen, get(params$s.trackuni)]

# get only tracks longer than the threshold params$tracklen
dt.concp.sub = dt.concp[get(params$s.trackuni) %in% v.longtrackid]

if (b.well)
  setkeyv(dt.concp.sub, c(params$s.well, params$s.site, params$s.track)) else
setkeyv(dt.concp.sub, c(params$s.site, params$s.track))



# save a reduced dataset with:
# Image_Metadata_Well Image_Metadata_Site Image_Metadata_T
# track_id - track ID from u-track (it's unique per analysis; if analysis with u-track was performed on the entire dataset, track_id is unique)
# condAll - experimental conditions from experimentDescription.xlsx
# all measurements as in the full data set
# ONLY CELLS with tracks longer than the threshold params$tracklen
v.meascol = names(dt.concp.sub)[names(dt.concp.sub) %like% 'obj']


if (b.well)
write.csv(x = dt.concp.sub[, (c(params$s.well, params$s.site, params$s.time, params$s.track, params$s.trackuni, params$s.pm.condall, v.meascol)), with = FALSE], 
          file = file.path(params$s.dir.data, paste0(params$s.file.core, params$s.file.track.suff)), 
          row.names = F, quote = F) else
write.csv(x = dt.concp.sub[, (c(params$s.site, params$s.time, params$s.track, params$s.trackuni, params$s.pm.condall, v.meascol)), with = FALSE],
          file = file.path(params$s.dir.data, paste0(params$s.file.core, params$s.file.track.suff)),
          row.names = F, quote = F)
