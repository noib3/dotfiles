#!/usr/bin/env sh

# TODO Remove everything from notifications 'Today' page
# TODO System Preferences -> Desktop & Screen Saver -> Screen Saver -> Start after: Never

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
  '/System/Library/CoreServices/Menu Extras/Clock.menu' \
  '/System/Library/CoreServices/Menu Extras/Battery.menu' \
  '/System/Library/CoreServices/Menu Extras/AirPort.menu' \
  '/System/Library/CoreServices/Menu Extras/Bluetooth.menu' \
  '/System/Library/CoreServices/Menu Extras/User.menu'
defaults write com.apple.systemuiserver \
  "NSStatusItem Preferred Position Item-0" -float 23
defaults write com.apple.systemuiserver \
  "NSStatusItem Preferred Position com.apple.menuextra.airport" -float 303
defaults write com.apple.systemuiserver \
  "NSStatusItem Preferred Position com.apple.menuextra.battery" -float 252
defaults write com.apple.systemuiserver \
  "NSStatusItem Preferred Position com.apple.menuextra.bluetooth" -float 333
defaults write com.apple.systemuiserver \
  "NSStatusItem Preferred Position com.apple.menuextra.clock" -float 149

# Autohide Dock and set a really long show-on-hover delay
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock autohide-delay -int 1000

# Empty Dock
defaults write com.apple.dock persistent-apps -array ''
defaults write com.apple.dock persistent-others -array ''
defaults write com.apple.dock recent-others -array ''

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
defaults write NSGlobalDomain AppleShowScrollBars -string WhenScrolling

# Finder
defaults write com.apple.finder QuitMenuItem -bool true
defaults write com.apple.Finder AppleShowAllFiles -bool true

# TODO Finder
#     Preferences -> Uncheck 'External disks' and 'CDs, DVDs and iPods'
#     Preferences -> New Finder windows show home
#     Delete all Tags
#     Remove Documents Desktop Recents Airdrop from Sidebar
#     Add ~ and .config to sidebar
#     Order sidebar folders with Applications on top
#     tags can be deleted from preferences -> tags
#     stuff can be removed from sidebar via preferences -> sidebar
#     preferences -> advanced to show filename extensions, dont show warnings
#     show view options -> group by name sort by name -> use as defaults
# TODO remove spotlight from the menu bar
#     https://www.idownloadblog.com/2017/02/02/disable-spotlight-remove-menu-bar/
#     basically
#     cd /System/Library/CoreServices/Spotlight.app/Contents/MacOS
#     sudo mount -uw /
#     sudo cp Spotlight Spotlight-backup
#     sudo perl -pi -e 's|(\x00\x00\x00\x00\x00\x00\x47\x40\x00\x00\x00\x00\x00\x00)\x42\x40(\x00\x00\x80\x3f\x00\x00\x70\x42)|$1\x00\x00$2|sg' Spotlight
#     sudo codesign -f -s - Spotlight
#     sudo killall Spotlight
# input password if asked. If it worked 'sudo rm Spotlight-backup'
# TODO remove finder and trash from dock
#       sudo mount -uw /
#       killall Finder (maybe not necessary)
#       sudo nvim /System/Library/CoreServices/Dock.app/Contents/Resources/DockMenus.plist
#       find the sections 'finder-quit', 'finder-running', 'trash' and add a new entry
#       <dict>
#           <key>command</key>
#           <integer>1004</integer>
#           <key>name</key>
#           <string>REMOVE_FROM_DOCK</string>
#       </dict>

# Set time zone
sudo systemsetup -settimezone "Europe/Rome" >/dev/null

# Never let computer or display go to sleep
sudo pmset -a sleep 0
sudo pmset -a displaysleep 0

# Never dim the display while on battery power
sudo pmset -a halfdim 0

# Remove public folder from home folder
sudo rm -rf Public

# Rename host
sudo scutil --set ComputerName "MBAir" LocalHostname "MBAir" HostName "MBAir"
