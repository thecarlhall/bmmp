#!/usr/bin/env bash
set -e

################################################################################
##  functions
################################################################################
## https://stackoverflow.com/a/37840948/201197
urldecode() { : "${*//+/ }"; echo -e "${_//%/\\x}"; }

## choose the next track to play
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

    elif [ "$previous" = true ]; then
        unset previous
        if [[ $pick -gt 1 ]]; then
            pick=$((pick - 1))
        fi

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

    echo "** playing track $pick"
}

kill_it() {
    if [[ -z "$last_pid" ]]; then
        return
    fi

    if ps -p $last_pid > /dev/null; then
        kill $last_pid
        unset last_pid
        state=stopped
    fi
}

play_url() {
    echo $(urldecode "$url")
    curl -ks "$url" | mpg123 --long-tag - & last_pid=$!
    state=playing
}

start_stop() {
    if [[ "$state" == 'playing' ]]; then
        kill_it
    else
        play_url
    fi
}

toggle_random() {
    if [ "$random" = true ]; then
        random=false
    else
        random=true
    fi
    echo -e "** set random to $random"
}

## play songs based on a search
play() {
    search

    pick=0
    state=stopped
    while true; do
        echo '--------------------------------------------------------------------------------'
        choose_next

        url=$(echo "$list" | sed -n ${pick}p)
        play_url
        echo '--------------------------------------------------------------------------------'

        while true; do
            read -s -n 1 -t 1 cmd || true

            case $cmd in
                [1-9])
                    read -p "Choose track [playing $pick of $list_len]: " -e -i "$cmd" user_pick

                    if [[ ! -z "$user_pick" ]]; then
                        kill_it
                        break
                    fi
                    ;;

                l) print_list ;;
                n) kill_it; break ;;
                p) previous=true; kill_it; break ;;
                q) kill_it; echo '** bye!'; exit 0 ;;
                r) toggle_random ;;
                s) start_stop ;;
                \?) usage ;;
            esac

            ## if should be playing, but is missing mpg123 process, assume an
            ## error happend, so break the loop to start the next track
            if [[ "$state" == "playing" && -z "$(pgrep mpg123)" ]]; then
                break
            fi
        done
    done
}

## print the playlist
print_list() {
    decoded=$(urldecode "$list")
    echo "$decoded" | less -N
}

## search the playlist
search() {
    if [[ -z "$pattern" ]]; then
        list=$(<"$playlist_file")
    else
        list=$(grep -Ei "${pattern}" "$playlist_file")
    fi

    list=$(echo "$list" | sort)
    list_len=$(echo "$list" | wc -l | grep -Eo '[0-9]+')

    if [[ $1 == 'print' ]]; then
        print_list
    fi
}

## print usage details
usage() {
    echo '****************************************'
    echo ' :arguments:'
    echo '****************************************'
    echo ' -c   config file'
    echo ' -r   turn on random play'
    echo ' -s   search without playing'
    echo
    echo '****************************************'
    echo ' :runtime:'
    echo '****************************************'
    echo ' [1-9] - choose entry from playlist'
    echo ' l     - print the playlist'
    echo ' n     - next track'
    echo ' p     - previous track'
    echo ' q     - quit'
    echo ' r     - toggle random play'
    echo ' s     - start/stop play'
    echo ' ?     - show usage'
    echo '****************************************'
}

################################################################################
##  main
################################################################################
while getopts c:rs option; do
    case $option in
        r) random=true ;;
        s) action=search ;;
    esac
done

playlist_file=${playlist_file:-playlist.m3u}
echo "Reading playlist from $playlist_file"

pattern=${!OPTIND}

if [[ "$action" == "search" ]]; then
    search 'print'
else
    play
fi

