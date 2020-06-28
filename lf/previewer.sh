#!/usr/bin/env sh

# Filename:   previewer.sh
# Github:     https://github.com/n0ibe/macOS-dotfiles
# Maintainer: Riccardo Mazzarini

# Needs to be executable

FILE="$1"

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
    text/*) text_preview "$1" ;;
    */pdf) pdf_preview "$1" ;;
    image/*) image_preview "$1" "$2" ;;
    video/*) video_preview "$1" ;;
    audio/*) audio_preview "$1" ;;
    *) fallback_preview "$1" ;;
esac
