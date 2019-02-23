#!/bin/sh
# use: download URL FILE
dl_curl() {
    command -v curl > /dev/null || return 1;
    curl "${1}" -o "${2}" || return 1;
    exit 0;
}
dl_wget() {
    command -v wget > /dev/null || return 1;
    wget -q "${1}" -O"${2}" || return 1;
    exit 0;
}
dl_wget ${@}
dl_curl ${@}
