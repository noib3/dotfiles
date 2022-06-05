{ pkgs
, lib
, machine
, colorscheme
, font-family
, palette
, configDir
, cloudDir
, hexlib
, ...
}:

{
  homebrew = {
    enable = true;
    cleanup = "zap";
    brews = [
      "mas"
    ];
    casks = [
      "alacritty"
      "nordvpn"
      "signal"
      "zoom"
    ];
  };

  networking = {
    computerName = machine;
    hostName = machine;
    localHostName = machine;
  };

  services.nix-daemon.enable = true;

  system.defaults = {
    dock = {
      autohide = true;
      mru-spaces = false;
      show-recents = false;
    };

    finder = {
      AppleShowAllExtensions = true;
      AppleShowAllFiles = true;
      QuitMenuItem = true;
    };

    trackpad.Clicking = true;

    LaunchServices.LSQuarantine = false;

    NSGlobalDomain = {
      AppleShowAllFiles = true;
      InitialKeyRepeat = 10;
      KeyRepeat = 2;
    };

    SoftwareUpdate.AutomaticallyInstallMacOSUpdates = true;
  };

  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToEscape = true;
  };
}
