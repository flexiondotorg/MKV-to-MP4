#!/bin/bash

NAME="MKV-to-MP4"
VER=1.1

rm ${NAME}-v${VER}.tar* 2>/dev/null
bzr export ${NAME}-v${VER}.tar
tar --delete -f ${NAME}-v${VER}.tar ${NAME}-v${VER}/release.sh
gzip ${NAME}-v${VER}.tar
