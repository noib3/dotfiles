#	         _
#	        | |
#   ________| |__  _ __ ___
#   |_  / __| '_ \| '__/ __|
#  _ / /\__ \ | | | | | (__
# (_)___|___/_| |_|_|  \___|


PATH=/usr/local/bin
PATH=$PATH:/usr/local/opt/coreutils/libexec/gnubin
PATH=$PATH:/usr/bin
PATH=$PATH:/usr/sbin
PATH=$PATH:/bin
PATH=$PATH:/sbin
PATH=$PATH:/Library/TeX/texbin
PATH=$PATH:/opt/X11/bin

# SHELL ------------------
unsetopt BEEP
setopt AUTO_CD

export VISUAL=nvim
export EDITOR="$VISUAL"

export LS_COLORS='di=1;36:ex=32'
PROMPT='%F{250}%1~ %F{137}> %F{245}'

HISTFILE=$ZDOTDIR/.zsh_history
PLUGDIR=$ZDOTDIR/plugins

# PLUGINS ----------------
source $PLUGDIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# ALIASES ----------------
alias -g stop='brew services stop'
alias -g restart='brew services restart'

alias -g ndiet='~/programs/ndiet/ndiet.py'
alias -g 2d2small='~/programs/2d2small/2d2small.sh'

alias -g peek='~/scripts/peek/peek.py'
alias -g Omega='~/scripts/Omega/Omega.py'
alias -g lebowski='~/scripts/lebowski/lebowski.py'
alias -g otfinstall='~/scripts/otfinstall/otfinstall.sh'

alias -g ls='ls -A --color'
alias -g c='clear && printf "\e[3J"'
alias -g dlmp3='youtube-dl --extract-audio --audio-format mp3'
alias -g tag='mid3v2' # installed with 'pip3 install mutagen'
alias -g skim='/Applications/Skim.app/Contents/MacOS/Skim'

# EDIT CONFIG FILES ----
alias -g zshrc='nvim $ZDOTDIR/.zshrc && source $ZDOTDIR/.zshrc'
alias -g yabairc='nvim ~/.yabairc && ~/.yabairc'
alias -g skhdrc='nvim ~/.config/skhd/skhdrc && ~/.config/skhd/skhdrc'
alias -g nvimrc='nvim ~/.config/nvim/init.vim'
alias -g firefoxrc='nvim ~/Library/Application\ Support/Firefox/profiles/egbtbydd.default-release/chrome/userChrome.css'
alias -g rangerrc='nvim ~/.config/ranger/rc.conf'
alias -g riflerc='nvim ~/.config/ranger/rifle.conf'
alias -g mpdrc='nvim ~/.mpd/mpd.conf'
alias -g ncmpcpprc='nvim ~/.ncmpcpp/config'

# TRANSMISSION -----------
# function tsm() {
# 	transmission-remote -l | sed '$ d;s/ MB/MB/g;s/ GB/GB/g;s/ days/days/g;s/ hrs/hrs/g;s/ min/min/g;s/ \& /\&/g' |
# 		awk '{
# 			for(i=1;i<=NF;++i)
# 				if (i != 3 && i != 7)
# 					if (i == 4)
# 						printf("%s\t   ", $i);
# 					else if (i == 5)
# 						printf("%s\t      ", $i);
# 					else if (i == 8)
# 						printf("%s\t\t", $i);
# 					else
# 						printf("%s\t", $i);
# 				printf("\n");
# 		}' | sed 's/days/ days/g;s/hrs/ hrs/g;s/min/ min/g;s/Up\&Down	/Downloading/g;s/Uploading	/Uploading/g';
# }

function tsmlist() {
    transmission-remote -l
}
function tsmadd() {
    transmission-remote -a "$1"
}

function tsmstop() {
    transmission-remote -t "$1" --stop
}

function tsmstart() {
    transmission-remote -t "$1" --start
}

# does not delete data
function tsmremove() {
    transmission-remote -t "$1" -r
}

# does delete data
function tsmpurge() {
    transmission-remote -t "$1" --remove-and-delete
}

# Mac OS
alias -g showhidden='defaults write com.apple.Finder AppleShowAllFiles true'
alias -g hidehidden='defaults write com.apple.Finder AppleShowAllFiles false'

# Empty Dock (need to install m with 'brew install m-cli')
# m dock prune

# Show all file extensions
# m finder showextensions YES

# Hide Dock
#   defaults write com.apple.dock autohide-delay -float 1000

# If Dock gets stuck and won't launch anymore
#   launchctl unload -F /System/Library/LaunchAgents/com.apple.Dock.plist
#   launchctl   load -F /System/Library/LaunchAgents/com.apple.Dock.plist
#   launchctl start com.apple.Dock.agent
#   launchctl unload -F /System/Library/LaunchAgents/com.apple.Dock.plist
#   /System/Library/CoreServices/Dock.app/Contents/MacOS/Dock
#   rm -rf ~/Library/Application\ Support/Dock
#   sudo reboot

# python3 -m site --user-site
# kpsewhich -var-value=TEXMFHOME
