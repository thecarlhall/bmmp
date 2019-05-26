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
        fi
    else
        if [[ ! -z "$user_pick" ]]; then
            pick=$user_pick
            unset user_pick

            if [[ $user_pick -lt $first ]]; then
                pick=$first
            elif [[ $user_pick -gt $list_len ]]; then
                pick=$list_len
            fi
        else
            let pick=$pick+1
            if [[ $pick -gt $list_len ]]; then
                pick=$first
            fi
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
                [0-9])  # pick an entry from the playlist
                    user_pick=$cmd
                    kill_it
                    break
                    ;;

                l)  # list contents of playlist
                    print_list
                    ;;

                n)  # play next song in list
                    kill_it
                    break
                    ;;

                p)  # start/stop playing
                    if [[ "$state" == 'playing' ]]; then
                        kill_it
                        state=stopped
                    else
                        curl -ks "$line" | mpg123 - & last_pid=$!
                        state=playing
                    fi
                    ;;

                r)  # toggle random
                    if [ "$random" = true ]; then
                        random=false
                    else
                        random=true
                    fi
                    echo -e "Set random to $random"
                    ;;

                q)  # quit
                    kill_it
                    echo 'Bye!'
                    exit 0
                    ;;

                \?) # usage
                    print_usage
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
        list=$(<"$outfile")
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

