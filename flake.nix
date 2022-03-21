{
  description = "noib3's dotfiles";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    neovim-nightly-overlay.url =
      "github:nix-community/neovim-nightly-overlay/master";
    tdtd.url = "path:/home/noib3/Dropbox/projects/tdtd";
  };

  outputs = { self, ... }@inputs: with inputs;
    let
      username = "noib3";
      colorscheme = "tokyonight";
      font-family = "Mononoki Nerd Font";

      hexlib = import ./palettes/hexlib.nix { inherit (nixpkgs) lib; };
      palette = import (./palettes + "/${colorscheme}.nix");
      configDir = ./configs;

      getHomeDirectory = system: with nixpkgs.legacyPackages.${system}.stdenv;
        if isDarwin then
          "/Users/${username}"
        else if isLinux then
          "/home/${username}"
        else "";

      mkSystemConfiguration = args: nixpkgs.lib.nixosSystem {
        inherit (args) system;
        specialArgs = {
          homeDirectory = getHomeDirectory args.system;
          inherit (args) machine;
          inherit
            username
            colorscheme
            palette
            configDir
            hexlib
            ;
        };
        modules = [
          ./configuration.nix
        ];
      };

      mkHomeConfiguration = args: home-manager.lib.homeManagerConfiguration {
        inherit username;
        inherit (args) system;
        homeDirectory = getHomeDirectory args.system;
        stateVersion = "22.05";
        pkgs = import nixpkgs {
          inherit (args) system;
          overlays = [
            neovim-nightly-overlay.overlay
            tdtd.overlay
          ];
        };
        extraModules = [
          ./modules/programs/skhd.nix
          ./modules/programs/spacebar.nix
          ./modules/programs/vivid.nix
          ./modules/programs/yabai.nix
        ];
        extraSpecialArgs = {
          cloudDir = "${getHomeDirectory args.system}/Dropbox";
          inherit (args) machine;
          inherit
            colorscheme
            font-family
            palette
            configDir
            hexlib
            ;
        };
        configuration = import ./home.nix;
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
