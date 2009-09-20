#!/bin/bash

function build {
    RELEASE_NAME="MKV-to-MP4"
    RELEASE_VER="1.2"
    RELEASE_DESC="Creates a PlayStation 3 or Xbox 360 compatible MPEG-4 from Matroska"
    RELEASE_KEYWORDS="MKV, Matroska, MP4, MPEG-4, conversion, PS3, PlayStation 3, Xbox 360, AAC 5.1"

    rm ${RELEASE_NAME}-v${RELEASE_VER}.tar* 2>/dev/null
    bzr export ${RELEASE_NAME}-v${RELEASE_VER}.tar
    tar --delete -f ${RELEASE_NAME}-v${RELEASE_VER}.tar ${RELEASE_NAME}-v${RELEASE_VER}/build.sh
    gzip ${RELEASE_NAME}-v${RELEASE_VER}.tar
}
