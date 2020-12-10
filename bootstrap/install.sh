#!/usr/bin/env bash

function print_start() { printf '\033[32m⟶   \033[0m\033[1m'"$1"'\033[0m\n\n'; }
function print_step() { printf '\033[34m⟶   \033[0m\033[1m'"$1"'\033[0m\n'; }
function print_reboot() { printf '\r\033[31m⟶   \033[0m\033[1m'"$1"'\033[0m'; }
function print_substep() { printf '\033[33m→ \033[0m\033[3m'"$1"'\033[0m\n'; }
function print_error() { printf '\033[31mERROR: \033[0m\033[1m'"$1"'\033[0m\n'; }

function check_sip_status() {
  if [[ $(csrutil status | sed 's/[^:]*:\s*\([^\.]*\).*/\1/') != "disabled" ]]
  then
    print_error "SIP needs to be disabled for the installation"
    echo -e "\
To disable it you need to:
  1. Restart macOS;
  2. Hold down Command-R while rebooting to go into recovery mode;
  3. Open a terminal via Utilities -> Terminal;
  4. execute \033[1mcsrutil disable\033[0m;
  5. Reboot.

If SIP was disabled correctly the output of \033[1mcsrutil status\033[0m will
be \"System Integrity Protection status: disabled\".
"
    exit 1
  fi
}

function greeting_message() {
  print_start "Install starting!"
  echo -e "\
You'll need the following passwords:
  1. The current user's password if you want to add it to the sudoers file;
  2. Your Firefox account's password if you want to link your bookmarks,
     previous history, addons, etc;
"
  read -n 1 -s -r -p "Press any key to continue:"
  printf '\n\n'
}

function command_line_tools() {
  print_step "Installing command line tools"
  if ! xcode-select --print-path &>/dev/null; then
    xcode-select --install &>/dev/null
  fi
  printf '\n' && sleep 1
}

function whoami_to_sudoers() {
  print_step "Adding current user to /private/etc/sudoers"
  printf "\n$(whoami)		ALL = (ALL) NOPASSWD: ALL\n" \
  | sudo tee -a /private/etc/sudoers &>/dev/null
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
  sudo systemsetup -settimezone "$timezone" &>/dev/null

  printf '\n' && sleep 1
}

function get_homebrew() {
  print_step "Downloading homebrew, then programs from Brewfile"

  local path_homebrew_install_script=\
https://raw.githubusercontent.com/Homebrew/install/master/install.sh

  local path_brewfile=\
https://raw.githubusercontent.com/noib3/dotfiles/macOS/Brewfile

  which -s brew
  if [[ $? != 0 ]]; then
    bash -c "$(curl -fsSL $path_homebrew_install_script)"
  else
    brew update
  fi

  curl -fsSL $path_brewfile -o /tmp/Brewfile
  brew bundle install --file /tmp/Brewfile

  printf '\n' && sleep 1
}

function patch_square_edges() {
  print_step "Patching .car file to get square edges"

  # https://cutt.ly/IhTI04v

  local path_edited_car_file=\
https://github.com/\
tsujp/custom-macos-gui/tree/master/\
DarkAquaAppearance/Edited/DarkAquaAppearance.car

  local path_destination_car_file=\
/System/Library/CoreServices/SystemAppearance.bundle/\
Contents/Resources/DarkAquaAppearance.car

  sudo mount -uw /
  wget -P /tmp/ $path_edited_car_file
  mv --force /tmp/DarkAquaAppearance.car $path_destination_car_file

  printf '\n' && sleep 1
}

function setup_odourless() {
  print_step "Setting up Odourless"

  # STOP CREATION OF .DS_Store FILES
  # download the latest .zip release from 'https://github.com/xiaozhuai/odourless/releases'
  # move it to /Applications
  # in case it doesn't launch (in my case it said something like 'this has to be under /Applications', even if it was under /Applications), just run it from the command line:
  # /Applications/Odourless.app/Contents/MacOS/odourless
  # install the daemon on the lil gui that pops up
  # reboot and you should be gucci

  # download latest release
  # unzip it
  # mv ./Odourless.app /Applications/Odourless.app
  # /Applications/Odourless.app/Contents/Resources/install-daemon
  # /Applications/Odourless.app/Contents/Resources/start-daemon
  local path_resources="/Applications/Odourless.app/Contents/Resources"
  cat "$path_resources/odourless-daemon.plist" \
  | sed "s#___replace_me_daemon_path__#$path_resources/bin/odourless-daemon#" \
  | sudo tee /Library/LaunchDaemons/odourless-daemon.plist &>/dev/null

  launchctl load "/Library/LaunchDaemons/odourless-daemon.plist"

  printf '\n' && sleep 1
}

function setup_fish() {
  print_step "Setting up the fish shell"

  sudo sh -c "echo /usr/local/bin/fish >> /etc/shells"
  chsh -s /usr/local/bin/fish

  local path_alacritty_terminfo=\
https://raw.githubusercontent.com/\
alacritty/alacritty/master/extra/alacritty.info

  wget -P /tmp/ $path_alacritty_terminfo
  sudo tic -xe alacritty,alacritty-direct /tmp/alacritty.info
  rm /tmp/alacritty.info

  printf '\n' && sleep 1
}

function setup_python() {
  # For UltiSnips
  pip3 install neovim

  # For coc-python
  pip3 install jedi
}

function setup_vimplug() {
  print_step "Installing vim-plug"

  local path_vim_plug=\
https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

  local path_destination_vim_plug=~/.local/share/nvim/site/autoload/plug.vim

  curl -fLo $path_vim_plug --create-dirs $path_destination_vim_plug

  printf '\n' && sleep 1
}

function setup_firefox() {
  print_step "Setting up Firefox"

  # Open firefox without being prompted for dialog
  sudo xattr -r -d com.apple.quarantine /Applications/Firefox.app

  printf "\n"
  print_substep "Set Firefox as the default browser"
  print_substep "Log into your Firefox account"
  print_substep "Quit Firefox"
  sleep 2

  /Applications/Firefox.app/Contents/MacOS/firefox \
    --setDefaultBrowser \
    --new-tab "about:preferences#sync" \

  profiles=\
"$(ls "~/Library/Application Support/Firefox/Profiles/" | grep release)"

  # Symlink firefox config
  for profile in "${profiles[@]}"; do
    ln -s --force \
      ~/.config/firefox/user.js \
      ~/Library/Application\ Support/Firefox/Profiles/"$profile"/user.js
    mkdir -p \
      ~/Library/Application\ Support/Firefox/Profiles/"$profile"/chrome
    ln -s --force \
      ~/.config/firefox/userChrome.css \
      ~/Library/Application\ Support/Firefox/Profiles/"$profile"/chrome/
    ln --force \
      ~/.config/firefox/userContent.css \
      ~/Library/Application\ Support/Firefox/Profiles/"$profile"/chrome/
  done

  # Download and install tridactyl (no-new-tab version)
  printf "\n"

  local $path_tridactyl_xpi=
https://tridactyl.cmcaine.co.uk/betas/nonewtab/\
tridactyl_no_new_tab_beta-latest.xpi

  wget -P /tmp/ $path_tridactyl_xpi

  print_substep "Accept Tridactyl installation"
  print_substep "Quit Firefox"
  sleep 2

  /Applications/Firefox.app/Contents/MacOS/firefox \
    /tmp/tridactyl_no_new_tab_beta-latest.xpi

  local $path_native_installer=\
https://raw.githubusercontent.com/tridactyl/tridactyl/master/native/install.sh

  # Install native messanger for tridactyl
  curl \
    -fsSl $path_native_installer \
    -o /tmp/trinativeinstall.sh && sh /tmp/trinativeinstall.sh master

  printf '\n' && sleep 1
}

function setup_skim() {
  print_step "Setting up Skim preferences"

  # Use Skim as the default PDF viewer

  # Open pdf with Skim to generate plist file

  # Preferences -> Sync -> Check for file changes
  defaults write -app Skim SKAutoCheckFileUpdate -int 1

  # Preferences -> Sync -> Reload automatically
  defaults write -app Skim SKAutoReloadFileUpdate -int 1

  # Preferences -> General -> Remember last page viewed
  defaults write -app Skim SKRememberLastPageViewed -int 1

  # Preferences -> General -> Open files: -> Fit
  defaults write -app Skim SKInitialWindowSizeOption -int 2

  # View -> Hide Contents Pane
  defaults write -app Skim SKLeftSidePaneWidth -int 0

  # View -> Hide Notes Pane
  defaults write -app Skim SKRightSidePaneWidth -int 0

  # View -> Hide Status Bar
  defaults write -app Skim SKShowStatusBar -int 0

  # View -> Toggle Toolbar
  plutil -replace "NSToolbar Configuration SKDocumentToolbar"."TB Is Shown" \
    -bool NO ~/Library/Preferences/net.sourceforge.skim-app.skim.plist

  printf '\n' && sleep 1
}

function allow_accessibility() {
  print_step "Allowing accessibility permissions to skhd, yabai and spacebar"

  local path_skhd_bin="$(readlink -f /usr/local/bin/skhd)"
  local path_spacebar_bin=$(readlink -f /usr/local/bin/spacebar)
  local path_yabai_bin=$(readlink -f /usr/local/bin/yabai)

  sudo tccutil --insert "$path_skhd_bin"
  sudo tccutil --insert "$path_spacebar_bin"
  sudo tccutil --insert "$path_yabai_bin"

  printf '\n' && sleep 1
}

function cleanup() {
  print_step "Cleaning up some files"

  # DESC: Cleans up all the cache/history files
  # ARGS: None
  # OUTS: None
  # NOTE: None

  # Remove public folder from home folder
  # rm -rf Public
  # rm ~/.config/zsh/.zsh-history ~/.CFUserTextEncoding ~/.viminfo ~/.zsh-history

  printf '\n' && sleep 1
}

function reboot() {
  for n in {9..0}; do
    print_reboot "Rebooting in $n"
    [[ ${n} == 0 ]] || sleep 1
  done

  printf '\n\n'
  osascript -e "tell app \"System Events\" to restart"
}

check_sip_status
greeting_message
# command_line_tools
# whoami_to_sudoers
# set_sys_defaults
# get_homebrew
# patch_square_edges
# setup_odourless
# setup_fish
# setup_github
# setup_vimplug
# setup_firefox
# setup_skim
# allow_accessibility
# cleanup
# reboot

# ----------------------------------------------------------------------------


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
# Sign in to gmail to get bitwarden master password
# login youtube, switch account and enable dark mode and english
# Log into bitwarden, unlock it, then Settings -> Vault timeout -> Never
# EOL
# }

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

# function setup_transmission() {
#   transmission-remote --torrent-done-script \
#     ~/Dropbox/scripts/transmission/notify-done.sh
# }

# set_wallpaper() {

# }
# set_wallpaper

# _setup_skim() {
# }
# _setup_skim

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

# _setup_logi_options() {
#   # 31. Logitech options -> zoom with wheel,
#   #     Logitech options -> Point & Scroll -> Scroll direction -> Natural, Thumb wheel direction -> Inverted
#   #     set pointer and scrolling speed
#   #     Smooth scrolling -> disabled
#   # 36. LogiOptions bind buttons to 'KeyStroke Assignment: Cmd + Left' and 'KeyStroke Assignment: Cmd + Right' (or don't, do that only if you need them to work with qutebrowser, otherwise stick with forward and back)'
# }
# _setup_logi_options

# function allow_accessibility() {
#   print_step "Allowing accessibility permissions to skhd and yabai"
  # Allow dropbox accessibility permissions
  # allow accessibility to logitech options (have to select it manually clicking on +)
# }

# function reboot() {
#   for n in {9..0}; do
#     print_reboot "Rebooting in $n"
#     [[ ${n} == 0 ]] || sleep 1
#   done

#   printf '\n\n'
#   osascript -e "tell app \"System Events\" to restart"
# }

# configure_github_ssh
# configure_clouded
# configure_remote_server
# setup_calcurse
# setup_transmission
# setup_logi_options
# create_todo_file
# set_wallpaper
# cleanup
# reboot
