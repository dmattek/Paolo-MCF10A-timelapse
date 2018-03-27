require(tca)


# params
params = list()

# name of the folder with sub-folders with CP output
params$s.dir.output = 'output'

# extension of files with CP output
params$s.file.pattern = '.csv'

# switch variable for data output
# set FALSE if you don't want processed data to be written to files
params$b.data.out = TRUE

# get directory from the command line
args <- commandArgs(TRUE)

if (is.na(args[1]))
  params$s.currdirr = '.' else
    params$s.currdirr = paste0(getwd(), '/', args[1])

#setwd("/Volumes/imaging.data/Paolo/MCF10A_TimeLapse/2017-12-20_MCF10Amutants_H2B-miRFP_ERKKTR-mTurquiose_20xAir_T30s_noStim/cp3.out")

cat('Setting current directory to:\n')
cat(params$s.currdirr, '\n\n')
setwd(params$s.currdirr)

# Create directory for merged output in the current working directory
params$s.dir.data = paste0(params$s.dir.output, '.mer')
ifelse(!dir.exists(file.path(params$s.currdirr, params$s.dir.data)), dir.create(file.path(params$s.currdirr, params$s.dir.data)), FALSE)

#####
## Read 

#### Step 1: read all CP outputs from separate folders, merge all the output, create one big file withh all outputs

# store locations of all csv files in the output folder
s.files = list.files(path = file.path(params$s.currdirr, params$s.dir.output), pattern = params$s.file.pattern, recursive = TRUE, full.names = TRUE)

# set the name of the merged output file based on file names of individual outputs
if (length(s.files > 0))
  params$s.file.data = gsub('.*/', '', s.files[1]) else
  params$s.file.data = 'data.csv'

# loop through the list of files and read them, and then bind them together in a single file
# remove columns specified in in.col.rem
dt.all = do.call(rbind, lapply(s.files, freadCSV2lineHeader, in.col.rem = c('Image_Metadata_C',
                                                                            'Image_Metadata_ChannelName',
                                                                            'Image_Metadata_ChannelNumber',
                                                                            'Image_Metadata_ColorFormat',
                                                                            'Image_Metadata_FileLocation',
                                                                            'Image_Metadata_Frame',
                                                                            'Image_Metadata_Plate',
                                                                            'Image_Metadata_Series',
                                                                            'Image_Metadata_SizeC',
                                                                            'Image_Metadata_SizeT',
                                                                            'Image_Metadata_SizeX',
                                                                            'Image_Metadata_SizeY',
                                                                            'Image_Metadata_SizeZ',
                                                                            'Image_Metadata_Z')))

# write merged dataset
if (params$b.data.out) {
 write.csv(dt.all, file = file.path(params$s.currdirr, params$s.dir.data, params$s.file.data), row.names = F) 
}


cat('Summary stats of the number of cells per site, per well, per time point:\n')
summary(dt.all[, .N, by = .(Image_Metadata_Well, Image_Metadata_Site, Image_Metadata_T)][, N])
