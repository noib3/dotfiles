#!/bin/sh

# ---------------------------------------------------------------------------
# nO0bs - Noibe's macOs day-0 Bootstrapping Scripts


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
