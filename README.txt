############################################################
# This project is inactive and archived here for reference #
############################################################

License

Creates a PlayStation 3 or Xbox 360 compatible MPEG-4 from Matroska
Copyright (c) 2009 Flexion.Org, http://flexion.org/

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

Introduction

Creates a PlayStation 3 or Xbox 360 compatible MPEG-4 from Matroska providing 
the video is H.264 and audio is AC3 or DTS. Xbox 360 compatibility requires that
audio is forcibly downmixed to stereo with '--stereo'. AAC 5.1 audio will have 
the correct channel assignments when transcoding from AC3 5.1 and DTS 5.1.

The script does as little re-encoding as possible, only the audio and subtitles
are re-encoded or converted. The script can detects profile 5.1 H.264 and patch 
it to 4.1 in under a second.

Any subtitles in the Matroska are preserved. If 'mp4creator' is used the 
subtitles are extracted stored in a seperate file. If 'MP4Box' is used (default)
the subtitles are converted to GPAC Timed Text and muxed into the resulting 
MPEG-4. The PS3 can't display these subtitles but some software players can. 

The script can optionally split the Matroska if it is greater than 4GB to ensure 
Play Station 3, Xbox 360 and FAT32 compatibility. 

If 'neroAacEnc' is installed then it in preference to 'faac' for encoding the 
AAC audio as it produces better quality output. neroAacEnc is optional, this is 
how to install it.

 wget http://ftp6.nero.com/tools/NeroDigitalAudio.zip
 unzip NeroDigitalAudio.zip
 chmod 755 linux/*
 sudo mv linux/* /usr/local/bin/

This script works on Ubuntu Linux and should work on any other Linux/Unix 
flavour and possibly Mac OS X providing you have the required tools installed. 

Usage

  MKV-to-MP4.sh movie.mkv [--yes] [--stereo] [--faac] [--mp4creator] [--split] [--keep] [--help]

You can also pass several optional parameters
  --yes        : Answer Yes to all prompts.
  --stereo     : Force a stereo down mix.
  --faac       : Force the use of faac, even if NeroAacEnc is available.
  --mp4creator : Force the use of mp4creator instead of MP4Box.
  --split      : If required, the output will be split at a boundary less than
                 4GB for FAT32 compatibility
  --keep       : Keep the intermediate files
  --help       : This help.

Requirements

 - bash, cat, cut, echo, faac, ffmpeg, file, grep, mkfifo, mktemp, mkvextract, 
   mkvinfo, mkvmerge, mp4creator, neroAacEnc, python, rm, sed, sox, stat, MP4Box
   
Known Limitations

 - Option to answer "Yes" to all prompts is not implemented.
 - Could be faster with better use of FIFOs to reduce file I/O.
 - MP4Box has a habbit of segmentation faulting. This script does what it can
   to clean the output filenames to avoid this but crashes can still occur. If 
   bad stuff happens force the use of 'mp4creator' with the --mp4creator option. 
 
To Do

 - Fancy console output
 - Use this to avoid using Python.
     echo -n “)” | dd of=”$VIDEO_FILE” bs=1 seek=7 conv=notrunc  
 
Source Code

You can grab the source from Launchpad. Contributions are welcome :-)

 - https://code.launchpad.net/~flexiondotorg

References

 - https://bugs.launchpad.net/ubuntu/+source/gpac/+bug/273075
 - http://www.jenom.com/modules.php?name=News&file=article&cid=34
 - http://lists.mplayerhq.hu/pipermail/ffmpeg-devel/2007-April/028222.html
 - http://www.xs4all.nl/~carlo17/howto/encode.html
 - http://wiki.flexion.org/ConvertingMKV.html

v1.2 2009, 27th August.
 - Added option to force the use of 'mp4creator' instead of 'MP4Box'.
 - Added option to keep the intermidiate files created by the script.
 - Improved audio steam decoding by using 'ffmpeg' and 'sox'. Fixed DTS 5.1 to 
   AAC 5.1 transcoding which now works when using 'faac'.
 - Improved bitrates for 'faac' and 'neroAacEnc'. AAC file sizes will be much 
   closer for both. 

v1.1 2009, 23rd April.
 - Fixed tool validation
 - Fixed optional parameter parsing
 - Improved use of 'stat'
 - MIT license
 - Not publically released

v1.0 2009, 27th January.
 - Initial release
