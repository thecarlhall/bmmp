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

    if [[ ! -z "$user_pick" ]]; then
        pick=$user_pick
        unset user_pick

        if [[ $pick -lt $first ]]; then
            pick=$first
        elif [[ $pick -gt $list_len ]]; then
            pick=$list_len
        fi
        echo ** playing user pick $pick

    elif [ "$random" = true ]; then
        ## pick a random track from the list
        if hash jot;  then
            pick=$(jot -r 1 $first $list_len)
        elif hash shuf; then
            pick=$(shuf -n 1 -i $first-$list_len)
        fi

    else
        ## advance to the next track or wrap back to the beginning
        pick=$((pick % list_len + 1))
    fi
}

kill_it() {
    if ps -p $last_pid > /dev/null; then
        kill $last_pid
    fi
}

## play songs based on a search
play() {
    search

    pick=0
    state=stopped
    while true; do
        choose_next

        echo '--------------------------------------------------------------------------------'
        line=$(echo "$list" | sed -n ${pick}p)
        curl -ks "$line" | mpg123 - & last_pid=$!
        state=playing

        while true; do
            read -s -n 1 -t 1 cmd || true

            case $cmd in
                [1-9])  # pick an entry from the playlist
                    read -p "Choose track [playing $pick of $list_len]: " -e -i "$cmd" user_pick

                    if [[ ! -z "$user_pick" ]]; then
                        kill_it
                        break
                    fi
                    ;;

                l)  # list contents of playlist
                    print_list
                    ;;

                n)  # play next song in list
                    kill_it
                    break
                    ;;

                q)  # quit
                    kill_it
                    echo '** bye!'
                    exit 0
                    ;;

                r)  # toggle random
                    if [ "$random" = true ]; then
                        random=false
                    else
                        random=true
                    fi
                    echo -e "** set random to $random"
                    ;;

                s)  # start/stop playing
                    if [[ "$state" == 'playing' ]]; then
                        kill_it
                        state=stopped
                    else
                        curl -ks "$line" | mpg123 - & last_pid=$!
                        state=playing
                    fi
                    ;;

                \?) # usage
                    usage
                    ;;
            esac

            if [[ "$state" == "playing" && -z "$(pgrep mpg123)" ]]; then
                break
            fi
        done
    done
}

## print the playlist
print_list() {
    deprefixed=$(echo "$list" | sed "s,^$server/,,g")
    decoded=$(urldecode "$deprefixed")
    echo "$decoded" | less -N
}

## search the playlist
search() {
    if [[ -z "$pattern" ]]; then
        list=$(<"$outfile")
    else
        list=$(grep -Ei "${pattern}" "$outfile")
    fi

    list=$(echo "$list" | sort)
    list_len=$(echo "$list" | wc -l | grep -Eo '[0-9]+')

    if [[ $1 == 'print' ]]; then
        print_list
    fi
}

usage() {
    echo '****************************************'
    echo '[1-9] - choose entry from playlist'
    echo 'l     - print the playlist'
    echo 'n     - next track'
    echo 'q     - quit'
    echo 'r     - toggle random play'
    echo 's     - start/stop play'
    echo '?     - show usage'
    echo '****************************************'
}

################################################################################
##  main
################################################################################
while getopts r:s: option; do
    case "${option}" in
        r)
            random=true
            pattern=$OPTARG
            play
            ;;
        s)
            pattern=$OPTARG
            search 'print'
            ;;
    esac
done

if [[ $OPTIND -eq 1 && ! -z "$1" ]]; then
    pattern=$1
    play
fi

