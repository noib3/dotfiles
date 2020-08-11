#!/usr/bin/env sh

# Filename:   lf/previewer.sh
# Github:     https://github.com/n0ibe/macOS-dotfiles
# Maintainer: Riccardo Mazzarini

# Needs to be executable

FILE="$1"
HEIGHT="$2"

text_preview() {
    highlight -O ansi --force "$1"
}

pdf_preview() {
    pdftotext "$1" -
}

image_preview() {
    chafa --fill=block --symbols=block -c 256 -s 80x"$2" "$1"
}

video_preview() {
    mediainfo "$1"
}

audio_preview() {
    mediainfo "$1"
}

fallback_preview() {
    highlight -O ansi --force "$1"
}

case "$(file -b --mime-type "$FILE")" in
    text/*) text_preview "$FILE" ;;
    */pdf) pdf_preview "$FILE" ;;
    image/*) image_preview "$FILE" "$HEIGHT" ;;
    video/*) video_preview "$FILE" ;;
    audio/*) audio_preview "$FILE" ;;
    *) fallback_preview "$FILE" ;;
esac
