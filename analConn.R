# Loads CP output (1-line header) and the output of MATLAB's LAP implementation
# The matlab output from xxx_conn.csv is the output of tracksFinal(1:end).tracksFeatIndxCG
# that contains indices of objects from every frame that form a tracks

require(data.table)

# params
params = list()

# core of the file name with CP output
# tracking output is in a directory build from this core
params$s.file.core = 'objNuclei_'

# name of the folder with CP output
params$s.dir.data = '.'
params$s.dir.tracks = paste0('trackXY_', params$s.file.core)

# file with output from CP segmentation (1-line header file)
params$s.file.data.cp = paste0(params$s.file.core,'.csv')

# file with track connectivities
params$s.file.data.con = paste0(params$s.file.core, '_WellA1_S00_conn.csv')
params$s.file.data.seq = paste0(params$s.file.core, '_WellA1_S00_seq.csv')


# column names
params$s.well = 'Image_Metadata_Well'
params$s.site = 'Image_Metadata_Site'
params$s.time = 'Image_Metadata_T'
params$s.objnum.con = 'ObjectNumber'
params$s.objnum.cp = 'objNuclei_ObjectNumber'
params$s.track = 'track_id'
params$s.trackuni = paste0(params$s.track, "_uni")

# minimum track length
params$tracklen = 10

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
#params$s.currdirr = '~/Projects/Olivier/Paolo/2018-01-14_2018-01-18_merged/cp.out'
#params$s.currdirr = '~/Projects/Olivier/Paolo/2017-12-20_MCF10Amutants_H2B-miRFP_ERKKTR-mTurquiose_20xAir_T30s_noStim/cp3.out/'

# load data
dt.cp = fread(file.path(params$s.currdirr, params$s.dir.data, params$s.file.data.cp))
dt.con = fread(file.path(params$s.currdirr, params$s.dir.data, params$s.dir.tracks, params$s.file.data.con))
dt.seq = fread(file.path(params$s.currdirr, params$s.dir.data, params$s.dir.tracks, params$s.file.data.seq))

# Matlab output is entirely numeric
# Metadata_Well column contains numbers that enumnerate consecutive wells from the original table
v.wells = unique(dt.cp[[params$s.well]])
dt.wells = data.table(tmp1 = v.wells, 
                      tmp2 = 1:length(v.wells))
setnames(dt.wells, c(params$s.well, paste0(params$s.well, '_num')))

# add a column with proper well names
dt.con = merge(dt.con, dt.wells)

# merge connectivities with data
# dt.con holds the output from MATLAB with object numbers that belong to individual tracks
# Each of these object numbers is merged with data from CP output
dt.concp = merge(dt.con, dt.cp, 
      by.x = c(params$s.well, params$s.site, params$s.time, params$s.objnum.con), 
      by.y = c(params$s.well, params$s.site, params$s.time, params$s.objnum.cp), 
      all.x = T)

setkeyv(dt.concp, c(params$s.well, params$s.site, params$s.track))

# add unique track id
dt.concp[, (params$s.trackuni) := paste0(get(params$s.well), '_', get(params$s.site), '_', get(params$s.track))]

# calculate length of tracks (end - start); might include breaks
dt.tracklen = dt.concp[, .N, by = c(params$s.trackuni)]

# list of track ids that are longer than the threshold params$tracklen
v.longtrackid = dt.tracklen[N > params$tracklen, get(params$s.trackuni)]

# get only tracks longer than the threshold params$tracklen
dt.concp.sub = dt.concp[get(params$s.trackuni) %in% v.longtrackid]

setkeyv(dt.concp.sub, c(params$s.well, params$s.site, params$s.track))


# save a reduced dataset with:
# Image_Metadata_Well Image_Metadata_Site Image_Metadata_T
# track_id - track ID from u-track (it's unique per analysis; if analysis with u-track was performed on the entire dataset, track_id is unique)
# condAll - experimental conditions from experimentDescription.xlsx
# all measurements as in the full data set
# ONLY CELLS with tracks longer than the threshold params$tracklen
v.meascol = names(dt.concp.sub)[names(dt.concp.sub) %like% 'obj']
write.csv(x = dt.concp.sub[, (c(params$s.well, params$s.site, params$s.time, params$s.track, params$s.pm.condall, v.meascol)), with = FALSE], 
          file = file.path(params$s.currdirr, params$s.dir.data, gsub('.csv', '_clean_tracks.csv', params$s.file.data.cp)), 
          row.names = F)