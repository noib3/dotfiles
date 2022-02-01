{
  description = "noib3's dotfiles";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
    tdtd.url = "path:/home/noib3/Dropbox/projects/tdtd";
  };

  outputs = { self, ... }@inputs: with inputs;
    let
      username = "noib3";
      homeDirectory = with nixpkgs.legacyPackages.x86_64-linux.stdenv;
        if isLinux then
          "/home/${username}"
        else if isDarwin then
          "/Users/${username}"
        else "";

      configDir = ./configs;
      cloudDir = "${homeDirectory}/Dropbox";

      colorscheme = "tokyonight";
      font-family = "Iosevka Nerd Font";

      palette = import (./palettes + "/${colorscheme}.nix");
      hexlib = import ./palettes/hexlib.nix { inherit (nixpkgs) lib; };

      overlays = [
        neovim-nightly-overlay.overlay
        tdtd.overlay
      ];

      modules = [
        ./modules/programs/skhd.nix
        ./modules/programs/spacebar.nix
        ./modules/programs/vivid.nix
        ./modules/programs/yabai.nix
      ];

      mkSystemConfiguration = args: nixpkgs.lib.nixosSystem {
        inherit (args) system;
        modules = [
          # TODO: make this relative import work.
          # (import ./configuration.nix {
          (import "${cloudDir}/dotfiles/configuration.nix" {
            inherit (args) machine;
            inherit
              username
              homeDirectory
              colorscheme
              palette
              configDir
              hexlib
              ;
          })
        ];
      };

      mkHomeConfiguration = args: home-manager.lib.homeManagerConfiguration {
        inherit username homeDirectory;
        inherit (args) system;
        stateVersion = "22.05";
        configuration = import ./home.nix {
          inherit (args) machine;
          inherit
            colorscheme
            font-family
            palette
            configDir
            cloudDir
            hexlib
            overlays
            modules
            ;
        };
      };
    in
    {
      nixosConfigurations.blade = mkSystemConfiguration {
        system = "x86_64-linux";
        machine = "blade";
      };

      homeConfigurations."${username}@blade" = mkHomeConfiguration {
        system = "x86_64-linux";
        machine = "blade";
      };

      homeConfigurations."${username}@mbair" = mkHomeConfiguration {
        system = "x86_64-darwin";
        machine = "mbair";
      };
    };
}
