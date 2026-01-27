FILE="$1"

if [ -n "${FZF_PREVIEW_COLUMNS-}" ]; then
  # fzf previews.
  read -r _ TERMINAL_COLUMNS < <(</dev/tty stty size)
  WIDTH="$FZF_PREVIEW_COLUMNS"
  HEIGHT="$FZF_PREVIEW_LINES"
  X=$((TERMINAL_COLUMNS - FZF_PREVIEW_COLUMNS - 1))
  Y=0
else
  # lf previews.
  WIDTH="$2"
  # If the drawbox option is enabled.
  WIDTH=$((WIDTH - 1))
  HEIGHT="$3"
  X="$4"
  Y="$5"
fi

function draw() {
  if [ -n "${NVIM-}" ]; then
    # Neovim's terminal doesn't support kitty graphics.
    chafa --size "${WIDTH}x${HEIGHT}" "$1"
  elif [ -n "${FZF_PREVIEW_COLUMNS-}" ]; then
    # fzf preview.
    kitten icat --clear --transfer-mode=memory --unicode-placeholder --stdin=no \
      --place="${WIDTH}x${HEIGHT}@${X}x${Y}" "$1"
  else
    # lf preview.
    kitten icat --transfer-mode=memory --stdin=no \
      --place="${WIDTH}x${HEIGHT}@${X}x${Y}" "$1" </dev/null >/dev/tty
    exit 1
  fi
}

CACHE_DIR="$HOME/.cache/image-previews"
mkdir -p "$CACHE_DIR"

CACHE_FILE="$(
  stat --printf '%n\0%i\0%F\0%s\0%W\0%Y' -- "$(readlink -f "$FILE")" \
    | sha256sum \
    | awk '{print $1}' \
)"
CACHE="$CACHE_DIR/$CACHE_FILE"

MIME_TYPE=$(file -Lb --mime-type -- "$FILE")
FILE_DESC=$(file -Lb -- "$FILE")

if is_ssh_private_key "$FILE_DESC"; then
  echo "Preview disabled for private SSH key"
  exit 0
fi

if show_pgp_public_key "$FILE" "$MIME_TYPE"; then
  exit 0
fi

case "$FILE" in
  *.7z|*.a|*.ace|*.alz|*.arc|*.arj|*.bz|*.bz2|*.cab|*.cpio|*.deb|*.gz|*.jar|\
  *.lha|*.lrz|*.lz|*.lzh|*.lzma|*.lzo|*.rar|*.rpm|*.rz|*.t7z|*.tar|*.tbz|\
  *.tbz2|*.tgz|*.tlz|*.txz|*.tZ|*.tzo|*.war|*.xz|*.Z|*.zip)
    als -- "$FILE"
    ;;
  *.svg)
    [ -f "$CACHE" ] || inkscape -z -w 1024 -h 1024 "$FILE" -o "$CACHE"
    draw "$CACHE"
    ;;
  *.epub)
    [ -f "$CACHE" ] || ebook-meta --get-cover="$CACHE" "$FILE" &>/dev/null
    draw "$CACHE"
    ;;
esac

case "$MIME_TYPE" in
  text/*|application/javascript|application/json|application/csv)
    bat --color=always "$FILE"
    ;;
  */pdf)
    [ -f "${CACHE}.jpg" ] || pdftoppm -singlefile -f 1 -jpeg "$FILE" "$CACHE"
    draw "${CACHE}.jpg"
    ;;
  image/*)
    draw "$FILE"
    ;;
  video/*)
    [ -f "$CACHE" ] || ffmpegthumbnailer -i "$FILE" -o "$CACHE" -s 0
    draw "$CACHE"
    ;;
  audio/*)
    mediainfo "$FILE"
    ;;
  *)
    file -Lb --mime-type -- "$FILE"
    ;;
esac
