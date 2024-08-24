{
  description = "noib3's dotfiles";

  inputs = {
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nur.url = "github:nix-community/NUR";

    ags = {
      url = "github:Aylur/ags";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    neovim-nightly-overlay = {
      url = "github:nix-community/neovim-nightly-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs:
    with inputs;
    let
      pkgs = import nixpkgs {
        system = "x86_64-linux";
        config = {
          allowUnfreePredicate =
            pkg:
            builtins.elem (nixpkgs.lib.getName pkg) [
              "megasync"
              "ookla-speedtest"
              "spotify"
              "zoom"
            ];
        };
        overlays = [
          neovim-nightly-overlay.overlays.default
          nur.overlay
          rust-overlay.overlays.default
          (final: prev: {
            scripts = import ./scripts {
              inherit colorscheme;
              pkgs = prev;
            };
          })
        ];
      };

      fonts = (import ./fonts).schemes.fira pkgs;
      colorscheme = "tokyonight";
      username = "noib3";
    in
    {
      nixosConfigurations.skunk = nixpkgs.lib.nixosSystem {
        inherit pkgs;
        inherit (pkgs) system;
        modules = [
          ./hosts/skunk/configuration.nix
          ./modules/block-domains.nix
          nixos-hardware.nixosModules.apple-t2
        ];
        specialArgs = {
          inherit username;
        };
      };

      homeConfigurations."noib3@skunk" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;

        modules = [
          ags.homeManagerModules.default
          ./fonts/module.nix
          ./home.nix
          ./modules/programs/vivid.nix
          ./modules/services/bluetooth-autoconnect.nix
          ./modules/services/skhd.nix
        ];

        extraSpecialArgs = {
          inherit colorscheme fonts username;
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
