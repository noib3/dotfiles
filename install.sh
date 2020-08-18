#!/usr/bin/env sh

# ---------------------------------------------------------------------------
# nO0bs - Noibe's macOs day-0 Bootstrapping Scripts

# ---------------------------------------------------------------------------

# MOVED FROM .zshrc TO HERE -----------------------------
# -------------------------------------------------------
# Find a way to make entr run in the background, then
#   echo /Users/noibe/.config/yabai/yabairc | entr /bin/sh /Users/noibe/.config/yabai/yabairc
#   echo /Users/noibe/.config/tmux/tmux.conf | entr /usr/local/bin/tmux source /Users/noibe/.config/tmux/tmux.conf
# Set wallpaper from command line
#   osascript -e 'tell application "Finder" to set desktop picture to POSIX file "<absolute_path_to_file>"'
#   osascript -e 'quit app "Finder"'
# Or, to use it inside a shell function,
#   osascript -e "tell application \"Finder\" to set desktop picture to POSIX file \"$1\""

# Disable the "Are you sure you want to open this application?" dialog
#   defaults write com.apple.LaunchServices LSQuarantine -bool false

# List all songs and pipe them into tmd
#   find ~/Music -iname "*\.mp3" -print0 | xargs -0 tmd

# Change TeX home tree
#   sudo tlmgr conf texmf TEXMFHOME "~/TeX/texmf"

# Empty Dock
#   defaults write com.apple.dock recent-apps -array
#   defaults write com.apple.dock persistent-apps -array

# Hide Dock
#   defaults write com.apple.dock autohide-delay -float 1000

# Keep programs out of dock
#   System Preferences -> Dock -> Show recent applications in Dock [uncheck]

# If Dock gets stuck and won't launch anymore
#   launchctl unload -F /System/Library/LaunchAgents/com.apple.Dock.plist
#   launchctl   load -F /System/Library/LaunchAgents/com.apple.Dock.plist
#   launchctl start com.apple.Dock.agent
#   launchctl unload -F /System/Library/LaunchAgents/com.apple.Dock.plist
#   /System/Library/CoreServices/Dock.app/Contents/MacOS/Dock
#   rm -rf ~/Library/Application Support/Dock
#   rm -rf ~/Library/Preferences/com.apple.dock.plist
#   sudo reboot

# Write to /System
#   sudo mount -uw /
#   killall Finder

# defaults write -g InitialKeyRepeat -int 10 # normal minimum is 15 (225 ms)
# defaults write -g KeyRepeat -int 1 # normal minimum is 2 (30 ms)A
# -------------------------------------------------------
# -------------------------------------------------------


# ---------------------------------------------------------------------------
# System Preferences -> Mission Control -> Uncheck "Automatically rearrange spaces based of most recent use"
# System Preferences -> Keyboard -> Key Repeat all the way to the right
# System Preferences -> Keyboard -> Delay Until Repeat all the way to the right

# Quit the finder
defaults write com.apple.finder QuitMenuItem -bool false && killall Finder

# Remove 'Other' from login screen
sudo defaults write /Library/Preferences/com.apple.loginwindow SHOWOTHERUSERS_MANAGED -bool FALSE

# Disable Gatekeeper and open every program without being asked for confirmation
sudo spctl --master-disable
# System Preferences -> Security & Privacy -> Allow apps downloaded from -> Check "Anywhere"

# Install homebrew
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

# push to github without password
ssh-keygen -t rsa -C "riccardo.mazzarini98@gmail.com"
# copy the content of ~/.ssh/id_rsa.pub, go to github -> settings -> ssh and gpg keys -> new ssh key -> paste
# answer 'yes' to
ssh -T git@github.com
# go to the repository on github, close or download -> use ssh url, copy that url and paste it in <git_repo>/.git/config under [remote "origin"]


# silence startup sound (it's one of these ones, they should be system-dependent)
#sudo nvram SystemAudioVolume=%80
sudo nvram SystemAudioVolume=%01 # this is the first one that worked on my macbook (haven't tried the next 2)
#sudo nvram SystemAudioVolume=%00
#sudo nvram SystemAudioVolume=" "


# KEEP FINDER FROM OPENING WHEN NO OTHER APPS ARE OPENED
launchctl unload /System/Library/LaunchAgents/com.apple.Finder.plist

# FINDER OUT OF DOCK AND CMD-TAB MENU (https://apple.stackexchange.com/questions/30415/how-can-i-remove-the-finder-icon-from-my-dock?newreg=7853552a016a48d2a67c03406a1b7af9)
sudo nvim /System/Library/CoreServices/Dock.app/Contents/Resources/DockMenus.plist
# find the sections 'finder-quit', 'finder-running' and 'trash', and add a new subsection to them:
<dict>
    <key>command</key>
    <integer>1004</integer>
    <key>name</key>
    <string>REMOVE_FROM_DOCK</string>
</dict>
# open the Finder, then
killall Dock
# right click on the finder icon in the Dock and remove it


# STOP CREATION OF .DS_Store FILES
# download the latest .zip release from 'https://github.com/xiaozhuai/odourless/releases'
# move it to /Applications
# in case it doesn't launch (in my case it said something like 'this has to be under /Applications', even if it was under /Applications), just run it from the command line:
# /Applications/Odourless.app/Contents/MacOS/odourless
# install the daemon on the lil gui that pops up
# reboot and you should be gucci


# Change TeX directory
sudo tlmgr conf texmf TEXMFHOME "~/Library/texmf"
