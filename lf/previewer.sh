#!/usr/bin/env sh

# needs to be executable

FILE="${1}"
HEIGHT="${2}"

case "$(file -b --mime-type "${FILE}")" in
    image/*)
        # chafa --fill=block --symbols=block -c 256 -s 80x"${HEIGHT}" "${FILE}";;
        chafa -c 256 "${FILE}";;
    text/*)
        highlight -O ansi "$1";;
esac

# case "$1" in
#     *.png|*.jpg|*.jpeg|*.mp4|*.mkv) mediainfo "$1";;
#     *.zip) unzip -l "$1";;
#     *.pdf) pdftotext "$1" -;;
#     *) highlight -O ansi "$1" || cat "$1";;
# esac
