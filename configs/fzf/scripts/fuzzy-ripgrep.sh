# Piping ripgrep's output into sed to filter empty lines
query_format=\
'rg --column --color=always -- %s'\
" | sed '/.*:\\x1b\\[0m[0-9]*\\x1b\\[0m:$/d'"\
' || true'

initial_query=$(printf "$query_format" '""')
reload_query=$(printf "$query_format" '{q}')

git status &> /dev/null
[ $? != 0 ] || cd "$(git rev-parse --show-toplevel)"

results="$(\
  eval "$initial_query" \
    | fzf \
        --multi \
        --prompt='Rg> ' \
        --disabled \
        --delimiter=':' \
        --with-nth='1,2,4..' \
        --bind="change:reload:$reload_query" \
        --preview='rg-previewer {}' \
        --preview-window='+{2}-/2' \
)"

[ ! -z "$results" ] || exit 0

regex='^([^:]*):([^:]*):([^:]*):.*$'

filenames="$(\
  echo "$results" \
    | sed -r "s!$regex!\1!;s/\ /\\\ /g" \
    | tr '\n' ' ' \
)"
lnum="$(echo "$results" | head -n 1 | sed -r "s/$regex/\2/")"
col="$(echo "$results" | head -n 1 | sed -r "s/$regex/\3/")"

nvim "+call cursor($lnum, $col)" $filenames
