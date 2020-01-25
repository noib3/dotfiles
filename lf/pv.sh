#!/bin/sh
# needs to be chmodded

case "$1" in
    *.png|*.jpg|*.jpeg|*.mp4|*.mkv) mediainfo "$1";;
    *.zip) unzip -l "$1";;
    *.pdf) pdftotext "$1" -;;
    *) highlight -O ansi "$1" || cat "$1";;
esac
