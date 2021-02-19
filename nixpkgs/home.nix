{ config, pkgs, ... }:

let
  unstable = import <nixpkgs-unstable> { config = { allowUnfree = true; }; };

in {
  home = {
    username = "noibe";
    homeDirectory = "/Users/noibe";
    stateVersion = "21.03";

    packages = with pkgs; [
      # alacritty
      # auto-selfcontrol
      # bash
      bat
      # buku
      # calcurse
      # chafa
      # coreutils
      direnv
      # duti
      # entr
      # fd
      # ffmpeg
      # findutils
      # # firefox
      # fish
      # fzf
      # git
      # gnu-sed
      # gotop
      # jq
      # lazygit
      # lf
      # mas
      # mediainfo
      neofetch
      # neovim
      # nodejs
      # openssh
      pfetch
      # (python39.withPackages(
      #   ps: with ps; [
      #     autopep8
      #     black
      #     docopt
      #     flake8
      #     ipython
      #     jedi
      #     numpy
      #   ]
      # ))
      # redshift
      # rsync
      # skhd
      # spacebar
      # ookla-speedtest
      # sshfs
      # starship
      # syncthing
      # tccutil
      # terminal-notifier
      # transmission
      # vivid
      # wget
      # xmlstarlet
      # yabai
    ];
  };

  nixpkgs = {
    # config = {
    #   allowUnsupportedSystem = true;
    # };

    overlays = [(
     self: super: {
        direnv = unstable.direnv;
        # fzf = unstable.fzf;
        # lf  = unstable.lf;
        # neovim = unstable.neovim;
        # python39 = unstable.python39;
        # starship = unstable.starship;
      }
    )];
  };

  programs.home-manager.enable = true;

  # programs.git = {
  #   enable = true;
  #   userName = "noib3";
  #   userEmail = "riccardo.mazzarini@pm.me";
  # };
}
