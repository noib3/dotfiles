{
  description = "noib3's dotfiles";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
    peek.url = "path:/home/noib3/Dropbox/projects/peek";
    tdtd.url = "path:/home/noib3/Dropbox/projects/tdtd";
  };

  outputs = { self, ... }@inputs: with inputs;
    let
      username = "noib3";
      # TODO: what system to use here? I just want to access pkgs.stdenv :(
      homeDirectory = with nixpkgs.legacyPackages.x86_64-linux.stdenv;
        if isDarwin then
          "/Users/${username}"
        else if isLinux then
          "/home/${username}"
        else "";

      configDir = ./configs;
      cloudDir = "${homeDirectory}/Dropbox";

      colorscheme = "tokyonight";
      font-family = "Iosevka Nerd Font";

      palette = import (./palettes + "/${colorscheme}.nix");
      hexlib = import ./palettes/hexlib.nix { inherit (nixpkgs) lib; };

      mkSystemConfiguration = args: nixpkgs.lib.nixosSystem {
        inherit (args) system;
        specialArgs = {
          inherit (args) machine;
          inherit
            username
            homeDirectory
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
        inherit username homeDirectory;
        inherit (args) system;
        stateVersion = "22.05";
        pkgs = import nixpkgs {
          inherit (args) system;
          overlays = [
            neovim-nightly-overlay.overlay
            tdtd.overlay
            peek.overlay
          ];
        };
        extraModules = [
          ./modules/programs/skhd.nix
          ./modules/programs/spacebar.nix
          ./modules/programs/vivid.nix
          ./modules/programs/yabai.nix
        ];
        extraSpecialArgs = {
          inherit (args) machine;
          inherit
            colorscheme
            font-family
            palette
            configDir
            cloudDir
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
