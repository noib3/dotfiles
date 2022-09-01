# gri - git rebase interactive

set -l commit (
  git --no-pager log --pretty="format:%C(green)%h %C(blue)%an %C(white)%s%Creset" --color=always \
    | fzf --prompt="Commits> " \
    | sed 's/^\(\w*\).*$/\1/' # the commit hash is the first word
)

test -z "$commit" || git rebase -i "$commit"
