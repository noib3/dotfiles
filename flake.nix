{
  description = "noib3's dotfiles";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    nixos-hardware.url = "github:NixOS/nixos-hardware";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  
  outputs = { self, ... }@inputs: with inputs; {
    nixosConfigurations.skunk = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./hosts/skunk/configuration.nix
        nixos-hardware.nixosModules.apple-t2
      ];
    };

    homeConfigurations."noib3@skunk" = home-manager.lib.homeManagerConfiguration {
      modules = [
        ./home.nix
        ./modules/programs/vivid.nix
        ./modules/services/skhd.nix
      ];

      extraSpecialArgs = rec {
        colorscheme = "tokyonight";
        configDir = ./home;
        font-family = "Inconsolata Nerd Font";
        hexlib = import ./lib/hex.nix { inherit (nixpkgs) lib; };
        palette = import (./palettes + "/${colorscheme}.nix");
        machine = "skunk";
      };

      pkgs = import nixpkgs {
        system = "x86_64-darwin";
      };
    };
  };

  nixConfig = {
    # Binary caches.
    extra-substituters = [
      "https://cache.soopy.moe"
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "cache.soopy.moe-1:0RZVsQeR+GOh0VQI9rvnHz55nVXkFardDqfm4+afjPo="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };
}
