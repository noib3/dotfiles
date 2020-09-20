#!/usr/bin/env bash

# TODO this is just a first outline of the script. All the functions have yet
# to be implemented

set -o errexit
set -o errtrace
set -p pipefail

trap 'exit' EXIT ERR SIGINT

readonly COMPUTER_NAME="MBAir"

readonly TIMEZONE="Europe/Rome"

readonly BREW_TAPS=(
  caskroom/cask
  cask-drivers
  koekeishiya/formulae
)

readonly BREW_FORMULAE=(
  bash
  bitwarden-cli
  calcurse
  chafa
  coreutils
  entr
  fd
  findutils
  fzf
  git
  gnu-sed
  gotop
  highlight
  ipython
  lf
  media-info
  neovim
  openssh
  pandoc
  python@3.8
  r
  redshift
  skhd
  terminal-notifier
  transmission-cli
  yabai
  zsh
  zsh-autosuggestions
)

readonly BREW_CASKS=(
  alacritty
  dropbox
  firefox
  font-iosevka-nerd-font
  font-jetbrains-mono-nerd-font
  font-sf-mono-nerd-font
  logitech-options
  mactex-no-gui
  mpv
  nordvpn
  pdftotext
  qview
  skim
  whatsapp
  xquartz
)

_command_line_tools() {
  # DESC: Install XCode command line tools if not already installed
  # ARGS: None
  # OUTS: None
  # NOTE: None

  if ! xcode-select --print-path >/dev/null; then
    xcode-select --install >/dev/null
  fi
}
_command_line_tools

_add_to_sudoers() {
  # DESC: Adds a user to the sudoers file
  # ARGS: $1 (required) - Name of the user to be added to the sudoers file
  # OUTS: None
  # NOTE: None

  # TODO Add after '%admin ...' entry

  local user="$1"

  # sudo echo 'noibe		ALL = (ALL) NOPASSWD: ALL' >> /private/etc/sudoers
}
_add_to_sudoers "$(id -un)"

_set_sys_defaults() {
  # DESC: Sets all the system defaults
  # ARGS: None
  # OUTS: None
  # NOTE: None

  # TODO Remove everything from notifications 'Today' page
  # TODO System Preferences -> Desktop & Screen Saver -> Screen Saver -> Start after: Never
  # TODO Finder sidebar shows: Applications, noibe (~), .config, Dropbox, Downloads, Bin, bin
  # TODO Finder -> Preferences -> Sidebar -> Check Applications, Downloads, Hard disks, External disks

  # Enable trackpad's tap to click
  defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true

  # Show battery percentage in menu bar
  defaults write com.apple.menuextra.battery ShowPercent -bool true

  # Disable 'Are you sure you want to open this application?' dialog
  defaults write com.apple.LaunchServices LSQuarantine -bool false

  # Remove input sources in menu bar
  defaults write com.apple.TextInputMenu visible -bool false

  # Organize menu bar
  defaults write com.apple.systemuiserver menuExtras -array \
    '/System/Library/CoreServices/Menu Extras/AirPort.menu' \
    '/System/Library/CoreServices/Menu Extras/Bluetooth.menu' \
    '/System/Library/CoreServices/Menu Extras/Clock.menu' \
    '/System/Library/CoreServices/Menu Extras/User.menu' \
    '/System/Library/CoreServices/Menu Extras/Battery.menu' \
  defaults write com.apple.systemuiserver \
    "NSStatusItem Preferred Position Item-0" -float 23
  defaults write com.apple.systemuiserver \
    "NSStatusItem Preferred Position com.apple.menuextra.airport" -float 315
  defaults write com.apple.systemuiserver \
    "NSStatusItem Preferred Position com.apple.menuextra.appleuser" -float 68.5
  defaults write com.apple.systemuiserver \
    "NSStatusItem Preferred Position com.apple.menuextra.battery" -float 264
  defaults write com.apple.systemuiserver \
    "NSStatusItem Preferred Position com.apple.menuextra.bluetooth" -float 345
  defaults write com.apple.systemuiserver \
    "NSStatusItem Preferred Position com.apple.menuextra.clock" -float 159.5

  # Autohide Dock and set a really long show-on-hover delay
  defaults write com.apple.dock autohide -bool true
  defaults write com.apple.dock autohide-delay -int 1000

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

  # Disable UI sound effects
  defaults write NSGlobalDomain com.apple.sound.uiaudio.enabled -bool false

  # Show day of the week in menu bar
  defaults write com.apple.menuextra.clock DateFormat -string 'EEE d MMM  HH:mm'

  # Show scroll bars when scrolling
  defaults write NSGlobalDomain AppleShowScrollBars -string 'WhenScrolling'

  # Enable quitting the Finder
  defaults write com.apple.finder QuitMenuItem -bool true

  # Show all files
  defaults write com.apple.finder AppleShowAllFiles -bool true

  # New Finder windows open in ~/Downloads
  defaults write com.apple.finder NewWindowTarget -string 'PfLo'
  defaults write com.apple.finder NewWindowTargetPath -string 'file:///Users/noibe/Downloads/'

  # Don't show warning before changing an extension
  defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

  # Show all extensions
  defaults write NSGlobalDomain AppleShowAllExtensions -bool true

  # Group and sort files by name
  defaults write com.apple.finder FXPreferredGroupBy -string 'Name'

  # Set time zone
  sudo systemsetup -settimezone "$TIMEZONE" >/dev/null

  # Disable startup chime
  # https://www.howtogeek.com/260693/how-to-disable-the-boot-sound-or-startup-chime-on-a-mac/
  sudo nvram SystemAudioVolume=" "

  # Never let computer or display go to sleep
  sudo pmset -a sleep 0
  sudo pmset -a displaysleep 0

  # Never dim the display while on battery power
  sudo pmset -a halfdim 0

  # Rename host
  sudo scutil --set ComputerName "$COMPUTER_NAME"
  sudo scutil --set HostName "$COMPUTER_NAME"
  sudo scutil --set LocalHostName "$COMPUTER_NAME"
  sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string "${COMPUTER_NAME}"

  # Remove 'Other' from login screen
  sudo defaults write /Library/Preferences/com.apple.loginwindow SHOWOTHERUSERS_MANAGED -bool false
}
_set_sys_defaults

_remove_spotlight_from_menu_bar() {
  # DESC: Removes the Spotlight icon from the menu bar
  # ARGS: None
  # OUTS: None
  # NOTE: https://www.idownloadblog.com/2017/02/02/disable-spotlight-remove-menu-bar/

  sudo mount -uw /
  sudo perl -pi -e 's|(\x00\x00\x00\x00\x00\x00\x47\x40\x00\x00\x00\x00\x00\x00)\x42\x40(\x00\x00\x80\x3f\x00\x00\x70\x42)|$1\x00\x00$2|sg' /System/Library/CoreServices/Spotlight.app/Contents/MacOS/Spotlight
  sudo codesign -f -s - /System/Library/CoreServices/Spotlight.app/Contents/MacOS/Spotlight
  sudo killall /System/Library/CoreServices/Spotlight.app/Contents/MacOS/Spotlight
}
_remove_from_menu_bar_spotlight

_add_remove_from_dock() {
  # DESC: Adds 'Remove from Dock' option to Finder and Trash Dock icons
  # ARGS: None
  # OUTS: None
  # NOTE: None

  # TODO 'finder-quit', 'finder-running', 'trash'
  sudo mount -uw /
  read -r -d '' remove_from_dock_dict << EOM
		<dict>
			<key>command</key>
			<integer>1004</integer>
			<key>name</key>
			<string>REMOVE_FROM_DOCK</string>
		</dict>
EOM

  # sudo sed -i 's/(<key>finder_quit</key>\n<array>\n)/\1$remove_from_dock_dict/' /System/Library/CoreServices/Dock.app/Contents/Resources/DockMenus.plist
}
_add_remove_from_dock

_patch_square_edges() {
  # DESC: Patches .car files with square edges for all macOS GUI programs
  # ARGS: None
  # OUTS: None
  # NOTE: https://github.com/tsujp/custom-macos-gui

  sudo mount -uw /
  # 40. SQUARE BORDERS

  # Place DarkAquaAppearance.car file found here (https://github.com/tsujp/custom-macos-gui/tree/master/DarkAquaAppearance/Edited) in /System/Library/CoreServices/SystemAppearance.bundle/Contents/Resources/DarkAquaAppearance.car. Will have to unmount the filesystem first with

  # then move the file there replacing the one that's already there, then reboot. (https://www.reddit.com/r/unixporn/comments/i7s3t1/yabaiwm_monokai_machintosh/g16gnck?utm_source=share&utm_medium=web2x)'
}
_patch_square_edges

_homebrew() {
  # DESC: Installs homebrew if not already installed, then it installs all the
  #       programs in BREW_FORMULAE and BREW_CASKS
  # ARGS: None
  # OUTS: None
  # NOTE: None

  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"

  for tap in "${BREW_TAPS[@]}"; do
    brew tap $tap
  done

  for formula in "${BREW_FORMULAE[@]}"; do
    brew install $formula
  done

  for cask in "${BREW_CASKS[@]}"; do
    brew cask install $cask
  done
}
_homebrew

_setup_git() {
  # TODO create ssh key for github
  #      ssh-keygen -t rsa -C "riccardo.mazzarini98@gmail.com"
  # TODO copy the content of ~/.ssh/id_rsa.pub, go to github -> settings -> ssh
  #      and gpg keys -> new ssh key -> paste
  # TODO answer 'yes' to
  #      ssh -T git@github.com
  # TODO go to the repository on github, close or download -> use ssh url, copy
  #      that url and paste it in <git_repo>/.git/config under [remote "origin"]
  # TODO Use /usr/local/etc/gitconfig for git config file instead of
  #      ~/.config/gitconfig. To use that you need to use the --system flag, so
  #      for ex 'git config --system user.name n0ibe' etc. To list all configs
  #      and the file where they are defined use 'git config --list --show-origin'
  # TODO for every git folder downloaded, edit the remote origin url in the git
  #      config file to be of the form git@github.com:n0ibe/<repo_name>.git
}
_setup_git

_setup_zsh() {
  # 4. Change shell to zsh
  #       sudo sh -c 'echo /usr/local/bin/zsh >> /etc/shells'
  #       chsh -s /usr/local/bin/zsh
  # 8. Compaudit
  #       compaudit
  #       sudo chmod -R 755 the top directory of each compaudit (in my case it returned the directoryies /usr/local/share/zsh and /usr/local/share/zsh/site-functions, so sudo chmod -R 755 /usr/local/share/zsh was enough)
  # 17. make zsh history dir
  #       mkdir ~/.cache/zsh
  # # git clone https://github.com/Aloxaf/fz-tab /usr/local/share/fz-tab
  # # git clone https://github.com/zdharma/fast-syntax-highlighting /usr/local/share/fast-syntax-highlighting
  # # git clone https://github.com/kutsan/zsh-system-clipboard /usr/local/share/zsh-system-clipboard
  # # git clone https://github.com/hlissner/zsh-autopair /usr/local/share/zsh-autopair
  # 32. sudo touch /etc/zshenv && echo "export ZDOTDIR=~/.config/zsh" | sudo tee /etc/zshenv >/dev/null
  # 33. mkdir ~/.cache/python
  # 34. mkdir ~/.cache/less
}
_setup_zsh

_setup_neovim() {
  # 5. Install vim-plug
  #       curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  # 38. 'pip3 install neovim' for UltiSnips

  # 39. install vimtex for coc via
  #     :CocInstall coc-vimtex
  # 40. pip3 install jedi if coc-python gives problems
}
_setup_neovim

_setup_firefox() {
  # 1. Open firefox without being prompted for dialog
  #       sudo xattr -r -d com.apple.quarantine /Applications/Firefox.app
  # 2. Download bitwarden firefox extension
  # 3. Sign in to gmail to get bitwarden master password
  # 9. Login firefox
  # 10. firefox about:config options
  # 11. load firefox config
  #     cd ~/Library/Application\ Support/Firefox/Profiles/*-release/
  #     mkdir chrome && cd chrome
  #     ln -s ~/.config/firefox/userChrome.css
  #     ln ~/.config/firefox/userContent.css
  # 29. login youtube, switch account and enable dark mode and english
  # 22. load vimium c config file
}
_setup_firefox

_setup_skim() {
  # 25. install skim
  #       preferences -> Sync -> Check 'check for file changes' and 'reload automatically'
  # 26. use skim as default pdf viewer
  #       right click on a pdf file -> get info -> open with: skim.app -> change all
  # 27. debloat skim
  #       skim -> view -> hide contents pane and notes pane, toogle toolbar
  #       skim -> preferences -> general -> remember lat page viewed
}
_setup_skim

_setup_logi_options() {
  # 31. Logitech options -> zoom with wheel,
  #     Logitech options -> Point & Scroll -> Scroll direction -> Natural, Thumb wheel direction -> Inverted
  #     set pointer and scrolling speed
  #     Smooth scrolling -> disabled
  # 36. LogiOptions bind buttons to 'KeyStroke Assignment: Cmd + Left' and 'KeyStroke Assignment: Cmd + Right' (or don't, do that only if you need them to work with qutebrowser, otherwise stick with forward and back)'
}
_setup_logi_options

_setup_dropbox() {
  # 1. log into dropbox account
}
_setup_dropbox

_setup_configs() {
  # 28. tell transmission to run script when torrent is done
  #       transmission-remote --torrent-done-script ~/scripts/transmission/notify-done.sh
}
_setup_configs

_setup_scripts() {
  # 12. download scripts folder
  #      git clone https://github.com/n0ibe/scripts
  # 15. link at login files
  #       cd /Library/LaunchDaemons
  #       sudo ln -s ~/scripts/@login/Odourless/odourless-daemon.plist
  #       launchctl load /Library/LaunchDaemons/odourless-daemon.plist
  #       reboot and test if it works
  # 18. link login files
  #     cd ~/Library/LaunchAgents
  #     ln -s ~/scripts/@login/....plist
  #     launchctl load ./*.plist
}
_setup_scripts

_setup_calcurse() {
  # 14. download calcurse
  #       git clone https://github.com/n0ibe/calcurse
  #       mv calcurse ~/.local/share/
}
_setup_calcurse

_setup_texmf() {
  # 19. install texlive
  #       git clone https://github.com/n0ibe/texmf
  #       mv texmf ~/Library/texmf
  #       sudo ln -s ~/Library/tex/context /usr/local/texlive/texmf-local/tex/
}
_setup_texmf

_setup_ndiet() {
  # 20. install ndiet
  #       mkdir ~/bin && cd ~/bin
  #       git clone https://github.com/n0ibe/ndiet
  #       pip3 install pyfiglet
  #       pip3 install docopt
  #       pip3 install gkeepapi
}
_setup_ndiet

_setup_odourless(){
  # STOP CREATION OF .DS_Store FILES
  # download the latest .zip release from 'https://github.com/xiaozhuai/odourless/releases'
  # move it to /Applications
  # in case it doesn't launch (in my case it said something like 'this has to be under /Applications', even if it was under /Applications), just run it from the command line:
  # /Applications/Odourless.app/Contents/MacOS/odourless
  # install the daemon on the lil gui that pops up
  # reboot and you should be gucci
}
_setup_odourless

_allow_accessibility(){
  # 6. Allow skhd and yabai accessibility permission
  # 7. Allow dropbox accessibility permissions
  # 24. allow accessibility to logitech options (have to select it manually clicking on +)
  # 30. Allow terminal-notifier notifications
}
_allow_accessibility

_set_wallpaper() {

}
_set_wallpaper

_cleanup() {
  # DESC: Cleans up all the cache/history files
  # ARGS: None
  # OUTS: None
  # NOTE: None

  # Remove public folder from home folder
  # rm -rf Public
  # rm ~/.config/zsh/.zsh-history ~/.CFUserTextEncoding ~/.viminfo ~/.zsh-history
}
_cleanup

_create_todo_file() {
  # DESC: Creates a TODO.txt file in the home directory with all the steps left
  #       to have a finished working environment
  # ARGS: None
  # OUTS: None
  # NOTE: None

  cat >$HOME/TODO.txt << EOL
1. Do this
2. Do that
3. Attach an external display and rearrange so that the external is the main one
EOL
}
_create_todo_file

_reboot() {
  osascript -e "tell app \"System Events\" to restart"
}
_reboot
