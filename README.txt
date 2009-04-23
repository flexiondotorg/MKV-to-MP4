License

Creates a PlayStation 3 compatible MPEG-4 from a MKV
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

Creates a PlayStation 3 compatible MPEG-4 from a MKV, assuming video is H.264 
and audio is AC3 or DTS with as little re-encoding as possible. Detect profile 
5.1 H.264 and patches it to 4.1 in under a second. 

Creates AAC 5.1 from AC3 5.1 and DTS 5.1 with the correct channel assignments 
(currently NeroAacEnc only). The resulting MPEG-4 should also compatible with 
Xbox360 if '-2ch' option is used.

Any subtitles in the MKV are extracted and converted to 3GPP Timed Text and 
preserved in the MPEG-4, although the PS3 can't displayed subtitles in MPEG-4
containers but some software players can.

Splits the MKV, if it is greater than 4GB, to maintain PS3 and FAT32 
compatibility in the resulting MPEG-4 files. 

This scripts Work on Ubuntu Linux, should work on any other Linux/Unix flavour 
and possibly Mac OS X providing you have the required tools installed. 

Usage

  ./MKV-to-MP4.sh movie.mkv [--yes] [--stereo] [--faac] [--help]

You can also pass several optional parameters
  --yes   : Answer Yes to all prompts.
  --stereo : Force a stereo down mix.
  --faac  : Force the use of faac, even if NeroAacEnc is available.
  --help  : This help.

Requirements

 - bash, cat, cut, echo, faac, file, grep, mkfifo, mktemp, mkvextract, mkvinfo, 
   mkvmerge, mplayer, neroAacEnc, python, rm, sed, stat, which, MP4Box.
   
Known Limitations

 - AAC 5.1 channel mapping when using 'faac' is still not correct. 
 - Add option to answer "Yes" to all prompts, useful for scripting. 
 - Better use of FIFOs could reduce file I/O.
 
Source Code

You can checkout the current branch from my Bazaar repository. This is a 
read-only repository, get in touch if you want to contribute and require write 
access.

 bzr co http://code.flexion.org/Bazaar/MKV-to-MP4/

References

 - http://wiki.flexion.org/ConvertingMKV.html

v1.1 2009, 23rd April.
 - Fixed tool validation
 - Fixed optional parameter parsing
 - Improved use of 'stat'
 - MIT license

v1.0 2009, 27th January.
 - Initial release
