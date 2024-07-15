CACHE_DIR="$HOME/.cache/image-previews"
mkdir -p "$CACHE_DIR"

FILE="$1"

if [ -n "${FZF_PREVIEW_COLUMNS-}" ]; then
  # fzf previews
  read -r _ TERMINAL_COLUMNS < <(</dev/tty stty size)
  WIDTH="$FZF_PREVIEW_COLUMNS"
  HEIGHT="$FZF_PREVIEW_LINES"
  X=$((TERMINAL_COLUMNS - FZF_PREVIEW_COLUMNS - 1))
  Y=0
else
  # lf previews
  WIDTH="$2"
  WIDTH=$((WIDTH - 1)) # if drawbox option is enabled
  HEIGHT="$3"
  X="$4"
  Y="$5"
fi

function hash() {
  hash="$(
    stat --printf '%n\0%i\0%F\0%s\0%W\0%Y' -- "$(readlink -f "$1")" \
      | sha256sum \
      | awk '{print $1}' \
  )"
  printf '%s/%s' "$CACHE_DIR" "$hash"
}

function draw() {
  if [ -n "${UEBERZUG_FIFO-}" ] && [ -z "${FZF_PREVIEW_COLUMNS-}" ]; then
    path="$(printf '%s' "$1" | sed 's/\\/\\\\/g;s/"/\\"/g')"
    declare cmd
    declare -A -p cmd=(\
      [action]=add \
      [identifier]=preview \
      [x]="$X" \
      [y]="$Y" \
      [width]="$WIDTH" \
      [height]="$HEIGHT" \
      [scaler]=contain \
      [scaling_position_x]=0.5 \
      [scaling_position_y]=0.5 \
      [path]="$path" \
    ) > "${UEBERZUG_FIFO}"
  else
    chafa --size "${WIDTH}x${HEIGHT}" "$1"
  fi
}

case "$FILE" in
  *.7z|*.a|*.ace|*.alz|*.arc|*.arj|*.bz|*.bz2|*.cab|*.cpio|*.deb|*.gz|*.jar|\
  *.lha|*.lrz|*.lz|*.lzh|*.lzma|*.lzo|*.rar|*.rpm|*.rz|*.t7z|*.tar|*.tbz|\
  *.tbz2|*.tgz|*.tlz|*.txz|*.tZ|*.tzo|*.war|*.xz|*.Z|*.zip)
    als -- "$FILE"
    ;;
  *.svg)
    cache="$(hash "$FILE").png"
    [ -f "$cache" ] \
      || inkscape -z -w 1024 -h 1024 "$FILE" -o "$cache"
    draw "$cache"
    ;;
  *.epub)
    cache="$(hash "$FILE").jpg"
    [ -f "$cache" ] \
      || ebook-meta --get-cover="$cache" "$FILE" &>/dev/null
    draw "$cache"
    ;;
esac

case "$(file -Lb --mime-type -- "$FILE")" in
  text/*|application/json|application/csv)
    bat --color=always "$FILE"
    ;;
  */pdf)
    cache="$(hash "$FILE")"
    [ -f "${cache}.jpg" ] \
      || pdftoppm -f 1 -l 1 \
          -scale-to-x '1920' \
          -scale-to-y -1 \
          -singlefile \
          -jpeg \
          -- "$FILE" "$cache"
    draw "${cache}.jpg"
    ;;
  image/*)
    draw "$FILE"
    ;;
  video/*)
    cache="$(hash "$FILE").jpg"
    [ -f "$cache" ] \
      || ffmpegthumbnailer -i "$FILE" -o "$cache" -s 0
    draw "$cache"
    ;;
  audio/*)
    mediainfo "$FILE"
    ;;
  *)
    file -Lb --mime-type -- "$FILE"
    ;;
esac
