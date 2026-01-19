if [ -z "$1" ]; then
  echo "usage: $0 FILENAME[:LINENO][:IGNORED]"
  exit 1
fi

IFS=':' read -r -a INPUT <<< "$1"
FILE=${INPUT[0]}
CENTER=${INPUT[1]}

if [[ $1 =~ ^[A-Za-z]:\\ ]]; then
  FILE=$FILE:${INPUT[1]}
  CENTER=${INPUT[2]}
fi

if [[ -n "$CENTER" && ! "$CENTER" =~ ^[0-9] ]]; then
  exit 1
fi
CENTER=${CENTER/[^0-9]*/}

FILE="${FILE/#\~\//$HOME/}"
if [ ! -r "$FILE" ]; then
  echo "File not found ${FILE}"
  exit 1
fi

FILE_LENGTH=${#FILE}
MIME=$(file -Lb --mime -- "$FILE")
MIME_TYPE=$(file -Lb --mime-type -- "$FILE")
FILE_DESC=$(file -Lb -- "$FILE")

if is_ssh_private_key "$FILE_DESC"; then
  echo "Preview disabled for private SSH key"
  exit 0
fi

if show_pgp_public_key "$FILE" "$MIME_TYPE"; then
  exit 0
fi

if [[ "${MIME:FILE_LENGTH}" =~ binary ]]; then
  echo "$MIME"
  exit 0
fi

if [ -z "$CENTER" ]; then
  CENTER=0
fi

bat --style="${BAT_STYLE:-numbers}" --color=always --pager=never \
      --highlight-line="$CENTER" "$FILE"
