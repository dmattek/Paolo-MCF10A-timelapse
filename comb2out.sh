# Call R script that combines files with 2-line header

#!/bin/bash

DIR=/opt/local/misc-improc/Paolo-MCF10A-timelapse

runrscript.sh $DIR/combine2lineHeaderOutput.R $@
