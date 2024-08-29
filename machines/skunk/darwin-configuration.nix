{
  config,
  lib,
  pkgs,
  colorscheme,
  hostName,
  ...
}:

let
  configDir = ../../configs;

  configs = import "${configDir}" {
    inherit
      config
      lib
      pkgs
      colorscheme
      ;
    hexlib = import ../../lib/hex.nix { inherit lib; };
    palette = import (../../palettes + "/${colorscheme}.nix");
  };
in
{
  environment = {
    loginShell = "${pkgs.fish}/bin/fish";
    shells = [ pkgs.fish ];
  };

  networking = {
    computerName = hostName;
    hostName = hostName;
    localHostName = hostName;
  };

  # This is needed to have /run/current-system/sw/bin in PATH, which is where
  # `darwin-rebuild` and other nix-darwin-related commands live.
  programs.fish.enable = true;

  services = {
    nix-daemon.enable = true;
    inherit (configs) skhd yabai;
  };

  system = {
    defaults = {
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
    };

    keyboard = {
      enableKeyMapping = true;
      remapCapsLockToEscape = true;
    };
  };
}
