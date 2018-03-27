# loads original CP output and the output of MATLAB's LAP implementation
# The matlab output from xxx_conn.csv is the output of tracksFinal(1:end).tracksFeatIndxCG
# that contains indices of objects from every frame that form a tracks

require(data.table)
require(tca)
require(Hmisc) # for smean.cl.boot
require(xlsx)
require(plotly)

# params
params = list()

# name of the folder with merged CP output
params$s.dir.data = '.'
params$s.dir.tracks = 'trackXY_objNuclei_'

# name of the folder with plots
params$s.dir.plots = 'plots'

params$b.plot.out = T

params$n.plot1.w = 18
params$n.plot1.h = 30

params$n.plot2.w = 20
params$n.plot2.h = 12


# name of the folder with plate map
params$s.dir.pm = '..'

# file with merged output from CP segmentation
params$s.file.data.cp = 'objNuclei.csv'

params$s.file.pm = 'experimentDescription.xlsx'

# file with track connectivities
params$s.file.data.con = 'objNuclei_conn.csv'
params$s.file.data.seq = 'objNuclei_seq.csv'
params$s.file.data.tr = 'objNuclei_tracks.csv'


# column names
params$s.well = 'Image_Metadata_Well'
params$s.site = 'Image_Metadata_Site'
params$s.time = 'Image_Metadata_T'
params$s.objnum.con = 'ObjectNumber'
params$s.objnum.cp = 'objNuclei_ObjectNumber'
params$s.track = 'track_id'
params$s.trackuni = paste0(params$s.track, "_uni")
params$s.meas = 'objCytoRing_Intensity_MeanIntensity_imKTR / objNuclei_Intensity_MeanIntensity_imKTR'
params$s.pm.condall = 'condAll'

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
params$s.currdirr = '~/Projects/Olivier/Paolo/2018-01-14_2018-01-18_merged/cp.out'
#params$s.currdirr = '~/Projects/Olivier/Paolo/2017-12-20_MCF10Amutants_H2B-miRFP_ERKKTR-mTurquiose_20xAir_T30s_noStim/cp3.out/'

# load data
dt.cp = fread(file.path(params$s.currdirr, params$s.dir.data, params$s.file.data.cp))
dt.con = fread(file.path(params$s.currdirr, params$s.dir.data, params$s.dir.tracks, params$s.file.data.con))
dt.seq = fread(file.path(params$s.currdirr, params$s.dir.data, params$s.dir.tracks, params$s.file.data.seq))

# Plate map
dt.pm = as.data.table(read.xlsx(file.path(params$s.currdirr, params$s.dir.pm, params$s.file.pm), 
                                sheetIndex = 1, startRow = 3, colIndex = 1:7, header = TRUE, 
                                as.data.frame = TRUE, 
                                stringsAsFactors=FALSE))

# remove NAs from the plate map
# sometimes an NA column appears at the end; remove
dt.pm = dt.pm[, names(dt.pm)[!(names(dt.pm) %like% 'NA')], with = FALSE]

# sometimes an NA row appears at the end; remove
dt.pm = dt.pm[dt.pm[, !Reduce('&', lapply(.SD, is.na))]]

#remove zeroes from well names because main data table doesn't have them
dt.pm[, Well := gsub('0', '', Well)]

setkeyv(dt.pm, c('Well', 'Position'))

# add combined condition
dt.pm[, coltmp := paste0(Cell_type, '_',  Stimulation_treatment, '_', Stimulation_intensity)]
setnames(dt.pm, 'coltmp', params$s.pm.condall)

# remove unnecessary columns
dt.pm[, c('Cell_type',
          'Stimulation_treatment',
          'Stimulation_intensity',
          'Stimulation_duration',
          'Acquisition_frequency_min') := NULL]



# for comparison
dt.tracks = fread(file.path(params$s.currdirr, params$s.dir.data, params$s.dir.tracks, params$s.file.data.tr))

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

# tracks with cyto ring = 0
v.cytoringeq0 = unique(dt.concp[(get(params$s.trackuni) %in% v.longtrackid) & (objCytoRing_Intensity_MeanIntensity_imKTR == 0), get(params$s.trackuni)])

cat(sprintf('Tracks with cytoRing=0 out of tracks longer than %d time units: %d / %d', params$tracklen, length(v.cytoringeq0), length(v.longtrackid)))


# get only tracks longer than the threshold params$tracklen and those with cytoring mean int > 0
dt.concp.sub = dt.concp[get(params$s.trackuni) %in% setdiff(v.longtrackid, v.cytoringeq0)]

setkeyv(dt.concp.sub, c(params$s.well, params$s.site, params$s.track))

# add plate map data
dt.concp.sub = merge(dt.concp.sub, dt.pm, by.x = c(params$s.well, params$s.site), by.y = c('Well', 'Position'))


# save a reduced dataset with:
# Image_Metadata_Well Image_Metadata_Site Image_Metadata_T
# track_id - track ID from u-track (it's unique per analysis; if analysis with u-track was performed on the entire dataset, track_id is unique)
# condAll - experimental conditions from experimentDescription.xlsx
# all measurements as in the full data set
# ONLY CELLS with tracks longer than the threshold params$tracklen and those with cytoring mean int > 0
v.meascol = names(dt.concp.sub)[names(dt.concp.sub) %like% 'obj']
write.csv(x = dt.concp.sub[, (c(params$s.well, params$s.site, params$s.time, params$s.track, params$s.pm.condall, v.meascol)), with = FALSE], 
          file = file.path(params$s.currdirr, params$s.dir.data, gsub('.csv', '_clean_tracks.csv', params$s.file.data.cp)), 
          row.names = F)



# select first N tracks from every condition
v.firstNtracks = dt.concp.sub[, .(track_id_uni = head(unique(get(params$s.trackuni)), 20)),  by = c(params$s.pm.condall)][[2]]
dt.concp.sub.20 = dt.concp[get(params$s.trackuni) %in% v.firstNtracks]
dt.concp.sub.20 = merge(dt.concp.sub.20, dt.pm, by.x = c(params$s.well, params$s.site), by.y = c('Well', 'Position'))


l.p1 = list()
l.p2 = list()

# plot individual trajectories
l.p1$traj_cytoNucErk_perCond = plotTraj(dt.concp.sub, params$s.time, params$s.meas, 
                                        group.arg = paste0(params$s.track, "_uni"),
                                        facet.arg = params$s.pm.condall, facet.ncol.arg = 2, 
                                        summary.arg = 'mean',
                                        maxrt.arg = 800, xaxisbreaks.arg = 60, 
                                        xlab.arg = 'Time (min)', ylab = params$s.meas, ylim.arg = c(0.5, 1.7))

l.p1$traj_cytoNucErk_perCond_first20 = plotTraj(dt.concp.sub.20, params$s.time, params$s.meas, 
                                                group.arg = paste0(params$s.track, "_uni"),
                                                facet.arg = params$s.pm.condall, facet.ncol.arg = 2, 
                                                summary.arg = 'mean',
                                                maxrt.arg = 800, xaxisbreaks.arg = 60, 
                                                xlab.arg = 'Time (min)', ylab = params$s.meas, ylim.arg = c(0.5, 1.7))

l.p1$traj_cellErk_perCond_first20 = plotTraj(dt.concp.sub.20, params$s.time, 'objCells_Intensity_MeanIntensity_imKTR', 
                                             group.arg = paste0(params$s.track, "_uni"),
                                             facet.arg = params$s.pm.condall, facet.ncol.arg = 2, 
                                             summary.arg = 'mean',
                                             maxrt.arg = 800, xaxisbreaks.arg = 60, 
                                             xlab.arg = 'Time (min)', ylab = 'objCells_Intensity_MeanIntensity_imKTR', ylim.arg = c(0.1, 0.3))




# plot mean + 95% CI for all together
dt.concp.sub.mean = dt.concp.sub[, as.list(smean.cl.normal(objCytoRing_Intensity_MeanIntensity_imKTR / objNuclei_Intensity_MeanIntensity_imKTR)), 
                                 by = c(params$s.pm.condall, params$s.time)]


calcTrajCI(dt.concp.sub, params$s.meas)


l.p2$trajMean_cytoNucErk_perCond = plotTrajRibbon(dt.concp.sub.mean, params$s.time, 'Mean', 
                                                  group.arg = params$s.pm.condall,
                                                  xlab.arg = 'Time (min)', ylab = params$s.meas, legendpos.arg = 'right')

ggplotly(l.p2$trajMean_cytoNucErk_perCond)


if (params$b.plot.out) {
  
  # Create directory for plots in the currenty working directory
  s.path.tmp = file.path(params$s.currdirr, params$s.dir.plots)
  if(!dir.exists(s.path.tmp))
    dir.create(s.path.tmp) else 
      cat('Directory\n', s.path.tmp, '\nalready exists!')
  
  # all plots
  lapply(names(l.p1),
         function(x)
           ggsave(
             filename = paste0(s.path.tmp, '/', x, ".pdf"),
             plot = l.p1[[x]],
             width = params$n.plot1.w,
             height = params$n.plot1.h
           ))
  
  lapply(names(l.p2),
         function(x)
           ggsave(
             filename = paste0(s.path.tmp, '/', x, ".pdf"),
             plot = l.p2[[x]],
             width = params$n.plot2.w,
             height = params$n.plot2.h
           ))
  
  
}



# check
dt.tmp.1 = dt.concp[get(params$s.well) == 'A2' & get(params$s.site) == 0 & track_id == 500]
dt.tmp.2 = dt.tracks[get(params$s.well) == 'A2' & get(params$s.site) == 0 & track_id == 500]


