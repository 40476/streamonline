﻿# StreamOnline
## A live stream checker

this is the culmination of many months of work, enjoy!


# Instructions
### DO NOT EDIT THESE LINES DIRECTLY, THE SYNTAX IS EXTREMELY STRICT!
a configuration file looks like **this**

stored as : `~/.local/share/streamonline/zentreyastream_state.txt`
```
000
streamlink
360p
https://twitch.tv/
```
* line 1 (`000`) is the date last checked (if <= current date it will not be checked)
* line 2 (`streamlink` or `xdg_open`) is the mode to use, use `xdg_open` if you want our stream opened in a browser, use `streamlink` for media player (recommended on lower end systems)
* line 3 (`360p`) is the stream quality (options are provided at file creation, (see source code for details))
* line 4 (`https://twitch.tv/`) is the host site, you will need to provide the link exactly as it appears in you browsers address bar (minus the stream name since that is appended to the end of the URL)
* line 5 and beyond (reserved for future use)


# dependencies
* `streamlink`
* `printf`
* `systemd`
* `notify-send`
* `grep`
* `sed`
* `echo`