#!/usr/bin/env bash
set -e

while getopts fl:o:s: option; do
    case $option in
        f) force=1 ;;
        l) location=$OPTARG ;;
        o) output=$OPTARG ;;
        s) server=$OPTARG ;;
    esac
done

if [[ -z $force ]]; then
    if ls --full-time -tr | tail -n 1 | grep -q playlist; then
        echo 'Playlist was generated after latest change. Use -f to ignore this check.'
        exit 1
    fi
fi

location=${location:-$(pwd)}
output=${output:-playlist.m3u}

if [[ -z "$location" || -z "$server" ]]; then 
    echo 'Set -l (location), -s (server)'
    echo $location :: $server
    exit 1
fi

# add a line for each mp3 and replace some url characters
# this reflects play.sh
find $location -type f -iname '*.mp3' \
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

