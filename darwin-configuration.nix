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
    taps = [
      "koekeishiya/formulae"
    ];
    brews = [
      "mas"
      "yabai"
      "skhd"
    ];
  };

  # networking = {
  #   computerName = machine;
  #   hostName = machine;
  #   localHostName = machine;
  # };

  services.nix-daemon.enable = true;

  services.skhd = {
    enable = false;
    package = pkgs.skhd;
    skhdConfig = "cmd - return : alacritty";
  };

  # services.yabai = {
  #   enable = false;
  # } // (import "${configDir}/yabai" {
  #   inherit pkgs colorscheme palette hexlib;
  #   inherit (lib.strings) removePrefix;
  # });

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
      # Enable trackpad's tap to click
      # com.apple.mouse.tapBehaviour = 1;
    };

    SoftwareUpdate.AutomaticallyInstallMacOSUpdates = true;
  };

  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToEscape = true;
  };
}
