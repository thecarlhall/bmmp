#!/usr/bin/env bash
set -e

usage() {
    echo 'Usage: generate_m3u.sh [-f] [-l location] [-o output] [-s server]'
    echo ' -f   force regeneration even if playlist is up to date'
    echo ' -h   show help and usage'
    echo ' -l   location to scan for mp3 files'
    echo ' -o   output file to write playlist. Defaults to /var/storage/playlists/music.m3u'
    echo ' -s   server URL to prefix file paths'
}

while getopts fhl:o:s: option; do
    case $option in
        f) force=1 ;;
        h) usage; exit 0 ;;
        l) location=$OPTARG ;;
        o) output=$OPTARG ;;
        s) server=$OPTARG ;;
    esac
done

location=${location:-/var/storage/music/}
server=${server:-https://media.halls.farm/files/music/}
output=${output:-/var/storage/playlists/music.m3u}

if [[ -z $force ]] && [[ -f "$output" ]]; then
    if [[ -z "$(find "$location" -type f -iname '*.mp3' -newer "$output" | head -1)" ]]; then
        echo 'Playlist is up to date. Use -f to force regeneration.'
        exit 0
    fi
fi

# output a line for each mp3 and replace some URL characters
# this reflects play.sh
find "$location" -type f -iname '*.mp3' \
    | sed -e "s,^$location,$server,g" \
        -e 's, ,%20,g' \
        -e 's,!,%21,g' \
        -e 's,",%22,g' \
        -e 's,#,%23,g' \
        -e 's,\$,%24,g' \
        -e 's,&,%26,g' \
        -e 's,'"'"',%27,g' \
        -e 's,(,%28,g' \
        -e 's,),%29,g' \
        -e 's,\[,%5B,g' \
        -e 's,\],%5D,g' \
        -e 's,{,%7B,g' \
        -e 's,},%7D,g'  \
    | sort \
    > "$output"

line_count=$(sed -n '$=' "$output")

echo Wrote $line_count entries to $output

