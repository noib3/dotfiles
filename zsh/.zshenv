# On macOS, the PATH is built up as described here:
#   https://unix.stackexchange.com/questions/246751/how-to-know-why-and-where-the-path-env-variable-is-set
# In particular, you need to comment out the contents of /etc/zprofile

PATH=/usr/local/opt/coreutils/libexec/gnubin
PATH=$PATH:/usr/local/opt/findutils/libexec/gnubin
PATH=$PATH:/usr/local/opt/python@3.8/bin
PATH=$PATH:/Library/TeX/texbin
PATH=$PATH:/usr/local/bin
PATH=$PATH:/usr/bin
PATH=$PATH:/bin
PATH=$PATH:/usr/sbin
PATH=$PATH:/sbin
export PATH

# Preferred editor
export VISUAL=nvim
export EDITOR=$VISUAL

# Locale settings
export LC_LL=en_US.UTF-8
export LANG=en_US.UTF-8

# Custom history/cache files locations
export LESSHISTFILE=$HOME/.cache/less/lesshst
export MPLCONFIGDIR=$HOME/.cache/matplotlib
export PYTHONSTARTUP=$HOME/.local/share/python/python-startup.py

