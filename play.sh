#!/usr/bin/env bash
set -e

################################################################################
##  functions
################################################################################
## https://stackoverflow.com/a/37840948/201197
urldecode() { : "${*//+/ }"; echo -e "${_//%/\\x}"; }

## look for the playlist in known locations
find_playlist() {
    possible_playlists=( $playlist_file ~/.bmmp/playlist.m3u playlist.m3u )
    
    for playlist in ${possible_playlists[@]}; do
        if [[ -f $playlist ]]; then
            playlist_file=$playlist
            echo "Reading playlist from $playlist_file"
            return
        fi
    done

    echo "No playlist found!"
    exit -2
}

## choose the next track to play
choose_next() {
    first=1

    if [[ ! -z "$user_pick" ]]; then
        if [[ ${user_pick:0:1} == "-" || ${user_pick:0:1} == "+" ]]; then
            pick=$(($pick $user_pick))
        else
            pick=$user_pick
        fi
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

    if [[ -z "$list" ]]; then
        url=$(sed "${pick}q;d" "$playlist_file")
    else
        url=$(echo "$list" | sed -n ${pick}p)
    fi
}

## kill the mpg123 process if running
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

## use mpg123 to play an mp3 by url
play_url() {
    echo "** playing track $pick"

    echo $(urldecode "$url")
    curl -ks "$url" | mpg123 --resync-limit 2048 --long-tag - & last_pid=$!
    state=playing
}

## toggle starting or stopping a url
start_stop() {
    if [[ "$state" == 'playing' ]]; then
        kill_it
    else
        play_url
    fi
}

## toggle the random setting used when choosing the next entry to play
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

        play_url
        echo '--------------------------------------------------------------------------------'

        while true; do
            read -s -n 1 -t 1 cmd || true

            case $cmd in
                [1-9+-])
                    read -p "Choose track [playing $pick of $list_len]: " -e -i "$cmd" user_pick

                    if [[ ! -z "$user_pick" ]]; then
                        kill_it
                        break
                    fi
                    ;;

                l) print_list ;;
                n) kill_it; break ;;
                p) previous=true; kill_it; break ;;
                q) kill_it; echo '** bye!'; return 0 ;;
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
    echo "$(urldecode "$list")" | less -N +${pick}g
}

## search the playlist
search() {
    if [[ -z "$pattern" ]]; then
        echo "Using entire playlist..."
        unset list
        list_len=$(sed -n '$=' "$playlist_file")
    else
        # replace space with 'any char'
        echo "Searching for '$pattern'..."
        esc_pattern="${pattern//[\.]/\\.}"    # replace dots with escaped dots for explicit match
        esc_pattern="${esc_pattern//[ ]/.+}"  # replace spaces with .+ for fuzzy matching
        #echo "Using pattern: ${esc_pattern}"
        list=$(grep -Ei "$esc_pattern" "$playlist_file" | sort)
        list_len=$(echo "$list" | sed -n '$=')
    fi
}

## print usage details
usage() {
    echo '****************************************'
    echo ' :arguments:'
    echo '****************************************'
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
while getopts p:rs option; do
    case $option in
        p) playlist_file=$OPTARG ;;
        r) random=true ;;
        s) action=search ;;
    esac
done

find_playlist

shift $((OPTIND-1))
pattern="$@"

if [[ "$action" == "search" ]]; then
    search
    print_list
else
    play
fi

