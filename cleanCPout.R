# cleans 2-line header output from CP
# converts to a 1-line header
# removes selected columns
#
# Example call from command-line
# Rscript cleanCPout.R objNuclei.csv objNuclei_1line.csv

args <- commandArgs(TRUE)

# input file
s.f.in = args[1]

# output file
s.f.out = args[2]

# list of column names to remove
s.cols.rm = c('Image_Metadata_C',
              'Image_Metadata_Channel',
              'Image_Metadata_ChannelName',
              'Image_Metadata_ColorFormat',
              'Image_Metadata_FileLocation',
              'Image_Metadata_Frame',
              'Image_Metadata_Plate', 
              'Image_Metadata_SizeC',
              'Image_Metadata_SizeT', 
              'Image_Metadata_SizeX', 
              'Image_Metadata_SizeY',
              'Image_Metadata_SizeZ', 
              'Image_Metadata_Z', 
              'Image_Metadata_Series')
  
require(tca)
# read a CSV with a 2-line header; 
# remove repeated columns; 
# remove columns according to the list in s.cols.rm
dt=freadCSV2lineHeader(s.f.in, s.cols.rm)

# save file; no row numbers, no quotes around strings
write.csv(x = dt, file = s.f.out, row.names = F, quote = F)
