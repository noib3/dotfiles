set -x COLORSCHEME onedark
set -x SCRIPTSDIR $HOME/Sync/code/scripts
set -x SSHOTDIR $HOME/Sync/screenshots
set -x PRIVATEDIR $HOME/Sync/private

set PATH ""
set PATH $PATH /Applications/Alacritty.app/Contents/MacOS
set PATH $PATH /Applications/Firefox.app/Contents/MacOS
set PATH $PATH /usr/local/opt/coreutils/libexec/gnubin
set PATH $PATH /usr/local/opt/findutils/libexec/gnubin
set PATH $PATH /usr/local/opt/gnu-sed/libexec/gnubin
set PATH $PATH /Library/TeX/texbin
set PATH $PATH /usr/local/sbin
set PATH $PATH /usr/local/bin
set PATH $PATH /usr/sbin
set PATH $PATH /usr/bin
set PATH $PATH /sbin
set PATH $PATH /bin
set PATH $PATH $SCRIPTSDIR/peek
set PATH $PATH $SCRIPTSDIR/pfetch
set PATH $PATH $SCRIPTSDIR/vimv
set -x PATH $PATH

set -x VISUAL nvim
set -x EDITOR $VISUAL
set -x MANPAGER "nvim -c 'set ft=man' -"

set -x LANG en_US.UTF-8
set -x LC_ALL en_US.UTF-8

set -x TCELL_TRUECOLOR on

set -x HOMEBREW_NO_AUTO_UPDATE 1

set -x IPYTHONDIR $HOME/.local/share/ipython
set -x MPLCONFIGDIR $HOME/.local/share/matplotlib
set -x LESSHISTFILE $HOME/.cache/less/lesshst
set -x HISTFILE $HOME/.cache/bash/bash_history
set -x npm_config_cache $HOME/.cache/npm

set -x FZF_DEFAULT_COMMAND \
"fd --base-directory ~ --hidden --type f --color always"

set -x FZF_DEFAULT_OPTS \
"--reverse --no-bold --info=inline --hscroll-off=50 --ansi \
--color='hl:-1:underline,fg+:-1:regular:italic' \
--color='hl+:-1:underline:italic,prompt:4:regular,pointer:1'"

set -x FZF_ONLYDIR_COMMAND \
(echo $FZF_DEFAULT_COMMAND | sed 's/--type f/--type d/')

set -x LS_COLORS (vivid generate ~/.config/vivid/colorschemes/$COLORSCHEME)

set dircolor (echo $LS_COLORS | sed 's/\(^\|.*:\)di=\([^:]*\).*/\2/')
set fgodcolor (echo $LS_COLORS | sed 's/\(^\|.*:\)\*\.fgod=\([^:]*\).*/\2/')

set -x FZF_DEFAULT_COMMAND $FZF_DEFAULT_COMMAND "|
sed 's/\x1b\["$dircolor"m/\x1b\["$fgodcolor"m/g'"

set -x FZF_ONLYDIR_COMMAND $FZF_ONLYDIR_COMMAND "|
sed 's/\x1b\["$dircolor"m/\x1b\["$fgodcolor"m/g' |
sed 's/\(.*\)\x1b\["$fgodcolor"m/\1\x1b\["$dircolor"m/'"
