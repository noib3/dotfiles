#!/usr/bin/env bash
#
# Bootstraps a new macOS machine.

# TODO
# 1. purge dsstore cron job every 60s
# 2. unload finder service
# 3. quit finder service
# 4. remove finder from dock service

function echo_start() { printf '\033[32m⟶   \033[0m\033[1m'"$1"'\033[0m\n\n'; }
function echo_step() { printf '\033[34m⟶   \033[0m\033[1m'"$1"'\033[0m\n'; }
function echo_substep() { printf '\033[33m→ \033[0m\033[3m'"$1"'\033[0m\n'; }
function echo_reboot() { printf '\r\033[31m⟶   \033[0m\033[1m'"$1"'\033[0m'; }
function error_exit() { printf '\033[31mERROR: \033[0m'"$1"'\n' && exit 1; }

function exit_if_not_darwin() {
  # Checks if the script is being run on a macOS machine. Echoes an error
  # message and exits if it isn't.

  [[ "$OSTYPE" == "darwin"* ]] \
    || error_exit "We are not on macOS."
}

function exit_if_root() {
  # Checks if the script is being run as root. Echoes an error message and
  # exits if it is.

  (( EUID != 0 )) \
    || error_exit "This script shouldn't be run as root."
}

function exit_if_sip_enabled() {
  # Checks if System Integrity Protection (SIP) is enabled. Echoes the steps to
  # disable it and exits if it is.

  [[ $(csrutil status | sed 's/[^:]*:\s*\([^\.]*\).*/\1/') == "disabled" ]] \
    || error_exit "SIP needs to be disabled for the installation.

To disable it you need to:
  1. reboot;
  2. hold down Command-R while rebooting to go into recovery mode;
  3. open a terminal via Utilities -> Terminal;
  4. execute \033[1mcsrutil disable\033[0m;
  5. reboot.
"
}

function greetings_message() {
  # Echoes a greetings message listing the passwords needed for a full
  # installation. Then waits for user input.

  echo_start "Starting the installation"
  echo -e "\
You'll need:
  1. $(whoami)'s password to add $(whoami) to the sudoers file;
  2. the Firefox account's password to link bookmarks, previous history,
     addons, etc;
"
  read -n 1 -s -r -p "Press any key to continue:"
  printf '\n\n'
}

function command_line_tools() {
  # Checks if the command line tools are installed. Installs them if they
  # aren't.

  echo_step "Installing command line tools"
  xcode-select --print-path &>/dev/null \
    || xcode-select --install &>/dev/null
  printf '\n' && sleep 1
}

function whoami_to_sudoers() {
  # Adds the current user to the sudoers file with the NOPASSWD directive,
  # allowing it to issue sudo commands without being prompted for a password.

  echo_step "Adding $(whoami) to /private/etc/sudoers"
  printf "\n$(whoami)		ALL = (ALL) NOPASSWD: ALL\n" \
    | sudo tee -a /private/etc/sudoers &>/dev/null
  printf '\n' && sleep 1
}

function set_sys_defaults() {
  # Sets some macOS system defaults. Then asks for user input to set the
  # current timezone and the host name.

  echo_step "Setting macOS system preference defaults"

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

function homebrew() {
  # Checks if homebrew is installed, it installs it if it isn't. Then
  # it installs the formulas taken from the Brewfile in the GitHub repo.

  echo_step "Downloading homebrew, then formulas from Brewfile"

  local path_homebrew_install_script=\
https://raw.githubusercontent.com/Homebrew/install/master/install.sh

  local path_brewfile=\
https://raw.githubusercontent.com/noib3/dotfiles/macOS/bootstrap/Brewfile

  which -s brew && brew update \
    || bash -c "$(curl -fsSL $path_homebrew_install_script)"

  curl -fsSL $path_brewfile -o /tmp/Brewfile
  brew bundle install --file /tmp/Brewfile

  printf '\n' && sleep 1
}

function patch_window_edges() {
  # Downloads an edited .car file to display windows with squared edges, then
  # substitutes the default one with it.

  echo_step "Patching UI to get squared window edges"

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

function unload_Finder {
  # Creates a service that quits Finder after the user logs in.

  echo_step "Creating a new service that quits Finder after loggin in"

  local agent_scripts_dir=~/.local/agent-scripts

  mkdir -p "${agent_scripts_dir}"

  cat << EOF >> "${agent_scripts_dir}/unload-Finder.sh"
#!/usr/bin/env bash

launchctl unload /System/Library/LaunchAgents/com.apple.Finder.plist
osascript -e 'quit app "Finder"'
EOF

  chmod +x "${agent_scripts_dir}/unload-Finder.sh"

  cat << EOF >> "${HOME}/Library/LaunchAgents/$(whoami).unload-Finder.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" \
"http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>$(whoami).unload-Finder</string>
  <key>ProgramArguments</key>
  <array>
    <string>${agent_scripts_dir}/unload-Finder.sh</string>
  </array>
  <key>EnvironmentVariables</key>
  <dict>
    <key>PATH</key>
    <string>/usr/local/bin:/usr/bin:/bin</string>
  </dict>
  <key>RunAtLoad</key>
  <true/>
</dict>
</plist>
EOF

  launchctl load \
    "${HOME}"/Library/LaunchAgents/"$(whoami)".unload-Finder.plist

  printf '\n' && sleep 1
}

function add_remove_from_dock {
  # Add the "Remove from Dock" option when right-clicking the Finder's Dock
  # icon.

  echo_step "Adding the \"Remove from Dock\" option to the Finder's Dock icon"

  sudo mount -uw /

  sudo /usr/libexec/PlistBuddy \
    -c "Add :finder-quit:0 dict" \
    -c "Add :finder-quit:0:command integer 1004" \
    -c "Add :finder-quit:0:name string REMOVE_FROM_DOCK" \
    -c "Add :finder-running:0 dict" \
    -c "Add :finder-running:0:command integer 1004" \
    -c "Add :finder-running:0:name string REMOVE_FROM_DOCK" \
      /System/Library/CoreServices/Dock.app/Contents/Resources/DockMenus.plist

  killall Dock

  printf '\n' && sleep 1
}

function remove_Finder_from_Dock {
  # Creates a service that removes the Finder icon from the Dock after the user
  # logs in.

  echo_step "Creating a new service that removes Finder from the Dock"

  local agent_scripts_dir=~/.local/agent-scripts

  mkdir -p "${agent_scripts_dir}"

  cat << EOF >> "${agent_scripts_dir}/remove-Finder-from-Dock.sh"
#!/usr/bin/env bash

osascript -e 'tell application "System Events"' \\
          -e    'tell UI element "Finder" of list 1 of process "Dock"' \\
          -e        'perform action "AXShowMenu"' \\
          -e        'click menu item "Remove from Dock" of menu 1' \\
          -e    'end tell' \\
          -e 'end tell'
EOF

  chmod +x "${agent_scripts_dir}/remove-Finder-from-Dock.sh"

  cat << EOF >> \
    "${HOME}/Library/LaunchAgents/$(whoami).remove-Finder-from-Dock.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" \
"http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>$(whoami).remove-Finder-from-Dock</string>
  <key>ProgramArguments</key>
  <array>
    <string>${agent_scripts_dir}/remove-Finder-from-Dock.sh</string>
  </array>
  <key>EnvironmentVariables</key>
  <dict>
    <key>PATH</key>
    <string>/usr/local/bin:/usr/bin:/bin</string>
  </dict>
  <key>RunAtLoad</key>
  <true/>
</dict>
</plist>
EOF

  launchctl load \
    "${HOME}"/Library/LaunchAgents/"$(whoami)".remove-Finder-from-Dock.plist

  printf '\n' && sleep 1
}

function purge_DSStore {
  # Creates a service that every 60 seconds searches every .DS_Store file in /
  # and deletes them.

  echo_step "Creating a new service that deletes every .DS_Store file every \
60 seconds"

  local agent_scripts_dir=~/.local/agent-scripts

  mkdir -p "${agent_scripts_dir}"

  cat << EOF >> "${agent_scripts_dir}/purge-DSStore.sh"
#!/usr/bin/env bash

sudo mount -uw /
osascript -e 'quit app "Finder"'
fd -uu ".DS_Store" / -X sudo rm
EOF

  chmod +x "${agent_scripts_dir}/purge-DSStore.sh"

  cat << EOF >> "${HOME}/Library/LaunchAgents/$(whoami).purge-DSStore.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" \
"http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>$(whoami).purge-DSStore</string>
  <key>ProgramArguments</key>
  <array>
    <string>${agent_scripts_dir}/purge-DSStore.sh</string>
  </array>
  <key>EnvironmentVariables</key>
  <dict>
    <key>PATH</key>
    <string>/usr/local/bin:/usr/bin:/bin</string>
  </dict>
  <key>StartInterval</key>
  <integer>60</integer>
  <key>ThrottleInterval</key>
  <integer>0</integer>
</dict>
</plist>
EOF

  launchctl load \
    "${HOME}"/Library/LaunchAgents/"$(whoami)".purge-DSStore.plist

  printf '\n' && sleep 1
}

function setup_dotfiles() {
  # Downloads the current dotfiles from the GitHub repo. Replaces the username
  # in "firefox/userChrome.css" and "alacritty/alacritty.yml" with $(whoami).
  # Lastly, it overrides ~/.config with the cloned repo.

  echo_step "Downloading and installing dotfiles \
from noib3/dotfiles (macOS branch)"

  git clone git@github.com:noib3/dotfiles.git --branch macOS /tmp/dotfiles

  sed -i "s@/Users/[^/]*/\(.*\)@/Users/`whoami`/\1@g" \
    /tmp/dotfiles/alacritty/alacritty.yml \
    /tmp/dotfiles/firefox/userChrome.css

  rm -rf ~/.config
  mv /tmp/dotfiles ~/.config

  printf '\n' && sleep 1
}

function chsh_fish() {
  # Adds fish to the list of the valid shells, then sets fish as the chosen
  # login shell.

  echo_step "Setting up the fish shell"

  sudo sh -c "echo /usr/local/bin/fish >> /etc/shells"
  chsh -s /usr/local/bin/fish

  printf '\n' && sleep 1
}

function terminfo_alacritty() {
  # Downloads and installs the terminfo database for alacritty.

  local path_alacritty_terminfo=\
https://raw.githubusercontent.com/\
alacritty/alacritty/master/extra/alacritty.info

  wget -P /tmp/ $path_alacritty_terminfo
  sudo tic -xe alacritty,alacritty-direct /tmp/alacritty.info

  printf '\n' && sleep 1
}

function python_install_modules() {
  # Installs the python modules taken from the requirements.txt file in the
  # GitHub repo.

  echo_step "Downloading python modules"

  local path_python_requirements=\
https://raw.githubusercontent.com/noib3/dotfiles/\
macOS/boostrap/requirements.txt

  wget -P /tmp/ $path_python_requirements
  pip3 install -r /tmp/requirements.txt

  printf '\n' && sleep 1
}

function vimplug_install() {
  # Downloads vim-plug, a tool to manage Vim plugins.

  echo_step "Installing vim-plug"

  local path_vim_plug=\
https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

  local path_destination_vim_plug=~/.local/share/nvim/site/autoload/plug.vim

  sh -c \
    'curl -fLo "${path_destination_vim_plug}" --create-dirs "${path_vim_plug}"'

  printf '\n' && sleep 1
}

function setup_firefox() {
  # Sets Firefox as the default browser. Symlinks the files in
  # ~/.config/firefox to all the user profiles. Downloads and installs the
  # no-new-tab version of Tridactyl. Installs the native messager to allow
  # Tridactyl to run other programs.

  echo_step "Setting up Firefox"

  # Open firefox without being prompted for dialog
  sudo xattr -r -d com.apple.quarantine /Applications/Firefox.app

  printf "\n"
  echo_substep "Set Firefox as the default browser"
  echo_substep "Log into your Firefox account"
  echo_substep "Quit Firefox"
  sleep 2

  /Applications/Firefox.app/Contents/MacOS/firefox \
    --setDefaultBrowser \
    --new-tab "about:preferences#sync" \

  profiles="$(ls "~/Library/Application Support/Firefox/Profiles/" \
                | grep release)"

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

  echo_substep "Accept Tridactyl installation"
  echo_substep "Quit Firefox"
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
  # Opens a dummy pdf file used to trigger the creation of Skim's property list
  # file in ~/Library/Preferences. Sets a few Skim preferences.

  echo_step "Setting up Skim preferences"

  local path_plist_trigger_file=\
https://github.com/noib3/dotfiles/macOS/bootstrap/Skim_plist_trigger.pdf

  wget -P /tmp/ $path_plist_trigger_file

  echo_substep "Quit Skim in a few seconds"
  sleep 2

  # Open pdf with Skim to generate plist file
  /Applications/Skim.app/Contents/MacOS/Skim /tmp/Skim_plist_trigger.pdf

  # Use Skim as the default PDF viewer
  duti -s net.sourceforge.skim-app.skim .pdf all

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
  # Allow accessibility permissions to skhd, spacebar, yabai. Then start
  # redshift, skhd, spacebar, syncthing, transmission-cli, yabai.

  echo_step "Allowing accessibility permissions to skhd, yabai and spacebar"

  local path_skhd_bin="$(readlink -f /usr/local/bin/skhd)"
  local path_spacebar_bin=$(readlink -f /usr/local/bin/spacebar)
  local path_yabai_bin=$(readlink -f /usr/local/bin/yabai)

  sudo tccutil --insert "$path_skhd_bin"
  sudo tccutil --insert "$path_spacebar_bin"
  sudo tccutil --insert "$path_yabai_bin"

  brew services start redshift
  brew services start skhd
  brew services start spacebar
  brew services start syncthing
  brew services start transmission-cli
  brew services start yabai

  printf '\n' && sleep 1
}

function cleanup() {
  # Remove unneeded files, either already present in the machine or created
  # by a function in this script.

  echo_step "Cleaning up some files"

  # rm -rf ~/Public
  # rm /tmp/Brewfile
  # rm /tmp/alacritty.info
  # rm /tmp/requirements.txt
  # rm /tmp/tridactyl_no_new_tab_beta-latest.xpi
  # rm /tmp/trinativeinstall.sh
  # rm /tmp/Skim_plist_trigger.pdf

  printf '\n' && sleep 1
}

function countdown_reboot() {
  # Display a nine second countdown, then reboot the system.

  for n in {9..0}; do
    echo_reboot "Rebooting in $n"
    [[ ${n} == 0 ]] || sleep 1
  done

  printf '\n\n'
  osascript -e "tell app \"System Events\" to restart"
}

exit_if_not_darwin
exit_if_root
exit_if_sip_enabled
greetings_message
command_line_tools
# whoami_to_sudoers
# set_sys_defaults
# homebrew
# patch_window_edges
# unload_Finder
# add_remove_from_dock
# remove_Finder_from_Dock
# purge_DSStore
# setup_dotfiles
# chsh_fish
# terminfo_alacritty
# python_install_modules
# vimplug_install
# setup_firefox
# setup_skim
# allow_accessibility
# cleanup
# countdown_reboot

# ----------------------------------------------------------------------------

# NOW IT'S PERSONAL

# 4. brew services stop syncthing
#    edit ~/Library/Application Support/Syncthing/config.xml, change markerName
#    from .stfolder to wallpapers for /Users/noibe/Sync
#    brew services start syncthing

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
#   echo_step "Allowing accessibility permissions to skhd and yabai"
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