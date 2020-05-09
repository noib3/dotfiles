# On macOS, the PATH is built up as described here:
#   https://unix.stackexchange.com/questions/246751/how-to-know-why-and-where-the-path-env-variable-is-set
# In particular, you need to comment out the contents of /etc/zprofile

PATH=/usr/local/opt/coreutils/libexec/gnubin
PATH=$PATH:/usr/local/opt/findutils/libexec/gnubin
PATH=$PATH:/Library/TeX/texbin
PATH=$PATH:/usr/local/bin
PATH=$PATH:/usr/bin
PATH=$PATH:/bin
PATH=$PATH:/usr/sbin
PATH=$PATH:/sbin
PATH=$PATH:/Applications/Alacritty.app/Contents/MacOS
PATH=$PATH:/Applications/qutebrowser.app/Contents/MacOS
PATH=$PATH:/Users/noibe/scripts
PATH=$PATH:/Users/noibe/scripts/pfetch
PATH=$PATH:/Users/noibe/bin/ndiet
export PATH

# Preferred editor
export VISUAL=nvim
export EDITOR=$VISUAL

# Export terminal and browser
export TERMINAL=alacritty
export BROWSER=qutebrowser

# Locale settings
export LC_LL=en_US.UTF-8
export LANG=en_US.UTF-8

# Custom history/cache files locations
export LESSHISTFILE=$HOME/.cache/less/lesshst
export MPLCONFIGDIR=$HOME/.cache/matplotlib
export PYTHONSTARTUP=$HOME/.local/share/python/python-startup.py

# Don't update homebrew automatically every time it's launched
export HOMEBREW_NO_AUTO_UPDATE=1

# Export LS_COLORS variable used by ls, lf and others for file coloring
export LS_COLORS=$(printf %s            \
                     'no=90:'           \
                     'di=01;34:'        \
                     'ex=01;32:'        \
                     'ln=35:'           \
                     'mh=31:'           \
                     '*.mp3=33:'        \
                     '*.md=04;93:'      \
                     '*.ttf=95:'        \
                     '*.otf=95:'        \
                     '*.png=04;92:'     \
                     '*.jpg=04;92'      \
                  )
