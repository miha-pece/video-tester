#!/bin/bash
# Script for testing integrity of video (audio) files.
# It uses ffmpeg. Put all files in folder, choose folder 
# as first parametre behind -i flag -- that is all.
# Potential errors will be written in log file.

# Made by Miha Peče, ZRC-SAZU

set -o nounset
#set -o xtrace

declare SELEC_FOLDER
declare LOG_FILE="error.log"

# Exit/usage function
function usage {
	tput setaf 2
	echo 
	echo "############################################"
	echo "#  Mandatory arguments:                    #"
    echo "#  -i/--input [FOLDER]                     #"
	echo "#                                          #"
    echo "#  Script for testing integrity of         #"
	echo "#  video, audio files                      #"
	echo "#                                          #"
	echo "############################################"
	echo 
	tput sgr0 # Reseting colors
	echo
	sleep 3
	exit 1
}

# Cheking if arguments were set
if [ ${#@} -eq 0 ]; then
	usage
fi

# First check for help
if [[ $1 == "-h" || $1 == "--help" ]]; then
	usage
fi

set +o nounset # Temporarly off
if [[ $1 == "-i" || $1 == "--input" ]]; then
    if [ -n "$2" ]; then
	    SELEC_FOLDER="$2"
	else
		usage
	fi
else
    usage
fi
set -o nounset

# Checking if folder was set
if [ "$SELEC_FOLDER" == "" ]; then
	usage
fi

if [ ${SELEC_FOLDER:(-1)} != "/" ]; then
	SELEC_FOLDER="${SELEC_FOLDER}/"
fi

# Checking folders
if [ ! -d "$SELEC_FOLDER" ]; then
	tput setaf 1
	echo
	echo "  #############################################"
	echo "  #   Folder with media files doesn't exists  #"
	echo "  #############################################"
	tput sgr0
	exit 1
fi

# Cheking if ffmpeg is installed
ffmpeg -h &> /dev/null

if [ $? -eq 0 ]; then
	echo
  	echo "####################"
	echo "# ffmpeg installed #"
	echo "####################"
else
	tput setaf 1
	echo ""
	echo "  ########################"
	echo "  # ffmpeg seems missing #"
	echo "  ########################"
	tput sgr0
	echo
	exit 1
fi

function test_video {
	# Main logic
	# loglevel 'error' will show only critical errors
    ffmpeg -loglevel warning ${f[@]} -f null - >>$LOG_FILE 2>&1
    echo >>$LOG_FILE 
}

START_TIME=$(date +%s)
echo >$LOG_FILE

for selec_file in "${SELEC_FOLDER}"*; do
	
	# Conditions
	# If folder, load next file
	if [ -d "$selec_file" ]; then
		continue
	fi

	# If not regular file, break
	if [ ! -f "$selec_file" ]; then
	  	echo "  ${selec_file} file is not a regular file"
		usage
	fi

	# If empty file, break
	if [ ! -s "$selec_file" ]; then
	  	echo "  ${selec_file} file has 0 bits"
	    usage
	fi

    echo "Testing file $selec_file" >> $LOG_FILE 
	# ffmpeg input flag + file
	f=("-i" "$selec_file")

    test_video

done

ALL_TIME=$(date +%s)
ALL_TIME=$(( $ALL_TIME - $START_TIME ))

echo
echo -n "Process duration: "
printf "%02d:" $(( $ALL_TIME / 3600 ))
printf "%02d:" $(( ($ALL_TIME % 3600) / 60 ))
printf "%02d\n" $(( $ALL_TIME % 60 ))
echo
echo "Possible errors are logged in $LOG_FILE"