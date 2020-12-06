#!/usr/bin/env bash

GITHUB_REPO="noib3/macOS-dotfiles"
GITHUB_REPO_BRANCH="master"
GITHUB_REPO_PATH="Brewfile"

function print_start() { printf '\033[32m→ \033[0m\033[1m'"$1"'\033[0m\n\n'; }
function print_step() { printf '\033[34m→ \033[0m\033[1m'"$1"'\033[0m\n'; }
function print_warning() { printf '\033[33mWARNING: '"$1"'\033[0m\n'; }
function print_error() { printf '\033[31mERROR: '"$1"'\033[0m\n'; }

function greeting_message() {
  print_start "Install starting!"
  printf '\n'
  read -n 1 -s -r -p "Press any key to continue:"
  printf '\n\n'
}

function command_line_tools() {
  print_step "Installing command line tools"
  if ! xcode-select --print-path >/dev/null; then
    xcode-select --install >/dev/null
  fi
  printf '\n' && sleep 1
}

function whoami_to_sudoers() {
  print_step "Adding current user to /private/etc/sudoers"
  printf "\n$(whoami)		ALL = (ALL) NOPASSWD: ALL\n" \
  | sudo tee -a /private/etc/sudoers >/dev/null
  printf '\n' && sleep 1
}

function set_sys_defaults() {
  print_step "Setting system defaults"

  # Enable trackpad's tap to click
  defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad \
    Clicking -bool true

  # Show battery percentage in menu bar
  defaults write com.apple.menuextra.battery ShowPercent -bool true

  # Organize menu bar
  defaults write com.apple.systemuiserver menuExtras -array \
    "/System/Library/CoreServices/Menu Extras/Bluetooth.menu" \
    "/System/Library/CoreServices/Menu Extras/AirPort.menu" \
    "/System/Library/CoreServices/Menu Extras/Battery.menu" \
    "/System/Library/CoreServices/Menu Extras/Clock.menu"

  # Show day of the week in menu bar
  defaults write com.apple.menuextra.clock \
    DateFormat -string "EEE d MMM  HH:mm"

  # Disable 'Are you sure you want to open this application?' dialog
  defaults write com.apple.LaunchServices LSQuarantine -bool false

  # Remove input sources from menu bar
  defaults write com.apple.TextInputMenu visible -bool false

  # Autohide Dock and set a really long show-on-hover delay (1000s ~> 16min)
  defaults write com.apple.dock autohide -bool true
  defaults write com.apple.dock autohide-delay -int 1000

  # Set dock size
  defaults write com.apple.dock tilesize -float 50

  # Empty Dock
  defaults write com.apple.dock persistent-apps -array
  defaults write com.apple.dock persistent-others -array
  defaults write com.apple.dock recent-others -array

  # Autohide menu bar
  defaults write NSGlobalDomain _HIHideMenuBar -bool true

  # Set keyboard key repeat delays
  defaults write NSGlobalDomain InitialKeyRepeat -int 15
  defaults write NSGlobalDomain KeyRepeat -int 2

  # Don't rearrange spaces based on most recent use
  defaults write com.apple.dock mru-spaces -bool false

  # Show scroll bars when scrolling
  defaults write NSGlobalDomain AppleShowScrollBars -string "WhenScrolling"

  # Enable quitting the Finder
  defaults write com.apple.finder QuitMenuItem -bool true

  # Show all files and extensions
  defaults write com.apple.finder AppleShowAllFiles -bool true
  defaults write NSGlobalDomain AppleShowAllExtensions -bool true

  # Don't show warning before changing an extension
  defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

  # Group and sort files by name
  defaults write com.apple.finder FXPreferredGroupBy -string "Name"

  # Make ~ the default directory when opening a new window
  defaults write com.apple.finder NewWindowTarget -string "PfLo"
  defaults write com.apple.finder NewWindowTargetPath \
    -string "file:///Users/$(whoami)/"

  # Remove 'Other' from login screen
  sudo defaults write /Library/Preferences/com.apple.loginwindow \
    SHOWOTHERUSERS_MANAGED -bool false

  # Never let the computer or the display go to sleep
  sudo pmset -a sleep 0
  sudo pmset -a displaysleep 0

  # Never dim the display while on battery power
  sudo pmset -a halfdim 0

  printf '\n'
  read -p "Choose a name for this machine:" hostname
  sudo scutil --set ComputerName "$hostname"
  sudo scutil --set HostName "$hostname"
  sudo scutil --set LocalHostName "$hostname"
  sudo defaults write \
    /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName \
      -string "$hostname"

  printf '\n'
  sudo systemsetup -listtimezones
  read -p "Set the current timezone from the list above:" timezone
  sudo systemsetup -settimezone "$timezone" >/dev/null

  printf '\n' && sleep 1
}

function get_homebrew() {
  print_step "Downloading homebrew, then programs from Brewfile"

  which -s brew
  if [[ $? != 0 ]]; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
  else
    brew update
  fi

  curl -fsSL https://raw.githubusercontent.com/"$GITHUB_REPO"/"$GITHUB_REPO_BRANCH"/"$GITHUB_REPO_PATH"

  brew bundle install

  printf '\n' && sleep 1
}

# function patch_square_edges() {
#   # DESC: Patches .car files with square edges for all macOS GUI programs
#   # ARGS: None
#   # OUTS: None
#   # NOTE: https://github.com/tsujp/custom-macos-gui

#   sudo mount -uw /
#   # 40. SQUARE BORDERS

#   # Place DarkAquaAppearance.car file found here (https://github.com/tsujp/custom-macos-gui/tree/master/DarkAquaAppearance/Edited) in /System/Library/CoreServices/SystemAppearance.bundle/Contents/Resources/DarkAquaAppearance.car. Will have to unmount the filesystem first with

#   # then move the file there replacing the one that's already there, then reboot. (https://www.reddit.com/r/unixporn/comments/i7s3t1/yabaiwm_monokai_machintosh/g16gnck?utm_source=share&utm_medium=web2x)'
# }

# reboot() {
#   osascript -e "tell app \"System Events\" to restart"
# }

greeting_message
# command_line_tools
# whoami_to_sudoers
# set_sys_defaults
# get_homebrew
# patch_square_edges
# reboot


# THIS IS WHAT AN INSTALL SCRIPT SHOULD DO
# 1. Install all programs, setup git with ssh etc..
# 2. Patch square edges
# 3. Clean up
# 4. Create TODO file with things left to do
# 5. reboot

# _patch_square_edges() {
# }
# _patch_square_edges

# _setup_fish() {
#   # 1. Change shell to zsh
#   #       sudo sh -c 'echo /usr/local/bin/zsh >> /etc/shells'
#   #       chsh -s /usr/local/bin/zsh
#   # to get italics suggestions working with fish + alacritty, download
#   #   https://github.com/alacritty/alacritty/blob/master/extra/alacritty.info
#   # then
#   #   sudo tic -xe alacritty,alacritty-direct ./alacritty.info
#   # then you can remove the alacritty.info file, but leave the .terminfo
#   # directory
# }
# _setup_fish

# _setup_neovim() {
#   # 5. Install vim-plug
#   #       curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
#   # 38. 'pip3 install neovim' for UltiSnips

#   # 40. pip3 install jedi if coc-python gives problems
# }
# _setup_neovim

# _setup_firefox() {
#   # 1. Open firefox without being prompted for dialog
#   #       sudo xattr -r -d com.apple.quarantine /Applications/Firefox.app
#   # 2. Download bitwarden firefox extension
#   # 3. Sign in to gmail to get bitwarden master password
#   # 9. Login firefox
#   # 10. firefox about:config options
#   # 11. load firefox config
#   #     cd ~/Library/Application\ Support/Firefox/Profiles/*-release/
#   #     mkdir chrome && cd chrome
#   #     ln -s ~/.config/firefox/userChrome.css
#   #     ln ~/.config/firefox/userContent.css
#   # 29. login youtube, switch account and enable dark mode and english
#   # 22. load vimium c config file

#   # Download tridactyl build without new tab page from
#   #   https://tridactyl.cmcaine.co.uk/betas/nonewtab/
#   # Download the latest release. It will be a .xpi file. Open that file in
#   # Finder, drag and drop it into Firefox -> accept installation.
#   # See https://github.com/tridactyl/tridactyl/issues/534 for source
#   # also, install native-messanger to use :source in tridactyl
#   # see the tutor for instructions (:tutor)
# }
# _setup_firefox

# _setup_skim() {
#   # 25. install skim
#   #       preferences -> Sync -> Check 'check for file changes' and 'reload automatically'
#   # 26. use skim as default pdf viewer
#   #       right click on a pdf file -> get info -> open with: skim.app -> change all
#   # 27. debloat skim
#   #       skim -> view -> hide contents pane and notes pane, toogle toolbar
#   #       skim -> preferences -> general -> remember lat page viewed
# }
# _setup_skim

# _setup_logi_options() {
#   # 31. Logitech options -> zoom with wheel,
#   #     Logitech options -> Point & Scroll -> Scroll direction -> Natural, Thumb wheel direction -> Inverted
#   #     set pointer and scrolling speed
#   #     Smooth scrolling -> disabled
#   # 36. LogiOptions bind buttons to 'KeyStroke Assignment: Cmd + Left' and 'KeyStroke Assignment: Cmd + Right' (or don't, do that only if you need them to work with qutebrowser, otherwise stick with forward and back)'
# }
# _setup_logi_options

# _setup_configs() {
#   # 28. tell transmission to run script when torrent is done
#   #       transmission-remote --torrent-done-script ~/scripts/transmission/notify-done.sh
# }
# _setup_configs

# _setup_scripts() {
#   # 12. download scripts folder
#   #      git clone https://github.com/n0ibe/scripts
#   # 15. link at login files
#   #       cd /Library/LaunchDaemons
#   #       sudo ln -s ~/scripts/@login/Odourless/odourless-daemon.plist
#   #       launchctl load /Library/LaunchDaemons/odourless-daemon.plist
#   #       reboot and test if it works
#   # 18. link login files
#   #     cd ~/Library/LaunchAgents
#   #     ln -s ~/scripts/@login/....plist
#   #     launchctl load ./*.plist
# }
# _setup_scripts

# _setup_calcurse() {
#   # 14. download calcurse
#   #       git clone https://github.com/n0ibe/calcurse
#   #       mv calcurse ~/.local/share/
# }
# _setup_calcurse

# _setup_ndiet() {
#   # 20. install ndiet
#   #       mkdir ~/bin && cd ~/bin
#   #       git clone https://github.com/n0ibe/ndiet
#   #       pip3 install pyfiglet
#   #       pip3 install docopt
#   #       pip3 install gkeepapi
# }
# _setup_ndiet

# _setup_odourless(){
#   # STOP CREATION OF .DS_Store FILES
#   # download the latest .zip release from 'https://github.com/xiaozhuai/odourless/releases'
#   # move it to /Applications
#   # in case it doesn't launch (in my case it said something like 'this has to be under /Applications', even if it was under /Applications), just run it from the command line:
#   # /Applications/Odourless.app/Contents/MacOS/odourless
#   # install the daemon on the lil gui that pops up
#   # reboot and you should be gucci
# }
# _setup_odourless

# _allow_accessibility(){
#   # 6. Allow skhd and yabai accessibility permission
#   # 7. Allow dropbox accessibility permissions
#   # 24. allow accessibility to logitech options (have to select it manually clicking on +)
#   # 30. Allow terminal-notifier notifications
# }
# _allow_accessibility


# set -o errexit
# set -o errtrace
# set -p pipefail








# NOW IT'S PERSONAL

# function configure_github_ssh() {
#   # TODO create ssh key for github
#   #      ssh-keygen -t rsa -C "riccardo.mazzarini98@gmail.com"
#   # TODO copy the content of ~/.ssh/id_rsa.pub, go to github -> settings -> ssh
#   #      and gpg keys -> new ssh key -> paste
#   # TODO answer 'yes' to
#   #      ssh -T git@github.com
#   # TODO go to the repository on github, close or download -> use ssh url, copy
#   #      that url and paste it in <git_repo>/.git/config under [remote "origin"]
#   # TODO Use /usr/local/etc/gitconfig for git config file instead of
#   #      ~/.config/gitconfig. To use that you need to use the --system flag, so
#   #      for ex 'git config --system user.name n0ibe' etc. To list all configs
#   #      and the file where they are defined use 'git config --list --show-origin'
#   # TODO for every git folder downloaded, edit the remote origin url in the git
#   #      config file to be of the form git@github.com:n0ibe/<repo_name>.git
# }

# create_todo_file() {
#   # DESC: Creates a TODO.txt file in the home directory with all the steps left
#   #       to have a finished working environment
#   # ARGS: None
#   # OUTS: None
#   # NOTE: None

#   cat >$HOME/TODO.txt << EOL
# 1. Do this
# 2. Do that
# 3. Attach an external display and rearrange so that the external is the main one
# EOL
# }

# set_wallpaper() {

# }
# set_wallpaper

# cleanup() {
#   # DESC: Cleans up all the cache/history files
#   # ARGS: None
#   # OUTS: None
#   # NOTE: None

#   # Remove public folder from home folder
#   # rm -rf Public
#   # rm ~/.config/zsh/.zsh-history ~/.CFUserTextEncoding ~/.viminfo ~/.zsh-history
# }

# configure_github_ssh
# configure_clouded
# configure_remote_server
# create_todo_file
# set_wallpaper
# cleanup
