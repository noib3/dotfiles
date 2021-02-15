{ config, pkgs, ... }:

{

  # Use a custom configuration.nix location.
  # $ darwin-rebuild switch -I darwin-config=$HOME/.config/nixpkgs/darwin/configuration.nix
  environment.darwinConfig = "$HOME/.config/nixpkgs/darwin/configuration.nix";

  # Auto upgrade nix package and the daemon service.
  # services.nix-daemon.enable = true;
  # nix.package = pkgs.nix;

  # Create /etc/bashrc that loads the nix-darwin environment.
  # programs.zsh.enable = true;  # default shell on catalina
  # programs.fish.enable = true;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;

  users.users.noibe = {
    home = "/Users/noibe";
    description = "Riccardo Mazzarini";
  };

  system.defaults.NSGlobalDomain = {
    # Autohide the menu bar.
    _HIHideMenuBar = true;

    # Set really short keyboard key repeat delays.
    InitialKeyRepeat = 10;
    KeyRepeat = 1;

    # Show scroll bars only when scrolling.
    AppleShowScrollBars = "WhenScrolling";
  };

  system.defaults.dock = {
    # Autohide the dock and set a really long show-on-hover delay.
    autohide = true;
    # autohide-delay = 1000;

    # Set the dock size.
    tilesize = 50;

    # Empty the dock.
    # persistent-apps = [];
    # persistent-others = [];
    # recent-others = [];
    show-recents = false;

    # Don't rearrange spaces based on most recent use.
    mru-spaces = false;
  };

  system.defaults.finder = {
    # Enable quitting the Finder.
    QuitMenuItem = true;

    # Show all files and extensions.
    # AppleShowAllFiles = true;

    # Don't show warnings before changing an extension.
    FXEnableExtensionChangeWarning = false;

    # Group and sort files by name.
    # FXPreferredGroupBy = "Name";

    # Make $HOME the default directory when opening a new window.
    # NewWindowTarget = "PfLo";
    # NewWindowTargetPath = "file://$HOME/";
  };
}
