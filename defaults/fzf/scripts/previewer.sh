CACHE_DIR="$HOME/.cache/image-previews"
mkdir -p "$CACHE_DIR"

file="$1"
width="$FZF_PREVIEW_COLUMNS"
height="$FZF_PREVIEW_LINES"

function hash() {
  local hash="$(
    stat --printf '%n\0%i\0%F\0%s\0%W\0%Y' -- "$(readlink -f "$1")" \
      | sha256sum \
      | awk '{print $1}' \
  )"
  printf '%s/%s' "$CACHE_DIR" "$hash"
}

function draw() {
  chafa --size "${width}x${height}" "$1"
}

case "$file" in
  *.7z|*.a|*.ace|*.alz|*.arc|*.arj|*.bz|*.bz2|*.cab|*.cpio|*.deb|*.gz|*.jar|\
  *.lha|*.lrz|*.lz|*.lzh|*.lzma|*.lzo|*.rar|*.rpm|*.rz|*.t7z|*.tar|*.tbz|\
  *.tbz2|*.tgz|*.tlz|*.txz|*.tZ|*.tzo|*.war|*.xz|*.Z|*.zip)
    als -- "$file"
    exit 0
    ;;
  *.svg)
    cache="$(hash "$file").jpg"
    [ -f "$cache" ] \
      || convert -- "$file" "$cache"
    draw "$cache"
    exit 0
    ;;
  *.epub)
    cache="$(hash "$file").jpg"
    [ -f "$cache" ] \
      || ebook-meta --get-cover="$cache" "$file" &>/dev/null
    draw "$cache"
    exit 0
    ;;
esac

case "$(file -Lb --mime-type -- "$file")" in
  text/*|application/json)
    bat "$file"
    ;;
  */pdf)
    cache="$(hash "$file")"
    [ -f "${cache}.jpg" ] \
      || pdftoppm -f 1 -l 1 \
          -scale-to-x '1920' \
          -scale-to-y -1 \
          -singlefile \
          -jpeg \
          -- "$file" "$cache"
    draw "${cache}.jpg"
    ;;
  image/*)
    draw "$file"
    ;;
  video/*)
    cache="$(hash "$file").jpg"
    [ -f "$cache" ] \
      || ffmpegthumbnailer -i "$file" -o "$cache" -s 0
    draw "$cache"
    ;;
  audio/*)
    mediainfo "$file"
    ;;
  *)
    file -Lb --mime-type -- "$file"
    ;;
esac

exit 0
