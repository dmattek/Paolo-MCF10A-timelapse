# cleans 2-line header output from CP
# converts to a 1-line header
# removes selected columns

args <- commandArgs(TRUE)

# input file
s.f.in = args[1]
  #'/mnt/imaging.data/Paolo/MCF10A_TimeLapse/2018-03-26_MCF10Amutants_H2B-miRFP_ERKKTR-Turq_FoxO-NeonGreen_40xAir_T5min_Stim15min-1ngmlEGF_24h-starving+CO2/cp.out2/output/out_0001/objNuclei.csv'

# output file
s.f.out = args[2]
  #'/mnt/imaging.data/Paolo/MCF10A_TimeLapse/2018-03-26_MCF10Amutants_H2B-miRFP_ERKKTR-Turq_FoxO-NeonGreen_40xAir_T5min_Stim15min-1ngmlEGF_24h-starving+CO2/cp.out2/output/out_0001/objNuclei_1line.csv'
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
dt=freadCSV2lineHeader(s.f.in, s.cols.rm)

write.csv(x = dt, file = s.f.out, row.names = F)
