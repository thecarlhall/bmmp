#!/usr/bin/env bash
set -e

source ./.bmmp.env

################################################################################
##  functions
################################################################################
## https://stackoverflow.com/a/37840948/201197
urldecode() { : "${*//+/ }"; echo -e "${_//%/\\x}"; }

## choose the next line to play
choose_next() {
    first=1
    list_len=$(echo -n "$list" | wc -l)
    if [ "$random" = true ]; then
        if hash jot;  then
            pick=$(jot -r 1 $first $list_len)
        elif hash shuf; then
            pick=$(shuf -n 1 -i $first-$list_len)
        else
            pick=$(($pick + 1))
        fi
    else
        let pick=$pick+1
        if [[ $pick -gt $list_len ]]; then
            pick=$first
        fi
    fi
    echo picking $pick
}

kill_it() {
    if ps -p $last_pid > /dev/null; then
        kill $last_pid
    fi
}

## play random songs based on a search
play() {
    search

    pick=0
    #tmpfile=$(mktemp)
    while true; do
        choose_next

        echo '--------------------------------------------------------------------------------'
        line=$(echo "$list" | sed -n ${pick}p)

        ## attempt to make it possible to pause mpg123
        #echo writing to $tmpfile
        #curl -kso "$tmpfile" "$line"
        #(mpg123 "$tmpfile" || true; rm -rf "$tmpfile") & last_pid=$!

        curl -ks "$line" | mpg123 -C - & last_pid=$!

        while true; do
            read -n 1 -t 1 cmd || true

            if [[ $cmd == "?" ]]; then
                print_usage

            elif [[ $cmd == 'l' ]]; then
                print_list

            elif [[ $cmd == 'r' ]]; then
                if [ "$random" = true ]; then
                    random=false
                else
                    random=true
                fi
                echo -e "\nSet random to $random"

            elif [[ $cmd == 'n' ]]; then
                kill_it
                break

            elif [[ -z "$(pgrep mpg123)" ]]; then
                break

            elif [[ $cmd == 'q' ]]; then
                kill_it
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
    echo 'r - toggle random play'
    echo 'q - quit'
    echo '? - show usage'
    echo
}

## search the playlist
search() {
    if [[ -z "$pattern" ]]; then
        ## use the whole list but skip the header
        list=$(sed 1d "$outfile")
    else
        list=$(grep -Ei "${pattern}" "$outfile")
    fi
    list=$(echo -n "$list" | sort)
    if [[ $1 == 'print' ]]; then
        print_list
    fi
}

################################################################################
##  main
################################################################################
while getopts :r:s: option; do
    case "${option}" in
        r)
            echo playing random
            random=true
            pattern=$OPTARG
            play
        ;;
        s)
            echo searching
            pattern=$OPTARG
            search 'print'
        ;;
        *)
            echo defaulting
            pattern=$OPTARG
            play
        ;;
    esac
done

