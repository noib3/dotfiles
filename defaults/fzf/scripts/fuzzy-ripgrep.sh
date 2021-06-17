command_fmt="rg --column --color=always --iglob '!LICENSE' -- %s"\
" | sed '/.*:\\x1b\\[0m[0-9]*\\x1b\\[0m:$/d' || true"

initial_command="$(printf "$command_fmt" '""')"
reload_command="$(printf "$command_fmt" '{q}')"

git status &> /dev/null
[ $? != 0 ] || cd "$(git rev-parse --show-toplevel)"

results="$(\
  eval "$initial_command" \
    | fzf \
        --multi \
        --prompt='Rg> ' \
        --disabled \
        --delimiter=':' \
        --with-nth='1,2,4' \
        --bind="change:reload:$reload_command" \
        --preview='rg-previewer {}' \
        --preview-window='+{2}-/2' \
        --preview-window='border-left' \
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
