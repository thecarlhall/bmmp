#!/usr/bin/env bash
set -e

while getopts c:l:o:s: option; do
    case $option in
        l) location=$OPTARG ;;
        o) output=$OPTARG ;;
        s) server=$OPTARG ;;
    esac
done

output=${output:-playlist.m3u}

if [[ -z "$location" || -z "$server" ]]; then 
    echo 'Set -l (location), -s (server)'
    exit 1
fi

# add a line for each mp3 and replace some url characters
find $location -type f -iname '*.mp3' | \
    sed -e "s,^$location,$server,g" \
        -e 's, ,%20,g' \
        -e 's,!,%21,g' \
        -e 's,",%22,g' \
        -e 's,#,%23,g' \
        -e 's,\$,%24,g' \
        -e 's,\&,%26,g' \
        -e "s,',%27,g" \
        -e 's,(,%28,g' \
        -e 's,),%29,g' \
        -e 's,\[,%5B,g' \
        -e 's,\],%5D,g' \
        -e 's,{,%7B,g' \
        -e 's,},%7D,g' \
    > "$output"

line_count=$(sed -n '$=' "$output")

echo Wrote $line_count entries to $output

