function fuzzy_cd
  set -l dirname (fd . --base-directory ~ --type d --hidden --color always \
                       --ignore-file ~/Dropbox/share/fd/ignore |
                  sed "s/\[1;34m/\[1;90m/g; s/\(.*\)\[1;90m/\1\[1;34m/" |
                  fzf --height=8) \
  && cd ~/$dirname || true
end
