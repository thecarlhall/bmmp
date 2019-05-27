# bmmp (pronounced "bump")

**Bare Minimum Music Player**

After years of building web-based music servers, and running other products, like Subsonic and Plex, I've finally fallen back to using just a Raspberry Pi to be a file and web server.  The web server is enough to serve files beyond the network, so I just need an index of playable media.  `generate_m3u.sh` will generate an m3u playlist (39k+ entries in ~1 sec) that can be shared anywhere.  `play.sh` will use that m3u to play the music.

## Usage

bmmp supports playing mp3 files as noted in an m3u playlist.  The files played can be filtered using using extended regular expressions as provided by `grep -E`.

```
****************************************
 [1-9] - choose entry from playlist
 l     - print the playlist
 n     - next track
 q     - quit
 r     - toggle random play
 s     - start/stop play
 ?     - show usage
****************************************
```

Use `.bmmp.env.example` to setup the config for running all scripts.

`location` - used to look for files to generate an m3u file
`server` - the host url where files will be served
`playlist_file` - name of playlist for file generating and playing

### Playing

#### Use entire playlist

```bash
./play.sh
```

#### Filter the playlist before playing

```bash
./play.sh Nas
```

### Filter the playlist before playing randomly

```bash
./play.sh -r Nas
```

### Searching 

#### List search results without playing

```bash
./play.sh -s Nas
```

### Generating playlist

```
./generate_m3u.sh
```

## Dependencies

### Generating Playlist

- find
- sed
- wc

### Playing Playlist

- sed
- grep
- kill
- jot _or_ shuf
- curl
- mpg123

