#!/usr/bin/env bash
set -e

source ./.bmmp.env

################################################################################
##  options
################################################################################
while getopts r:s:p: option
do
    case "${option}"
        in
        r) random=${OPTARG};;
        s) search=${OPTARG};;
        p) play=${OPTARG};;
    esac
done

################################################################################
##  functions
################################################################################
## https://stackoverflow.com/a/37840948/201197
urldecode() { : "${*//+/ }"; echo -e "${_//%/\\x}"; }

## choose the next line to play
choose_next() {
    if [[ ! -z "$random" ]]; then
        if hash jot;  then
            pick=$(jot -r 1 $first $last)
        elif hash shuf; then
            pick=$(shuf -n 1 -i $first-$last)
        else
            pick=$(($pick + 1))
        fi
    else
        pick=$(($pick + 1))
    fi
}

## play random songs based on a search
play() {
    echo Playing...
    search
    list_len=$(echo -n "$list" | wc -l)

    first=1
    last=$list_len
    pick=0
    while true; do
        choose_next

        line=$(echo "$list" | sed -n ${pick}p)
        (curl -ks "$line" | mpg123 - ) &

        while true; do
            read -n 1 -t 1 action

            if [[ $action == "?" ]]; then
                print_usage

            elif [[ $action == 'l' ]]; then
                print_list

            elif [[ $action == 'n' ]]; then
                (killall mpg123; true)
                break

            elif [[ -z "$(pgrep mpg123)" ]]; then
                break

            elif [[ $action == 'q' ]]; then
                (killall mpg123; true)
                exit 0

            fi
        done
    done
}

## print the playlist
print_list() {
    deprefixed=$(echo "$list" | sed "s,^$server/,,g")
    decoded=$(urldecode "$deprefixed")
    echo "$decoded" | less
}

print_usage() {
    echo
    echo 'n - next track'
    echo 'l - print the playlist'
    echo 'q - quit'
    echo '? - show usage'
    echo
}

## search the playlist
search() {
    echo Searching...
    if [[ -z "$search" ]]; then
        ## use the whole list but skip the header
        list=$(sed 1d "$outfile")
    else
        list=$(grep -Ei "${search}" "$outfile")
    fi
    list=$(echo -n "$list" | sort)
    if [[ $1 == 'print' ]]; then
        print_list
    fi
}

################################################################################
##  main
################################################################################
if [[ ! -z "$search" ]]; then
    search 'print'
elif [[ ! -z "$play" ]]; then
    search=$play
    play
elif [[ ! -z "$random" ]]; then
    search=$random
    play
else
    search=$1
    play
fi

