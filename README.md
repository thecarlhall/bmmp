# bmmp (pronounced "bump")

**Bare Minimum Music Player**

After years of building web-based music servers, and running other products, like Subsonic and Plex, I've finally fallen back to using just a Raspberry Pi to be a file and web server.  The web server is enough to serve files beyond the network, so I just need an index of playable media.  `generate_m3u.sh` will generate an m3u playlist (39k+ entries in ~1 sec) that can be shared anywhere.  `play.sh` will use that m3u to play the music.

## Usage

bmmp supports playing mp3 files as noted in an m3u playlist.  The files played can be filtered using using extended regular expressions as provided by `grep -E`.

### Arguments

#### Playing

**Arguments to start**
```
 -c   location of config file. Defaults to `~/.bmmp/config`.
 -h   show help and usage.
 -p   playlist file to use.  Defaults to `./playlist.m3u` then `~/.bmmp/playlist.m3u`.
 -r   turn on random play
```

**Menu while running**
```
 [1-9] - choose entry from playlist
 l     - print the playlist
 n     - next track
 p     - previous track
 q     - quit
 r     - toggle random play
 s     - start/stop play
 ?     - show usage
```

#### Generating Playlist
```
 -l   location to scan for mp3 files
 -o   output file where to write playlist. Defaults to 'playlist.m3u'
 -s   the host url where files will be served
```

### Playing

#### Use entire playlist

```bash
./play.sh
```

#### Filter the playlist before playing

```bash
./play.sh talib kweli
```

### Filter the playlist before playing randomly

```bash
./play.sh -r grateful dead
```

### Searching 

#### List search results without playing

```bash
./play.sh -s nas
```

### Generating playlist

```
./generate_m3u.sh
```

## Dependencies

### Generating Playlist

- find
- sed
- sort

### Playing Playlist

- curl
- grep
- kill
- less
- jot _or_ shuf
- mpg123
- sed

