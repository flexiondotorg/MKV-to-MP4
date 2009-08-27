#!/bin/bash
#
# License
#
# Creates a PS3 or Xbox 360 compatible MPEG-4 from Matroska
# Copyright (c) 2009 Flexion.Org, http://flexion.org/
#
# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation
# files (the "Software"), to deal in the Software without
# restriction, including without limitation the rights to use,
# copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following
# conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.

IFS=$'\n'
VER="1.2"

echo "MKV-to-MP4 v${VER} - Creates a PS3 or Xbox 360 compatible MPEG-4 from Matroska."
echo "Copyright (c) 2009 Flexion.Org, http://flexion.org. MIT License" 
echo

function usage {
    echo
	echo "Usage"
    echo "  ${0} movie.mkv [--yes] [--stereo] [--faac] [--mp4creator] [--split] [--keep] [--help]"
    echo ""
    echo "You can also pass several optional parameters"
    echo "  --yes        : Answer Yes to all prompts."
    echo "  --stereo     : Force a stereo down mix."
    echo "  --faac       : Force the use of faac, even if NeroAacEnc is available."
    echo "  --mp4creator : Force the use of mp4creator instead of MP4Box."    
    echo "  --split      : If required, the output will be split at a boundary less than"
    echo "                 4GB for FAT32 compatibility"    
    echo "  --keep       : Keep the intermediate files"
    echo "  --help       : This help."    
    echo
    exit 1
}

# Pass in the .mkv filename
function get_info {	
	MKV_FILENAME=${1}
	
	local MKV_TRACKS=`mktemp`
	mkvmerge -i ${MKV_FILENAME} > ${MKV_TRACKS}
	local MKV_INFO=`mktemp`
	mkvinfo ${MKV_FILENAME} > ${MKV_INFO}

	# Get the track ids for audio/video assumes one audio and one video track currently.
	VIDEO_ID=`grep video ${MKV_TRACKS} | cut -d' ' -f3 | sed 's/://'`
	AUDIO_ID=`grep audio ${MKV_TRACKS} | cut -d' ' -f3 | sed 's/://'`
	SUBS_ID=`grep subtitles ${MKV_TRACKS} | cut -d' ' -f3 | sed 's/://'`

	# Get the audio/video format. Strip the V_, A_ and brackets.
	VIDEO_FORMAT=`grep video ${MKV_TRACKS} | cut -d' ' -f5 | sed 's/(\|V_\|)//g'`
	AUDIO_FORMAT=`grep audio ${MKV_TRACKS} | cut -d' ' -f5 | sed 's/(\|A_\|)//g'`

	# Are there any subtitles in the .mkv
	if [ -z ${SUBS_ID} ]; then
		SUBS_FORMAT=""
	else
		SUBS_FORMAT=`grep subtitles ${MKV_TRACKS} | cut -d' ' -f5 | sed 's/(\|S_\|)//g'`
	fi

	# Get the video frames per seconds (FPS), number of audio channels and audio sample rate.
	if [ $VIDEO_ID -lt $AUDIO_ID ]; then
	    # Video is before Audio track
    	VIDEO_FPS=`grep fps ${MKV_INFO} | sed -n 1p | cut -d'(' -f2 | cut -d' ' -f1`
	else
    	# Video is after Audio track
	    VIDEO_FPS=`grep fps ${MKV_INFO} | sed -n 2p | cut -d'(' -f2 | cut -d' ' -f1`
	fi

	VIDEO_WIDTH=`grep "Pixel width" ${MKV_INFO} | cut -d':' -f2 | sed 's/ //g'`
	VIDEO_HEIGHT=`grep "Pixel height" ${MKV_INFO} | cut -d':' -f2 | sed 's/ //g'`

	# Get the sample rate
	AUDIO_RATE=`grep -A 1 "Audio track" ${MKV_INFO} | sed -n 2p | cut -c 27-31`        

	# Get the number of channels
	AUDIO_CH=`grep Channels ${MKV_INFO} | sed -e 1q | cut -d':' -f2 | sed 's/ //g'`
	
	# If there are not 6 audio channels or forcing stereo output is enabled, the set the channel to 2
	if [ ${AUDIO_CH} -ne 6 ] || [ ${FORCE_2CH} -eq 1 ]; then
		AUDIO_CH="2"
	fi
	
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
	rm ${MKV_TRACKS} 2>/dev/null
	rm ${MKV_INFO} 2>/dev/null
}

function extract_streams {	
	VIDEO_FILENAME=${FILENAME}.h264
    AUDIO_FILENAME="${FILENAME}.${AUDIO_FORMAT}"         		
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
	    rm ${VIDEO_FILENAME} 2> /dev/null
    
    	# Do the extract, extracting the subtitles if they were detected.
		if [ -z ${SUBS_ID} ]; then
			mkvextract tracks ${MKV_FILENAME} ${VIDEO_ID}:${VIDEO_FILENAME} ${AUDIO_ID}:${AUDIO_FILENAME}
		else
			mkvextract tracks ${MKV_FILENAME} ${VIDEO_ID}:${VIDEO_FILENAME} ${AUDIO_ID}:${AUDIO_FILENAME} ${SUBS_ID}:${SUBS_FILENAME} 
		fi	
	fi    	
}

function convert_video {
	# Check the video profile. The PS3 supports profile 4.1.
	local VIDEO_PROFILE=`file ${FILENAME}.h264 | cut -d'@' -f2 | sed 's/ //g'`

	echo "Converting Video"
	# If the video profile is 5.1, convert it to 4.1
	if [ "${VIDEO_PROFILE}" == "L51" ]; then
	    echo " - Video profile is ${VIDEO_PROFILE}"
	    echo " - Converting to profile L41, this will take but a second..."    
	    python -c "f=open('${VIDEO_FILENAME}','r+b'); f.seek(7); f.write('\x29'); f.close()"
   
    	    # Lets check our video profile again, to be sure the conversion worked.
    	    local NEW_VIDEO_PROFILE=`file ${FILENAME}.h264 | cut -d'@' -f2 | sed 's/ //g'`
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
	if [ ! -z ${SUBS_ID} ] && [ ${FORCE_MP4CREATOR} -eq 0 ] ; then
		echo "Converting subtitles"
		rm ${FILENAME}.ttxt 2>/dev/null
		MP4Box -ttxt ${SUBS_FILENAME}
	fi	
}

# Pass in how many audio channels to encode
function convert_audio {
                          
    if [ ${AUDIO_CH} -eq 2 ]; then
        echo "Converting ${AUDIO_CH}ch ${AUDIO_FORMAT} to Stereo MPEG4-AAC"        				    
		FAAC_QUALITY="120"
		NERO_QUALITY="0.5"        
    else
        echo "Converting ${AUDIO_CH}ch ${AUDIO_FORMAT} to Multi-channel MPEG4-AAC"                    
		FAAC_QUALITY="210"	
		NERO_QUALITY="0.5"		        
    fi    
                    
    AAC_FILENAME="${FILENAME}_${AUDIO_CH}ch.aac"    
    M4A_FILENAME="${FILENAME}_${AUDIO_CH}ch.m4a"
            
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
        rm ${M4A_FILENAME} 2>/dev/null

        if [ ${AUDIO_CH} -eq 6 ]; then
    		if [ ${FORCE_FAAC} -eq 1 ]; then            
                # Preserve 5.1 and use faac
    	        if [ "${AUDIO_FORMAT}" == "AC3" ]; then			        	    		    	            
                    ffmpeg -i "${AUDIO_FILENAME}" -f ac3 -acodec pcm_s16le - | sox -t raw -s -b 16 -c${AUDIO_CH} -r${AUDIO_RATE} - -t wav - remix 1 3 2 6 4 5 | faac -q ${FAAC_QUALITY} -o ${M4A_FILENAME} -w -P -C ${AUDIO_CH} -I 1,2 -X -R ${AUDIO_RATE} --mpeg-vers 4 -
    	        else
                    ffmpeg -i "${AUDIO_FILENAME}" -f dts -acodec pcm_s16le - | sox -t raw -s -b 16 -c${AUDIO_CH} -r${AUDIO_RATE} - -t wav - | faac -q ${FAAC_QUALITY} -o ${M4A_FILENAME} -w -P -C ${AUDIO_CH} -I 1,2 -X -R ${AUDIO_RATE} --mpeg-vers 4 -
    	        fi
    		else
    		    # Preserve 5.1 and use neroAacEnc
    	        if [ "${AUDIO_FORMAT}" == "AC3" ]; then			        	    		
                    ffmpeg -i "${AUDIO_FILENAME}" -f ac3 -acodec pcm_s16le - | sox -t raw -s -b 16 -c${AUDIO_CH} -r${AUDIO_RATE} - -t wav - remix 1 3 2 6 4 5 | neroAacEnc -q ${NERO_QUALITY} -lc -ignorelength -if - -of ${M4A_FILENAME}
    	        else
                    ffmpeg -i "${AUDIO_FILENAME}" -f dts -acodec pcm_s16le - | sox -t raw -s -b 16 -c${AUDIO_CH} -r${AUDIO_RATE} - -t wav - | neroAacEnc -q ${NERO_QUALITY} -lc -ignorelength -if - -of ${M4A_FILENAME}                                      
    	        fi    		
    		fi
        else            
    		if [ ${FORCE_FAAC} -eq 1 ]; then            
                # Downmix to stereo and use faac
                ffmpeg -i "${AUDIO_FILENAME}" -f u16le -acodec pcm_s16le - | sox -t raw -s -b 16 -c${AUDIO_CH} -r${AUDIO_RATE} - -t wav - | faac -q ${FAAC_QUALITY} -o ${M4A_FILENAME} -w -P -C ${AUDIO_CH} -X -R ${AUDIO_RATE} --mpeg-vers 4 -
    		else
    		    # Downmix to stereo and use neroAacEnc
                ffmpeg -i "${AUDIO_FILENAME}" -f u16le -acodec pcm_s16le - | sox -t raw -s -b 16 -c${AUDIO_CH} -r${AUDIO_RATE} - -t wav - | neroAacEnc -q ${NERO_QUALITY} -lc -ignorelength -if - -of ${M4A_FILENAME}
    		fi
        fi                     
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
	
    	rm "${MP4_FILENAME}" 2>/dev/null
    	
		# OK, pack the MPEG-4 and include subtitles if we have any.		
		if [ -z ${SUBS_ID} ]; then
		    if [ ${FORCE_MP4CREATOR} -eq 1 ]; then
        		echo " - Extracting audio from MP4 container..."
                mp4creator --extract=1 "${M4A_FILENAME}" "${AAC_FILENAME}"		    
                mp4creator --create="${VIDEO_FILENAME}" -r ${VIDEO_FPS} "${MP4_FILENAME}"
                mp4creator --create="${AAC_FILENAME}" "${MP4_FILENAME}"		    
		    else
    			MP4Box -fps ${VIDEO_FPS} -add ${VIDEO_FILENAME} -add ${M4A_FILENAME} -new ${MP4_FILENAME}		            
            fi    			
		else
   		    if [ ${FORCE_MP4CREATOR} -eq 1 ]; then		
        		echo " - Extracting audio from MP4 container..."
                mp4creator --extract=1 "${M4A_FILENAME}" "${AAC_FILENAME}"   		    
                mp4creator --create="${VIDEO_FILENAME}" -r ${VIDEO_FPS} "${MP4_FILENAME}"
                mp4creator --create="${AAC_FILENAME}" "${MP4_FILENAME}"	   		    
   		    else
    			MP4Box -fps ${VIDEO_FPS} -add ${VIDEO_FILENAME} -add ${M4A_FILENAME} -add ${TTXT_FILENAME} -new ${MP4_FILENAME}					
            fi    			
		fi			
	fi        

	# Remove the transient files
    if [ ${FORCE_KEEP} -eq 0 ]; then	
    	echo "Removing temporary files"
	    echo " - ${VIDEO_FILENAME}"
    	rm ${VIDEO_FILENAME} 2>/dev/null
	    echo " - ${MKV_PART_FILENAME}"
    	rm ${MKV_PART_FILENAME} 2>/dev/null
	    echo " - ${M4A_FILENAME}"	
    	rm ${M4A_FILENAME} 2>/dev/null
	    echo " - ${AAC_FILENAME}"	
    	rm ${AAC_FILENAME} 2>/dev/null
	    #rm ${SUBS_FILENAME} 2>/dev/null
    	rm ${TTXT_FILENAME} 2>/dev/null
    fi    	
}

# Define the commands we will be using. If you don't have them, get them! ;-)
REQUIRED_TOOLS=`cat << EOF
cut
echo
faac
ffmpeg
file
grep
mkfifo
mktemp
mkvextract
mkvinfo
mkvmerge
mp4creator
python
rm
sed
sox
stat
MP4Box
EOF`

for REQUIRED_TOOL in ${REQUIRED_TOOLS}
do
    # Is the required tool in the path?
    which ${REQUIRED_TOOL} >/dev/null  
         
    if [ $? -eq 1 ]; then
        echo "ERROR! \"${REQUIRED_TOOL}\" is missing. ${0} requires it to operate."
        echo "       Please install \"${REQUIRED_TOOL}\"."
        exit 1      
    fi        
done

# Get the first parameter passed in and validate it.
if [ $# -lt 1 ]; then
    echo "ERROR! ${0} requires a .mkv file as input."	
	usage
elif [ "${1}" == "-h" ] || [ "${1}" == "--h" ] || [ "${1}" == "-help" ] || [ "${1}" == "--help" ] || [ "${1}" == "-?" ]; then
    usage
else    
    MKV_FILENAME=`basename ${1}`
            
    # Is the .mkv a real Matroska file?
    MKV_VALID=`file ${MKV_FILENAME} | grep Matroska`
    if [ -z "${MKV_VALID}" ]; then
        echo "ERROR! ${0} requires valid a Matroska file as input. \"${1}\" is not a Matroska file."
        usage
    fi	        
    shift
fi

FORCE_YES=0
FORCE_2CH=0
FORCE_FAAC=0
FORCE_SPLIT=0
FORCE_MP4CREATOR=0
FORCE_KEEP=0

# Check for optional parameters
while [ $# -gt 0 ]; 
do	
	case "${1}" in	
		-y|-Y|--yes)
			FORCE_YES=1
            echo "SORRY! Forcing \"Yes\" to all prompts is not implemented."
            shift;;
        -2|-2ch|--2ch|--stereo)
        	FORCE_2CH=1
        	shift;;        	
        -f|-faac|--faac)
        	FORCE_FAAC=1
        	shift;;    
        -c|-mp4creator|--mp4creator)
        	FORCE_MP4CREATOR=1
        	shift;;            	
		-s|--split|-split)
            FORCE_SPLIT=1
            shift;;          	
		-k|--keep|-keep)
            FORCE_KEEP=1
            shift;;          	            
        -h|--h|-help|--help|-?)
            usage;;        	    	           	
       	*)
            echo "ERROR! \"${1}\" is not s supported parameter."
            usage;;                    	
	esac    
done

# Optional tools.
which neroAacEnc >/dev/null  
if [ $? -eq 1 ]; then
    echo "WARNING! 'neroAacEnc' not found. Will use 'faac' instead."
    FORCE_FAAC=1    
fi        

# Strip .mkv from the input file name and clean it so it can be used to define 
# other filenames
FILENAME=`echo ${MKV_FILENAME} | sed 's/.mkv//' | sed 's/\./_/g' | sed 's/-/_/g' | sed 's/ /_/g'`

if [ ${FORCE_SPLIT} -eq 1 ]; then
    # Get the size of the .mkv file in bytes (b)
    MKV_SIZE=`stat -c%s "${MKV_FILENAME}"`

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
else
    SPLIT_SIZE="0"
fi

if [ ${SPLIT_SIZE} -ne 0 ]; then
	echo "Splitting ${MKV_FILENAME} at ${SPLIT_SIZE}K boundary"
	if [ -e "${FILENAME}-part-001.mkv" ]; then
	    read -n 1 -s -p " - WARNING! Detected MKV file parts. Do you want to re-split the MKV file? (y/n) : " SPLIT
	    echo
	else
    	SPLIT="y"
	fi
fi

# Do we need to operate on the split file parts?
if [ ${SPLIT_SIZE} -ne 0 ]; then

	# Split the MKV file is required or requested.
	if [ "${SPLIT}" == "y" ]; then
		mkvmerge -o ${FILENAME}-part.mkv --split ${SPLIT_SIZE}K ${MKV_FILENAME}		
	fi
	
	for MKV_PART_FILENAME in `ls -1 ${FILENAME}-part-00*.mkv` 
	do
		# Set the MKV_FILENAME to the current MKV file part.
		MKV_FILENAME=${MKV_PART_FILENAME}
		# Set FILENAME based on the current MKV file part
		#FILENAME=`echo ${MKV_FILENAME} | sed 's/.mkv//'`
        FILENAME=`echo ${MKV_FILENAME} | sed 's/.mkv//' | sed 's/\./_/g' | sed 's/-/_/g' | sed 's/ /_/g'`		
		get_info ${MKV_FILENAME}
		extract_streams
		convert_video
		convert_subtitles
		convert_audio
		create_mp4
	done
else
	echo "Not splitting ${MKV_FILENAME}"
	# Create empty MKV_PART_FILENAME variable
	MKV_PART_FILENAME=""
	get_info ${MKV_FILENAME}
	extract_streams
	convert_video
	convert_subtitles	
	convert_audio
	create_mp4
fi

echo "All Done!"
