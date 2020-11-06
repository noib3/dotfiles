set fish_greeting ""

set -x SCRIPTSDIR $HOME/scripts

set PATH ""
set PATH $PATH /usr/local/opt/coreutils/libexec/gnubin
set PATH $PATH /usr/local/opt/findutils/libexec/gnubin
set PATH $PATH /usr/local/opt/gnu-sed/libexec/gnubin
set PATH $PATH /Library/TeX/texbin
set PATH $PATH /usr/local/bin
set PATH $PATH /usr/bin
set PATH $PATH /bin
set PATH $PATH /usr/sbin
set PATH $PATH /sbin
set PATH $PATH $SCRIPTSDIR/pfetch
set PATH $PATH $SCRIPTSDIR/vimv
set -x PATH $PATH

set -x VISUAL nvim
set -x EDITOR $VISUAL
set -x MANPAGER "nvim -c \"set ft=man\" -"

set -x FZF_DEFAULT_COMMAND "fd -uu --ignore-file ~/Dropbox/share/fd/ignore \
                               --base-directory ~ -t f -c always |
                            sed \"s/\[1;34m/\[1;90m/g\""

set -x FZF_DEFAULT_OPTS "--reverse --info=inline --hscroll-off=50 \
                         --ansi --color=\"hl:-1,hl+:-1\""

set -x IPYTHONDIR $HOME/.local/share/ipython
set -x MPLCONFIGDIR $HOME/.local/share/matplotlib
set -x LESSHISTFILE $HOME/.cache/less/lesshst
set -x npm_config_cache $HOME/.cache/npm

set -x HOMEBREW_NO_AUTO_UPDATE 1

set -x LANG        en_US.UTF-8
set -x LC_COLLATE  en_US.UTF-8
set -x LC_CTYPE    en_US.UTF-8
set -x LC_MESSAGES en_US.UTF-8
set -x LC_MONETARY en_US.UTF-8
set -x LC_NUMERIC  en_US.UTF-8
set -x LC_TIME     en_US.UTF-8
set -x LC_ALL      en_US.UTF-8

set LS_COLORS "rs=0:di=01;34:ln=01;36:mh=00:pi=40;33:so=01;35:do=01;35:\
bd=40;33;01:cd=40;33;01:or=40;31;01:mi=00:su=37;41:sg=30;43:ca=30;41:tw=30;42:\
ow=34;42:st=37;44:ex=01;32:"

# Archives or compressed files
set LS_COLORS $LS_COLORS"*.tar=01;31:*.tgz=01;31:*.arc=01;31:*.arj=01;31:\
*.taz=01;31:*.lha=01;31:*.lz4=01;31:*.lzh=01;31:*.lzma=01;31:*.tlz=01;31:\
*.txz=01;31:*.tzo=01;31:*.t7z=01;31:*.zip=01;31:*.z=01;31:*.dz=01;31:\
*.gz=01;31:*.lrz=01;31:*.lz=01;31:*.lzo=01;31:*.xz=01;31:*.zst=01;31:\
*.tzst=01;31:*.bz2=01;31:*.bz=01;31:*.tbz=01;31:*.tbz2=01;31:*.tz=01;31:\
*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.war=01;31:*.ear=01;31:*.sar=01;31:\
*.rar=01;31:*.alz=01;31:*.ace=01;31:*.zoo=01;31:*.cpio=01;31:*.7z=01;31:\
*.rz=01;31:*.cab=01;31:*.wim=01;31:*.swm=01;31:*.dwm=01;31:*.esd=01;31:"

# Image formats
set LS_COLORS $LS_COLORS"*.jpg=01;35:*.jpeg=01;35:*.mjpg=01;35:*.mjpeg=01;35:\
*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:\
*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.svg=01;35:\
*.svgz=01;35:*.mng=01;35:*.pcx=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:\
*.m2v=01;35:*.mkv=01;35:*.webm=01;35:*.webp=01;35:*.ogm=01;35:*.mp4=01;35:\
*.m4v=01;35:*.mp4v=01;35:*.vob=01;35:*.qt=01;35:*.nuv=01;35:*.wmv=01;35:\
*.asf=01;35:*.rm=01;35:*.rmvb=01;35:*.flc=01;35:*.avi=01;35:*.fli=01;35:\
*.flv=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.yuv=01;35:\
*.cgm=01;35:*.emf=01;35:"

# Audio formats
set LS_COLORS $LS_COLORS"*.aac=00;36:*.au=00;36:*.flac=00;36:*.m4a=00;36:\
*.mid=00;36:*.midi=00;36:*.mka=00;36:*.mp3=00;36:*.mpc=00;36:*.ogg=00;36:\
*.ra=00;36:*.wav=00;36:"

set LS_COLORS $LS_COLORS"*.md=01;04;33:*.pdf=36:"

set -x LS_COLORS $LS_COLORS
