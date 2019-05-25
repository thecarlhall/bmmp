#!/usr/bin/env bash
set -e

source ./.bmmp.env

# start a file with the m3u header
echo '#EXTM3U' > "$outfile"

# add a line for each mp3 and replace some url characters
find $location -type f -iname '*.mp3' | \
	sed -e "s,^$location,$server,g" \
		-e 's/ /%20/g' \
		-e 's/!/%21/g' \
		-e 's/#/%23/g' \
		-e 's/\$/%24/g' \
		-e 's/\&/%26/g' \
		-e "s/'/%27/g" \
		-e 's/(/%28/g' \
		-e 's/)/%29/g' \
        -e 's/\[/%5B/g' \
        -e 's/\]/%5D/g' \
	>> "$outfile"

line_count=$(wc -l < "$outfile")
## don't count the header
line_count=$(($line_count - 1))

echo Wrote $line_count entries to $outfile

