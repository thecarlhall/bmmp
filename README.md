# bmmp (pronounced "bump")
Bare Minimum Music Player

After years of building web-based music servers, and running other products, like Subsonic and Plex, I've finally fallen back to using just a Raspberry Pi to be a file and web server.  The web server is enough to serve files beyond the network, so I just need an index of playable media.  `generate_m3u.sh` will generate an m3u playlist that can be shared anywhere.  `play.sh` will use that m3u to play the music.

## Dependencies

### Generating Playlist

* find
* sed
* wc

### Playing Playlist

* sed
* grep
* pkill
* jot (mac) or shuf (linux)
* curl
* mpg123

## Usage

Search uses extended regular expressions as provided by `grep -E`.

### Playing

#### Use entire playlist
./play.sh

### Filter the playlist before playing
./play.sh Nas

### Filter the playlist before playing randomly
./play.sh -r Nas

### Searching 

#### List search results without playing
./play.sh -s Nas

