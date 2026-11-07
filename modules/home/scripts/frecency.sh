# Ranks paths by frecency, i.e. by how often and how recently they were visited.
# Each store is a TSV file with one `score\tlast_visit\tpath` row per path.

usage() {
  cat >&2 <<EOF
usage: frecency add <store> <path>...
       frecency list <store>
EOF
  exit 1
}

# The total score above which all the scores in a store are scaled down.
MAX_TOTAL_SCORE=1000

store_path() {
  printf '%s/frecency/%s' "${XDG_DATA_HOME:-$HOME/.local/share}" "$1"
}

# Adds a visit to each of the given absolute paths.
add() {
  local store
  store="$(store_path "$1")"
  shift

  mkdir -p "$(dirname "$store")"
  touch "$store"

  local tmp
  tmp="$(mktemp "$store.XXXXXX")"

  printf '%s\n' "$@" |
    awk -F '\t' -v OFS='\t' -v now="$(date +%s)" -v max_total="$MAX_TOTAL_SCORE" '
      FILENAME == "-" { visited[$0] = 1; next }
      $3 in visited { $1 += 1; $2 = now; delete visited[$3] }
      { score[$3] = $1; last_visit[$3] = $2; total += $1 }
      END {
        for (path in visited) {
          score[path] = 1
          last_visit[path] = now
          total += 1
        }
        factor = total > max_total ? 0.9 * max_total / total : 1
        for (path in score) {
          if (score[path] * factor >= 1) {
            print score[path] * factor, last_visit[path], path
          }
        }
      }
    ' - "$store" >"$tmp"

  mv "$tmp" "$store"
}

# Prints the existing paths in the store, from the most to the least frecent.
list() {
  local store
  store="$(store_path "$1")"

  [ -f "$store" ] || return 0

  awk -F '\t' -v OFS='\t' -v now="$(date +%s)" '
    {
      age = now - $2
      if (age < 3600) weight = 4
      else if (age < 86400) weight = 2
      else if (age < 604800) weight = 0.5
      else weight = 0.25
      print $1 * weight, $3
    }
  ' "$store" |
    sort -t $'\t' -k 1,1 -g -r |
    cut -f 2- |
    while IFS= read -r path; do
      if [ -e "$path" ]; then
        printf '%s\n' "$path"
      fi
    done
}

case "${1-}" in
  add)
    [ $# -ge 3 ] || usage
    shift
    add "$@"
    ;;
  list)
    [ $# -eq 2 ] || usage
    list "$2"
    ;;
  *)
    usage
    ;;
esac
