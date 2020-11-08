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
set PATH $PATH /Applications/Firefox.app/Contents/MacOS
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

set -x LS_COLORS "no=00;38;5;244:rs=0:di=00;38;5;33:ln=01;38;5;37:mh=00:\
pi=48;5;230;38;5;136;01:so=48;5;230;38;5;136;01:do=48;5;230;38;5;136;01:\
bd=48;5;230;38;5;244;01:cd=48;5;230;38;5;244;01:or=48;5;235;38;5;160:\
su=48;5;160;38;5;230:sg=48;5;136;38;5;230:ca=30;41:tw=48;5;64;38;5;230:\
ow=48;5;235;38;5;33:st=48;5;33;38;5;230:ex=01;38;5;64:*.tar=00;38;5;61:\
*.tgz=01;38;5;61:*.arj=01;38;5;61:*.taz=01;38;5;61:*.lzh=01;38;5;61:\
*.lzma=01;38;5;61:*.tlz=01;38;5;61:*.txz=01;38;5;61:*.zip=01;38;5;61:\
*.zst=01;38;5;61:*.z=01;38;5;61:*.Z=01;38;5;61:*.dz=01;38;5;61:\
*.gz=01;38;5;61:*.lz=01;38;5;61:*.xz=01;38;5;61:*.bz2=01;38;5;61:\
*.bz=01;38;5;61:*.tbz=01;38;5;61:*.tbz2=01;38;5;61:*.tz=01;38;5;61:\
*.deb=01;38;5;61:*.rpm=01;38;5;61:*.jar=01;38;5;61:*.rar=01;38;5;61:\
*.ace=01;38;5;61:*.zoo=01;38;5;61:*.cpio=01;38;5;61:*.7z=01;38;5;61:\
*.rz=01;38;5;61:*.apk=01;38;5;61:*.gem=01;38;5;61:*.jpg=00;38;5;136:\
*.JPG=00;38;5;136:*.jpeg=00;38;5;136:*.gif=00;38;5;136:*.bmp=00;38;5;136:\
*.pbm=00;38;5;136:*.pgm=00;38;5;136:*.ppm=00;38;5;136:*.tga=00;38;5;136:\
*.xbm=00;38;5;136:*.xpm=00;38;5;136:*.tif=00;38;5;136:*.tiff=00;38;5;136:\
*.png=00;38;5;136:*.PNG=00;38;5;136:*.svg=00;38;5;136:*.svgz=00;38;5;136:\
*.mng=00;38;5;136:*.pcx=00;38;5;136:*.dl=00;38;5;136:*.xcf=00;38;5;136:\
*.xwd=00;38;5;136:*.yuv=00;38;5;136:*.cgm=00;38;5;136:*.emf=00;38;5;136:\
*.eps=00;38;5;136:*.CR2=00;38;5;136:*.ico=00;38;5;136:*.nef=00;38;5;136:\
*.NEF=00;38;5;136:*.webp=00;38;5;136:*.tex=01;38;5;245:*.rdf=01;38;5;245:\
*.owl=01;38;5;245:*.n3=01;38;5;245:*.ttl=01;38;5;245:*.nt=01;38;5;245:\
*.torrent=01;38;5;245:*.xml=01;38;5;245:*Makefile=01;38;5;245:\
*Rakefile=01;38;5;245:*Dockerfile=01;38;5;245:*build.xml=01;38;5;245:\
*rc=01;38;5;245:*1=01;38;5;245:*.nfo=01;38;5;245:*README=01;38;5;245:\
*README.txt=01;38;5;245:*readme.txt=01;38;5;245:*.md=01;38;5;245:\
*README.markdown=01;38;5;245:*.ini=01;38;5;245:*.yml=01;38;5;245:\
*.cfg=01;38;5;245:*.conf=01;38;5;245:*.h=01;38;5;245:*.hpp=01;38;5;245:\
*.c=01;38;5;245:*.cpp=01;38;5;245:*.cxx=01;38;5;245:*.cc=01;38;5;245:\
*.objc=01;38;5;245:*.sqlite=01;38;5;245:*.go=01;38;5;245:*.sql=01;38;5;245:\
*.csv=01;38;5;245:*.log=00;38;5;240:*.bak=00;38;5;240:*.aux=00;38;5;240:\
*.lof=00;38;5;240:*.lol=00;38;5;240:*.lot=00;38;5;240:*.out=00;38;5;240:\
*.toc=00;38;5;240:*.bbl=00;38;5;240:*.blg=00;38;5;240:*~=00;38;5;240:\
*#=00;38;5;240:*.part=00;38;5;240:*.incomplete=00;38;5;240:*.swp=00;38;5;240:\
*.tmp=00;38;5;240:*.temp=00;38;5;240:*.o=00;38;5;240:*.pyc=00;38;5;240:\
*.class=00;38;5;240:*.cache=00;38;5;240:*.aac=00;38;5;166:*.au=00;38;5;166:\
*.flac=00;38;5;166:*.mid=00;38;5;166:*.midi=00;38;5;166:*.mka=00;38;5;166:\
*.mp3=00;38;5;166:*.mpc=00;38;5;166:*.ogg=00;38;5;166:*.opus=00;38;5;166:\
*.ra=00;38;5;166:*.wav=00;38;5;166:*.m4a=00;38;5;166:*.axa=00;38;5;166:\
*.oga=00;38;5;166:*.spx=00;38;5;166:*.xspf=00;38;5;166:*.mov=01;38;5;166:\
*.MOV=01;38;5;166:*.mpg=01;38;5;166:*.mpeg=01;38;5;166:*.m2v=01;38;5;166:\
*.mkv=01;38;5;166:*.ogm=01;38;5;166:*.mp4=01;38;5;166:*.m4v=01;38;5;166:\
*.mp4v=01;38;5;166:*.vob=01;38;5;166:*.qt=01;38;5;166:*.nuv=01;38;5;166:\
*.wmv=01;38;5;166:*.asf=01;38;5;166:*.rm=01;38;5;166:*.rmvb=01;38;5;166:\
*.flc=01;38;5;166:*.avi=01;38;5;166:*.fli=01;38;5;166:*.flv=01;38;5;166:\
*.gl=01;38;5;166:*.m2ts=01;38;5;166:*.divx=01;38;5;166:*.webm=01;38;5;166:\
*.axv=01;38;5;166:*.anx=01;38;5;166:*.ogv=01;38;5;166:*.ogx=01;38;5;166:"

# set LS_COLORS $LS_COLORS

# set LS_COLORS "rs=0:di=01;34:ln=01;36:mh=00:pi=40;33:so=01;35:do=01;35:\
# bd=40;33;01:cd=40;33;01:or=40;31;01:mi=00:su=37;41:sg=30;43:ca=30;41:tw=30;42:\
# ow=34;42:st=37;44:ex=01;32:"

# # Archives or compressed files
# set LS_COLORS $LS_COLORS"*.tar=01;31:*.tgz=01;31:*.arc=01;31:*.arj=01;31:\
# *.taz=01;31:*.lha=01;31:*.lz4=01;31:*.lzh=01;31:*.lzma=01;31:*.tlz=01;31:\
# *.txz=01;31:*.tzo=01;31:*.t7z=01;31:*.zip=01;31:*.z=01;31:*.dz=01;31:\
# *.gz=01;31:*.lrz=01;31:*.lz=01;31:*.lzo=01;31:*.xz=01;31:*.zst=01;31:\
# *.tzst=01;31:*.bz2=01;31:*.bz=01;31:*.tbz=01;31:*.tbz2=01;31:*.tz=01;31:\
# *.deb=01;31:*.rpm=01;31:*.jar=01;31:*.war=01;31:*.ear=01;31:*.sar=01;31:\
# *.rar=01;31:*.alz=01;31:*.ace=01;31:*.zoo=01;31:*.cpio=01;31:*.7z=01;31:\
# *.rz=01;31:*.cab=01;31:*.wim=01;31:*.swm=01;31:*.dwm=01;31:*.esd=01;31:"

# # Image formats
# set LS_COLORS $LS_COLORS"*.jpg=01;35:*.jpeg=01;35:*.mjpg=01;35:*.mjpeg=01;35:\
# *.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:\
# *.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.svg=01;35:\
# *.svgz=01;35:*.mng=01;35:*.pcx=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:\
# *.m2v=01;35:*.mkv=01;35:*.webm=01;35:*.webp=01;35:*.ogm=01;35:*.mp4=01;35:\
# *.m4v=01;35:*.mp4v=01;35:*.vob=01;35:*.qt=01;35:*.nuv=01;35:*.wmv=01;35:\
# *.asf=01;35:*.rm=01;35:*.rmvb=01;35:*.flc=01;35:*.avi=01;35:*.fli=01;35:\
# *.flv=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.yuv=01;35:\
# *.cgm=01;35:*.emf=01;35:"

# # Audio formats
# set LS_COLORS $LS_COLORS"*.aac=00;36:*.au=00;36:*.flac=00;36:*.m4a=00;36:\
# *.mid=00;36:*.midi=00;36:*.mka=00;36:*.mp3=00;36:*.mpc=00;36:*.ogg=00;36:\
# *.ra=00;36:*.wav=00;36:"

# set LS_COLORS $LS_COLORS"*.md=01;04;33:*.pdf=36:"

# set -x LS_COLORS $LS_COLORS
