#!/bin/bash
# Converts a Matroska video file into a PS3 compatible MPEG-4

#TODO!
# - Add option to answer "Yes" to all prompts, useful for scripting.
# - Double check and (possibly) fix faac 5.1 channel encoding.
# - Only work with filename that do not have spaces in the names.

function usage {
	echo "Usage"
    echo "  ${0} movie.mkv"
    echo ""
    echo "You can also pass several optional parameters"
    echo "  -y    : Answer Yes to all prompts."
    echo "  -2ch  : Force a stereo down mix."
    echo "  -faac : Force the use of faac, even if NeroAacEnc is available."
    echo
    exit 1
}

# Check that the required tools are available.
# One parameters taken as input
#  - $1 : The unpathed tool name.
#  - $2 : Specify that the tool is "required" or "optional"
function validate_tool {
	local TOOL=${1}
	local REQUIREMENT=${2}	
	local TOOL_PATH=`which ${TOOL}`
	
	# If the tool is required, how do we handle that?
	if [ "${REQUIREMENT}" == "required" ]; then
		if [ -z ${TOOL_PATH} ]; then
			echo " - ERROR! '${TOOL}' was not found in the path."
			echo "   Please install the package that contains '${TOOL}' or compile it or put it in the path."
			exit 1
		else
			echo ${TOOL_PATH}
		fi		
	else # The tool is option, what do we do?
		if [ -z ${TOOL_PATH} ]; then
			echo #return nothing
		else
			echo ${TOOL_PATH}
		fi	
	fi
}

# Pass in the .mkv filename
function get_info {	
	MKV_FILENAME=${1}
	
	local MKV_TRACKS=`${CMD_MKTEMP}`
	${CMD_MKVMERGE} -i ${MKV_FILENAME} > ${MKV_TRACKS}
	local MKV_INFO=`${CMD_MKTEMP}`
	${CMD_MKVINFO} ${MKV_FILENAME} > ${MKV_INFO}

	# Get the track ids for audio/video assumes one audio and one video track currently.
	VIDEO_ID=`${CMD_GREP} video ${MKV_TRACKS} | ${CMD_CUT} -d' ' -f3 | ${CMD_SED} 's/://'`
	AUDIO_ID=`${CMD_GREP} audio ${MKV_TRACKS} | ${CMD_CUT} -d' ' -f3 | ${CMD_SED} 's/://'`
	SUBS_ID=`${CMD_GREP} subtitles ${MKV_TRACKS} | ${CMD_CUT} -d' ' -f3 | ${CMD_SED} 's/://'`

	# Get the audio/video format. Strip the V_, A_ and brackets.
	VIDEO_FORMAT=`${CMD_GREP} video ${MKV_TRACKS} | ${CMD_CUT} -d' ' -f5 | ${CMD_SED} 's/(\|V_\|)//g'`
	AUDIO_FORMAT=`${CMD_GREP} audio ${MKV_TRACKS} | ${CMD_CUT} -d' ' -f5 | ${CMD_SED} 's/(\|A_\|)//g'`

	# Are there any subtitles in the .mkv
	if [ -z ${SUBS_ID} ]; then
		SUBS_FORMAT=""
	else
		SUBS_FORMAT=`${CMD_GREP} subtitles ${MKV_TRACKS} | ${CMD_CUT} -d' ' -f5 | ${CMD_SED} 's/(\|S_\|)//g'`
	fi

	# Get the video frames per seconds (FPS), number of audio channels and audio sample rate.
	if [ $VIDEO_ID -lt $AUDIO_ID ]; then
	    # Video is before Audio track
    	VIDEO_FPS=`${CMD_GREP} fps ${MKV_INFO} | ${CMD_SED} -n 1p | ${CMD_CUT} -d'(' -f2 | ${CMD_CUT} -d' ' -f1`
	else
    	# Video is after Audio track
	    VIDEO_FPS=`${CMD_GREP} fps ${MKV_INFO} | ${CMD_SED} -n 2p | ${CMD_CUT} -d'(' -f2 | ${CMD_CUT} -d' ' -f1`
	fi

	VIDEO_WIDTH=`${CMD_GREP} "Pixel width" ${MKV_INFO} | ${CMD_CUT} -d':' -f2 | ${CMD_SED} 's/ //g'`
	VIDEO_HEIGHT=`${CMD_GREP} "Pixel height" ${MKV_INFO} | ${CMD_CUT} -d':' -f2 | ${CMD_SED} 's/ //g'`

	# Get the sample rate
	AUDIO_RATE=`${CMD_GREP} -A 1 "Audio track" ${MKV_INFO} | ${CMD_SED} -n 2p | ${CMD_CUT} -c 27-31`        

	# Get the number of channels
	AUDIO_CH=`${CMD_GREP} Channels ${MKV_INFO} | ${CMD_SED} -e 1q | ${CMD_CUT} -d':' -f2 | ${CMD_SED} 's/ //g'`
	
	# If there are not 6 audio channels or forcing stereo output is enabled, the set the channel to 2
	if [ ${AUDIO_CH} -ne 6 ] || [ ${FORCE_2CH} -eq 1 ]; then
		AUDIO_CH="2"
	fi
	
	# Get the mplayer 'aid' for this audio track.
	AUDIO_AID=`${CMD_MPLAYER} ${MKV_FILENAME} -endpos 0 -ao null -vo null 2>/dev/null | ${CMD_GREP} "Track ID ${AUDIO_ID}:" | ${CMD_CUT} -d',' -f2 | ${CMD_SED} 's/ //'`

	# Is the video h264 and audio AC3 or DTS?
	if [ "${VIDEO_FORMAT}" != "MPEG4/ISO/AVC" ]; then
		echo " - ERROR! The Video track is not h264. I can't process ${VIDEO_FORMAT}, please use a different tool."
		exit 1
	elif [ "${AUDIO_FORMAT}" != "DTS" ] && [ "${AUDIO_FORMAT}" != "AC3" ]; then
		echo " - ERROR! The audio track is not DTS or AC3. I can't process ${AUDIO_FORMAT}, please use a different tool."
		exit 1
	else
		echo -e " - Video\t : Track ${VIDEO_ID} and of format ${VIDEO_FORMAT} (${VIDEO_WIDTH}x${VIDEO_HEIGHT} @ ${VIDEO_FPS}fps)"
		echo -e " - Audio\t : Track ${AUDIO_ID} and of format ${AUDIO_FORMAT} with ${AUDIO_CH} channels @ ${AUDIO_RATE}hz"
		if [ -z ${SUBS_ID} ]; then
			echo -e " - Subtitles\t : none"
		else
			# Check the format of the subtitles. If they are not TEXT/UTF8 we can't use them.
			if [ "${SUBS_FORMAT}" != "TEXT/UTF8" ]; then
				SUBS_ID=""
				echo -e " - Subtitles\t : ${SUBS_FORMAT} is not supported, skipping subtitle processing"
			else
				echo -e " - Subtitles\t : Track ${SUBS_ID} and of format ${SUBS_FORMAT}"
			fi
		fi	
	fi
	
	# Clean up the temp files
	${CMD_RM} ${MKV_TRACKS} 2>/dev/null
	${CMD_RM} ${MKV_INFO} 2>/dev/null
}

function extract_video {	
	VIDEO_FILENAME=${FILENAME}.h264
	SUBS_FILENAME=${FILENAME}.srt
	
	echo "Extracting Video"
	# If the extracted video file already exists, prompt the user if we should re-extract
	if [ -e ${VIDEO_FILENAME} ]; then
    	read -n 1 -s -p " - WARNING! Detected ${VIDEO_FILENAME}. Do you want to re-extract the video? (y/n) : " EXTRACT        
	    echo
	else
    	EXTRACT="y"
	fi

	# Extract the tracks, if required.
	if [ "${EXTRACT}" == "y" ]; then
    	# Make sure the output files do not already exist.
	    ${CMD_RM} ${VIDEO_FILENAME} 2> /dev/null
    
    	# Do the extract, extracting the subtitles if they were detected.
		if [ -z ${SUBS_ID} ]; then
			${CMD_MKVEXTRACT} tracks ${MKV_FILENAME} ${VIDEO_ID}:${VIDEO_FILENAME}
		else
			${CMD_MKVEXTRACT} tracks ${MKV_FILENAME} ${VIDEO_ID}:${VIDEO_FILENAME} ${SUBS_ID}:${SUBS_FILENAME} 
		fi	
	fi    	
}

function convert_video {
	# Check the video profile. The PS3 supports profile 4.1.
	local VIDEO_PROFILE=`${CMD_FILE} ${FILENAME}.h264 | ${CMD_CUT} -d'@' -f2 | ${CMD_SED} 's/ //g'`

	echo "Converting Video"
	# If the video profile is 5.1, convert it to 4.1
	if [ "${VIDEO_PROFILE}" == "L51" ]; then
	    echo " - Video profile is ${VIDEO_PROFILE}"
	    echo " - Converting to profile L41, this will take but a second..."    
	    ${CMD_PYTHON} -c "f=open('${VIDEO_FILENAME}','r+b'); f.seek(7); f.write('\x29'); f.close()"
   
    	    # Lets check our video profile again, to be sure the conversion worked.
    	    local NEW_VIDEO_PROFILE=`${CMD_FILE} ${FILENAME}.h264 | ${CMD_CUT} -d'@' -f2 | ${CMD_SED} 's/ //g'`
	    if [ "${NEW_VIDEO_PROFILE}" == "L51" ]; then
    	        echo " - ERROR! The video profile is still L51 which means I couldn't automatically patch it."
	        echo "   You will need to use 'hexedit' to manually change the profile level to L41."
    	    	clean_up
        	exit 1
	    elif [ "${NEW_VIDEO_PROFILE}" == "L41" ]; then
    	        echo " - Video profile is now L41"
	    fi	    
	else
	    echo " - Video profile is ${VIDEO_PROFILE}, no conversion required."
	fi
}

function convert_subtitles {
	TTXT_FILENAME=${FILENAME}.ttxt
	# Convert the subtitles
	if [ ! -z ${SUBS_ID} ]; then
		echo "Converting subtitles"
		${CMD_RM} ${FILENAME}.ttxt 2>/dev/null
		${CMD_MP4BOX} -ttxt ${SUBS_FILENAME}
	fi	
}

# Pass in how many audio channels to encode
function convert_audio {
    
	if [ ${AUDIO_CH} -eq 6 ]; then
		echo "Converting ${AUDIO_CH}ch ${AUDIO_FORMAT} to Multi-channel MPEG4-AAC"                    
	else
   	 	echo "Converting ${AUDIO_CH}ch ${AUDIO_FORMAT} to Stereo MPEG4-AAC"                
	fi
    
    M4A_FILENAME="${FILENAME}_${AUDIO_CH}ch.aac"
    
	# Setup the audio codecs and multi channel mappings    
	if [ "${AUDIO_FORMAT}" == "AC3" ]; then
		# Map the AC3 5.1 channels to the input format of NeroAacEnc and faac
	    local NERO_CHANNELS=",channels=6:6:0:0:1:2:2:1:3:4:4:5:5:3"
    	local FAAC_CHANNELS=",channels=6:6:0:2:1:4:2:3:3:0:4:1:5:5"	    
		local AUDIO_CODEC="ffac3"
		local NERO_QUALITY="-q 0.30"		#	~288kbps = 48kpbs per channel    	
		local FAAC_QUALITY="-q 100 -b 288"	#	 288kbps = 48kbps per channel    			
	else	
		# Map the DTS 5.1 channels to the input format of NeroAacEnc and faac
	    local NERO_CHANNELS=",channels=6:6:0:2:1:0:2:1:3:4:4:5:5:3"
	    local FAAC_CHANNELS=",channels=6:6:0:4:1:2:2:3:3:0:4:1:5:5"	    		
		local AUDIO_CODEC="ffdca"
		local NERO_QUALITY="-q 0.30"		#	~288kbps = 48kpbs per channel    	
		local FAAC_QUALITY="-q 100 -b 288"	#	 288kbps = 48kbps per channel    			
	fi		        
    
    if [ ${AUDIO_CH} -eq 2 ]; then
	    local NERO_CHANNELS=""
	    local FAAC_CHANNELS=""	    		    
		local NERO_QUALITY="-q 0.2"			#	~160kbps = 80kpbs per channel    	
		local FAAC_QUALITY="-q 100 -b 160"	#	 160kbps = 80kbps per channel
    fi
            
    # Does the target file already exist, if so ask the user if we should re-encode.
    if [ -e ${M4A_FILENAME} ]; then    
        read -n 1 -s -p " - WARNING! Detected ${M4A_FILENAME}. Do you want to re-encode the audio? (y/n) : " ENCODE
        echo            
    else 
        ENCODE="y"
    fi
    
    # Encode the audio
    if [ "${ENCODE}" == "y" ]; then         
        # Make sure the output files do not already exist.
        WAV_FILENAME="${FILENAME}.wav"         	
        ${CMD_RM} ${M4A_FILENAME} 2>/dev/null
		${CMD_RM} ${WAV_FILENAME} 2>/dev/null	               	       
       	${CMD_MKFIFO} ${WAV_FILENAME}

		# Which AAC Encoder should we use.
		# - NeroAacEnc is the default unless...
		#    * NeroAacEnc is not available then use 'faac'
	    #    * -faac parameter was set which forces the use 'faac'
		if [ -z "${CMD_NEROAACENC}" ] || [ ${FORCE_FAAC} -eq 1 ] ; then
			echo " - Using '${CMD_FAAC}'"		
		    # faac       : Only recommended for platforms where NeroAacEnc is not available
			local RUN_MPLAYER="${CMD_MPLAYER} ${MKV_FILENAME} ${AUDIO_AID} -ac ${AUDIO_CODEC} -channels ${AUDIO_CH} -af format=s16le${FACC_CHANNELS} -vo null -vc null -ao pcm:fast:waveheader:file=${WAV_FILENAME} -novideo -really-quiet -nolirc"
			${CMD_FAAC} ${FAAC_QUALITY} -o ${M4A_FILENAME} -P -C ${AUDIO_CH} -X -R ${AUDIO_RATE} --mpeg-vers 4 ${WAV_FILENAME} & ${RUN_MPLAYER}
		else
			echo " - Using '${CMD_NEROAACENC}'"		
			local RUN_MPLAYER="${CMD_MPLAYER} ${MKV_FILENAME} ${AUDIO_AID} -ac ${AUDIO_CODEC} -channels ${AUDIO_CH} -af format=s16le${NERO_CHANNELS} -vo null -vc null -ao pcm:fast:waveheader:file=${WAV_FILENAME} -novideo -really-quiet -nolirc"
			${CMD_NEROAACENC} -ignorelength ${NERO_QUALITY} -if ${WAV_FILENAME} -of ${M4A_FILENAME} & ${RUN_MPLAYER}
		fi		       					       				
       	${CMD_RM} ${WAV_FILENAME}      		
    fi
}

function create_mp4 {
	echo "Creating MPEG-4 Container"
	
	MP4_FILENAME="${FILENAME}.mp4"              	
	
	# Does the target file (or part thereof) already exist, if so ask the user if we should re-mux
	if [ -e ${MP4_FILENAME} ] ; then    
		read -n 1 -s -p " - WARNING! Detected ${MP4_FILENAME}. Do you want to re-mux the MPEG-4? (y/n) : " REMUX
	    echo            
	else 
		REMUX="y"
	fi
    
	# Remux the MPEG-4 container
	if [ "${REMUX}" == "y" ]; then	      	
		# OK, pack the MPEG-4 and include subtitles if we have any.		
		if [ -z ${SUBS_ID} ]; then
			${CMD_MP4BOX} -fps ${VIDEO_FPS} -add ${VIDEO_FILENAME} -add ${M4A_FILENAME} -new ${MP4_FILENAME}        
		else	
			${CMD_MP4BOX} -fps ${VIDEO_FPS} -add ${VIDEO_FILENAME} -add ${M4A_FILENAME} -add ${TTXT_FILENAME} -new ${MP4_FILENAME}
		fi			
	fi        

	# Remove the transient files
	echo "Removing temporary files"
	#echo " - ${VIDEO_FILENAME}"
	${CMD_RM} ${VIDEO_FILENAME} 2>/dev/null
	#echo " - ${MKV_PART_FILENAME}"
	${CMD_RM} ${MKV_PART_FILENAME} 2>/dev/null
	#echo " - ${M4A_FILENAME}"	
	${CMD_RM} ${M4A_FILENAME} 2>/dev/null
	${CMD_RM} ${SUBS_FILENAME} 2>/dev/null
	${CMD_RM} ${TTXT_FILENAME} 2>/dev/null
}

# Have we got enough parameters?
if [ $# -lt 1 ]; then
    echo "ERROR! ${0} requires a .mkv file as input, for example:"	
	usage
else
    MKV_FILENAME=${1}
    shift
fi

FORCE_YES=0
FORCE_2CH=0
FORCE_FAAC=0

if [ $# -gt 0 ]; then
	echo "Setting optional parameters"	
fi

# Check for optional parameters
while [ $# -gt 0 ]; 
do	
	case "${1}" in
		-y|--yes)
			FORCE_YES=1
            echo " - Forcing Yes to all prompts (not implemented)"
            shift;;
        -2ch|--2ch|--stereo)
        	FORCE_2CH=1
        	echo " - Forcing a stereo down mix"
        	shift;;        	
        -faac|--faac)
        	FORCE_FAAC=1
        	echo " - Forcing the use of 'faac'"
        	# I suspect that 5.1 conversion sing facc has incorrect channel assignments
        	# Force stereo for the time being.
     	    FORCE_2CH=1
        	echo " - Forcing a stereo down mix"
        	shift;; 
        -help|--help)
        	usage        	           	
	esac    
done

# Define the commands we will be using. If you don't have them, get them! ;-)
CMD_FILE=`validate_tool file required`
CMD_STAT=`validate_tool stat required`
CMD_GREP=`validate_tool grep required`
CMD_CUT=`validate_tool cut required`
CMD_SED=`validate_tool sed required`
CMD_RM=`validate_tool rm required`
CMD_PYTHON=`validate_tool python required`
CMD_MKTEMP=`validate_tool mktemp required`
CMD_MKFIFO=`validate_tool mkfifo required`
CMD_MKVMERGE=`validate_tool mkvmerge required`
CMD_MKVINFO=`validate_tool mkvinfo required`
CMD_MKVEXTRACT=`validate_tool mkvextract required`
CMD_MPLAYER=`validate_tool mplayer required`
CMD_MP4BOX=`validate_tool MP4Box required`
CMD_FAAC=`validate_tool faac required`
CMD_NEROAACENC=`validate_tool neroAacEnc optional`

# Get the track details
echo "Getting Matroska file details"
# Is the .mkv a real Matroska file?
MKV_VALID=`${CMD_FILE} "${MKV_FILENAME}" | ${CMD_GREP} Matroska`
if [ -z "${MKV_VALID}" ]; then
    echo " - ERROR! ${0} requires valid a Matroska file as input. The file you passed is not a Matroska file."
    exit 1
fi	

# Strip .mkv from the input file name so it can be used to define other filenames
FILENAME=`echo "${MKV_FILENAME}" | ${CMD_SED} 's/.mkv//'`

# Get the size of the .mkv file in bytes (b)
MKV_SIZE=`${CMD_STAT} "${MKV_FILENAME}" | ${CMD_GREP} Size | ${CMD_CUT} -f1 | ${CMD_SED} 's/ \|Size://g'`

# The PS3 can't play MP4 files which are bigger than 4GB and FAT32 doesn't like files bigger than 4GB.
# Lets figure out if we need to split the MKV the split size should be in kilo-bytes (kb)
if [ ${MKV_SIZE} -ge 12884901888 ]; then    
	# >= 12gb : Split into 3.5GB chunks ensuring PS3 and FAT32 compatibility
	SPLIT_SIZE="3670016"
elif [ ${MKV_SIZE} -ge 9663676416 ]; then   
	# >= 9gb  : Divide .mkv filesize by 3 and split by that amount
	SPLIT_SIZE=$(((${MKV_SIZE} / 3) / 1024))
elif [ ${MKV_SIZE} -ge 4294967296 ]; then   
	# >= 4gb  : Divide .mkv filesize by 2 and split by that amount
	SPLIT_SIZE=$(((${MKV_SIZE} / 2) / 1024))
else										
	# File is small enough to not require splitting
	SPLIT_SIZE="0"
fi

if [ ${SPLIT_SIZE} -ne 0 ]; then
	echo "Splitting "${MKV_FILENAME}" at ${SPLIT_SIZE}K boundary"
	if [ -e "${FILENAME}-part-001.mkv" ]; then
	    read -n 1 -s -p " - WARNING! Detected MKV file parts. Do you want to re-split the MKV file? (y/n) : " SPLIT
	    echo
	else
    	SPLIT="y"
	fi
fi

# Do we need to operate on the split file parts?
if [ ${SPLIT_SIZE} -ne 0 ]; then

	# Split the MKV file if required or requested.
	if [ "${SPLIT}" == "y" ]; then
		${CMD_MKVMERGE} -o "${FILENAME}"-part.mkv --split ${SPLIT_SIZE}K "${MKV_FILENAME}"
	fi
	
	for MKV_PART_FILENAME in `ls -1 "${FILENAME}"-part-00*.mkv` 
	do
		# Set the MKV_FILENAME to the current MKV file part.
		MKV_FILENAME="${MKV_PART_FILENAME}"
		# Set FILENAME based on the current MKV file part
		FILENAME=`echo "${MKV_FILENAME}" | ${CMD_SED} 's/.mkv//'`
		get_info "${MKV_FILENAME}"
		extract_video
		convert_video
		convert_subtitles
		convert_audio
		create_mp4
	done
else
	echo "Not splitting ${MKV_FILENAME}"
	# Create empty MKV_PART_FILENAME variable
	MKV_PART_FILENAME=""
	get_info "${MKV_FILENAME}"
	extract_video
	convert_video
	convert_subtitles	
	convert_audio
	create_mp4
fi

echo "All Done!"
