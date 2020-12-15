#!/usr/bin/env bash
#
# Bootstraps a new (as in straight out of the box) macOS machine.

# AFTER TESTING
# 1. cleanup
# 2. todo_dot_md

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
  2. your Firefox account's password to link bookmarks, previous history,
     addons, etc;
  3. your Logitech account's password to recover settings for the MX Master 2S
     mouse;
  4. the remote server's Syncthing's Web GUI password to fetch directories to
     sync;
  5. your GitHub account's password to add a new SSH key;
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
  sudo scutil --set ComputerName "${hostname}"
  sudo scutil --set HostName "${hostname}"
  sudo scutil --set LocalHostName "${hostname}"
  sudo defaults write \
    /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName \
      -string "${hostname}"

  printf '\n'

  sudo systemsetup -listtimezones
  read -p "Set the current timezone from the list above:" timezone
  sudo systemsetup -settimezone "${timezone}" &>/dev/null

  printf '\n' && sleep 1
}

function get_homebrew_bundle_brewfile() {
  # Checks if homebrew is installed, if not it installs it. Then it installs
  # the formulas taken from the Brewfile in the GitHub repo.

  echo_step "Downloading homebrew, then formulas from Brewfile"

  local path_homebrew_install_script=\
https://raw.githubusercontent.com/Homebrew/install/master/install.sh

  local path_brewfile=\
https://raw.githubusercontent.com/noib3/dotfiles/macOS/bootstrap/Brewfile

  which -s brew && brew update \
    || bash -c "$(curl -fsSL ${path_homebrew_install_script})"

  curl -fsSL ${path_brewfile} -o /tmp/Brewfile
  brew bundle install --file /tmp/Brewfile

  printf '\n' && sleep 1
}

function patch_window_edges() {
  # Downloads an edited .car file to display windows with squared edges, then
  # substitutes the default one with it.

  echo_step "Patching UI to get squared window edges"

  # https://cutt.ly/IhTI04v

  local path_edited_car_file=\
https://github.com/tsujp/custom-macos-gui/tree/master/DarkAquaAppearance/\
Edited/DarkAquaAppearance.car

  local path_destination_car_file=\
/System/Library/CoreServices/SystemAppearance.bundle/Contents/Resources/\
DarkAquaAppearance.car

  sudo mount -uw /
  wget -P /tmp/ ${path_edited_car_file}
  mv --force /tmp/DarkAquaAppearance.car ${path_destination_car_file}

  printf '\n' && sleep 1
}

function unload_Finder {
  # Creates a service that quits Finder after the user logs in.

  echo_step "Creating a new service that quits Finder after loggin in"

  local agent_scripts_dir="${HOME}"/.local/agent-scripts

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

  local agent_scripts_dir="${HOME}"/.local/agent-scripts

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

function setup_dotfiles() {
  # Downloads the current dotfiles from the GitHub repo. Replaces the username
  # in firefox/userChrome.css and alacritty/alacritty.yml with $(whoami).
  # Lastly, it overrides ~/.config with the cloned repo.

  echo_step "Downloading and installing dotfiles from noib3/dotfiles (macOS \
branch)"

  git clone git@github.com:noib3/dotfiles.git --branch macOS /tmp/dotfiles

  sed -i "s@/Users/[^/]*/\(.*\)@/Users/`whoami`/\1@g" \
    /tmp/dotfiles/alacritty/alacritty.yml \
    /tmp/dotfiles/firefox/userChrome.css

  mv --force /tmp/dotfiles "${HOME}"/.config

  printf '\n' && sleep 1
}

function chsh_fish() {
  # Adds fish to the list of the valid shells, then sets fish as the chosen
  # login shell.

  echo_step "Setting up fish as the default shell"

  sudo sh -c "echo /usr/local/bin/fish >> /etc/shells"
  chsh -s /usr/local/bin/fish

  printf '\n' && sleep 1
}

function terminfo_alacritty() {
  # Downloads and installs the terminfo database for alacritty.

  echo_step "Setting up terminfo for alacritty"

  local path_alacritty_terminfo=\
https://raw.githubusercontent.com/alacritty/alacritty/master/extra/\
alacritty.info

  wget -P /tmp/ "${path_alacritty_terminfo}"
  sudo tic -xe alacritty,alacritty-direct /tmp/alacritty.info

  printf '\n' && sleep 1
}

function pip_install_requirements() {
  # Installs the python modules taken from the requirements.txt file in the
  # GitHub repo.

  echo_step "Downloading python modules"

  local path_python_requirements=\
https://raw.githubusercontent.com/noib3/dotfiles/macOS/boostrap/\
requirements.txt

  wget -P /tmp/ "${path_python_requirements}"
  pip3 install -r /tmp/requirements.txt

  printf '\n' && sleep 1
}

function download_vimplug() {
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

  # Open firefox without being prompted for a "Are you sure.." dialog
  sudo xattr -r -d com.apple.quarantine /Applications/Firefox.app

  printf "\n"
  echo_substep "Set Firefox as the default browser"
  echo_substep "Log into your Firefox account"
  echo_substep "Quit Firefox"
  sleep 2

  /Applications/Firefox.app/Contents/MacOS/firefox \
    --setDefaultBrowser \
    --new-tab "about:preferences#sync" \

  profiles="$(\
    ls "${HOME}/Library/Application Support/Firefox/Profiles/" | grep release \
  )"

  # Symlink firefox config
  for profile in "${profiles[@]}"; do
    ln -s --force \
      "${HOME}/.config/firefox/user.js" \
      "${HOME}/Library/Application Support/Firefox/Profiles/${profile}/user.js"
    mkdir -p \
      "${HOME}/Library/Application Support/Firefox/Profiles/${profile}/chrome"
    ln -s --force \
      "${HOME}/.config/firefox/userChrome.css" \
      "${HOME}/Library/Application Support/Firefox/Profiles/${profile}/chrome/"
    ln --force \
      "${HOME}/.config/firefox/userContent.css" \
      "${HOME}/Library/Application Support/Firefox/Profiles/${profile}/chrome/"
  done

  printf "\n"

  # Download and install tridactyl (no-new-tab version)

  local path_tridactyl_xpi=
https://tridactyl.cmcaine.co.uk/betas/nonewtab/\
tridactyl_no_new_tab_beta-latest.xpi

  wget -P /tmp/ "${path_tridactyl_xpi}"

  printf "\n"
  echo_substep "Accept Tridactyl installation"
  echo_substep "Quit Firefox"
  sleep 2

  /Applications/Firefox.app/Contents/MacOS/firefox \
    /tmp/tridactyl_no_new_tab_beta-latest.xpi

  local path_native_installer=\
https://raw.githubusercontent.com/tridactyl/tridactyl/master/native/install.sh

  # Install native messanger for tridactyl
  curl \
    -fsSl "${path_native_installer}" \
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

  printf "\n"
  echo_substep "After the following pdf opens, quit Skim"
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
    -bool NO "${HOME}"/Library/Preferences/net.sourceforge.skim-app.skim.plist

  printf '\n' && sleep 1
}

function allow_accessibility() {
  # Allows accessibility permissions to skhd, spacebar and  yabai.

  echo_step "Allowing accessibility permissions to skhd, yabai and spacebar"

  local path_skhd_bin="$(readlink -f /usr/local/bin/skhd)"
  local path_spacebar_bin=$(readlink -f /usr/local/bin/spacebar)
  local path_yabai_bin=$(readlink -f /usr/local/bin/yabai)

  sudo tccutil --insert "${path_skhd_bin}"
  sudo tccutil --insert "${path_spacebar_bin}"
  sudo tccutil --insert "${path_yabai_bin}"

  printf '\n' && sleep 1
}

function brew_start_services() {
  # Tells homebrew to start a few services.

  local services=( \
    redshift \
    skhd \
    spacebar \
    syncthing \
    transmission-cli \
    yabai \
  )

  echo_step "Starting ${services[0]}, ${services[1]} and other \
$((${#services[@]} - 2)) services with Homebrew"

  for service in "${services[@]}"; do
    brew services start "${service}"
  done

  printf '\n' && sleep 1
}

function setup_logi_options() {
  # Opens the Logi Options app to log in and recover the settings for the MX
  # Master 2S mouse.

  echo_step "Opening the Logi Options app"

  printf "\n"
  echo_substep "Log in to recover all the MX Master settings"
  sleep 1

  /Applications/Logi\ Options.app/Contents/MacOS/Logi\ Options &>/dev/null

  printf '\n' && sleep 1
}

function syncthing_sync_from_server() {
  # Opens a new Firefox window with this machine's and my remote server's
  # Syncthing Web GUI pages.

  echo_step "Opening Syncthing Web GUIs"

  local remote_droplet_name=Ocean
  local remote_sync_path=/home/noibe/Sync
  local local_sync_path=/Users/"$(whoami)"/Sync

  printf "\n"
  echo_substep "Add ${remote_droplet_name} to this machine's remote devices"
  echo_substep "Sync ${remote_droplet_name}'s ${remote_sync_path} to \
${local_sync_path}"
  echo_substep "Flag ${local_sync_path} as Send Only"
  echo_substep "Set ${local_sync_path}'s Full Rescan Interval to 60 seconds"
  sleep 2

  /Applications/Firefox.app/Contents/MacOS/firefox \
    --new-tab "http://127.0.0.1:8384/#" \
    --new-tab "https://64.227.35.152:8384/#"

  brew services stop syncthing
  xml ed --inplace \
    -u "/configuration/folder[@path='${local_sync_path}']/markerName" \
    -v "wallpapers" \
    "${HOME}/Library/Application Support/Syncthing/config.xml"
  rm -rf "${local_sync_path}/.stfolder"
  brew services start syncthing

  printf '\n' && sleep 1
}

function setup_sync_symlinks {
  # Sets up symlinks from various directories and files to ~/Sync.

  echo_step "Setting up symlinks to ~/Sync"

  ln -s "${HOME}/Sync/private/ssh" "${HOME}/.ssh"

  rm -rf "${HOME}/.config"
  ln -s "${HOME}/Sync/dotfiles/macOS" "${HOME}/.config"

  ln -s "${HOME}/Sync/code/ndiet/ndiet.py" /usr/local/bin/ndiet
  ln -s "${HOME}/Sync/code/ndiet/diets" "${HOME}/.local/share/ndiet/diets"
  ln -s \
    "${HOME}/Sync/code/ndiet/pantry.txt" \
    "${HOME}/.local/share/ndiet/pantry.txt"

  ln -s \
    "${HOME}/Sync/private/auto-selfcontrol/config.json" \
    /usr/local/etc/auto-selfcontrol/config.json

  printf '\n' && sleep 1
}

function github_add_ssh_key() {
  # Creates a new ssh key for pushing to GitHub without having to input any
  # password. Adds the public key to the clipboard. Opens GitHub's settings
  # page in Firefox to add the newly generated key to the list of accepted
  # keys.

  echo_step "Creating new ssh key for GitHub"

  local github_user_email="riccardo.mazzarini@pm.me"

  printf "\n"
  echo_substep "Leave the default value for the key path \
(/Users/$(whomai)/.ssh/id_rsa)"
  echo_substep "Leave the passphrase empty"

  ssh-keygen -t rsa -C "${github_user_email}"
  cat "${HOME}"/Sync/private/ssh/id_rsa.pub | pbcopy

  printf "\n"
  echo_substep "The public key in id_rsa.pub is in the clipboard"
  echo_substep "Log in to GitHub, choose a name for the new key and paste the
key from the clipboard"

  /Applications/Firefox.app/Contents/MacOS/firefox
    --new-tab "https://github.com/settings/ssh/new" \

  printf "\n"
  echo_substep "Answer \"yes\""
  ssh -T git@github.com

  printf '\n' && sleep 1
}

function transmission_torrent_done_script {
  # Add a torrent-done script to Transmission.

  echo_step "Adding torrent-done notification script to Transmission"

  transmission-remote \
    --torrent-done-script "${HOME}/Sync/code/scripts/transmission/notify-done"

  printf '\n' && sleep 1
}

function set_wallpaper() {
  # Fetches the current $COLORSCHEME from fish/conf.d/exports.fish, then sets
  # the wallpaper to ~/Sync/wallpapers/$COLORSCHEME.png.

  local colorscheme="$(\
    grep 'set\s*-x\s*COLORSCHEME' "$HOME/.config/fish/conf.d/exports.fish" \
    sed 's/set\s*-x\s*COLORSCHEME\s*\(.*\)$/\1/'
  )"

  echo_step "Changing the wallpaper to ${colorscheme}.png"

  osascript -e \
    "tell application \"Finder\" to set desktop picture \
      to POSIX file \"${HOME}/Sync/wallpapers/${colorscheme}.png\"" &>/dev/null

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

function todo_dot_md() {
  # Create a TODO.md file in $(whoami)'s home folder listing the things left to
  # do to get back to full speed

  # Logitech options -> zoom with wheel,
  # Logitech options -> Point & Scroll -> Scroll direction -> Natural,
  # Thumb wheel direction -> Inverted
  # set pointer and scrolling speed
  # Smooth scrolling -> disabled
  # 36. LogiOptions bind buttons to 'KeyStroke Assignment: Cmd + Left' and
  # 'KeyStroke Assignment: Cmd + Right' (or don't, do that only if you need
  # them to work with qutebrowser, otherwise stick with forward and back)'
  # allow accessibility to logitech options (have to select it manually
  # clicking on +)

  cat > $HOME/TODO.md << EOF
# TODO.md

1. do this;
2. do that;
3. attach an external display and rearrange so that the external is the main
   one;
4. login youtube, switch account and enable dark mode and english;
5. log into bitwarden, unlock it, then Settings -> Vault timeout -> Never;
EOF
  printf '\n' && sleep 1
}

function countdown_reboot() {
  # Display a nine second countdown, then reboot.

  for n in {9..0}; do
    echo_reboot "Rebooting in $n"
    [[ ${n} == 0 ]] || sleep 1
  done

  printf '\n\n'
  osascript -e "tell app \"System Events\" to restart"
}

# These functions are part of a generic installation aiming to fully reproduce
# my setup.

exit_if_not_darwin
exit_if_root
exit_if_sip_enabled
greetings_message
command_line_tools
whoami_to_sudoers
set_sys_defaults
get_homebrew_bundle_brewfile
patch_window_edges
unload_Finder
add_remove_from_dock
remove_Finder_from_Dock
setup_dotfiles
chsh_fish
terminfo_alacritty
pip_install_requirements
download_vimplug
setup_firefox
setup_skim
allow_accessibility
brew_start_services

# These functions are specific to my particular setup. Things like configuring
# settings for my Logitech MX Master mouse, adding a new SSH key to my GitHub
# account or synching directories from a remote server.

setup_logi_options
syncthing_sync_from_server
setup_sync_symlinks
github_add_ssh_key
transmission_torrent_done_script
set_wallpaper

# Cleanup leftover files, create a TODO.md file listing the things left to do
# to get back to full speed, reboot the system.

cleanup
todo_dot_md
countdown_reboot
