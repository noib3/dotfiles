trl() { transmission-remote --list }
tra() { transmission-remote --add "$1" }
trst() { transmission-remote --torrent "$1" --start }
trsp() { transmission-remote --torrent "$1" --stop }
trr() { transmission-remote --torrent "$1" --remove }
trp() { transmission-remote --torrent "$1" --remove-and-delete }
