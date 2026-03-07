{
  description = "noib3's Neovim configuration";

  inputs = {
    neovim-src.follows = "nix-community-neovim/neovim-src";
    nix-community-neovim.url = "github:nix-community/neovim-nightly-overlay";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    inputs:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      eachSystem =
        f:
        inputs.nixpkgs.lib.genAttrs systems (
          system: f inputs.nixpkgs.legacyPackages.${system}
        );
    in
    {
      homeManagerModules.default = import ./module.nix inputs;

      packages = eachSystem (pkgs: {
        default = pkgs.callPackage ./package.nix { inherit inputs; };
      });

      devShells = eachSystem (pkgs: {
        develop-neovim = pkgs.mkShell {
          name = "develop-neovim";
        };
      });

      vimRuntime = eachSystem (
        pkgs:
        "${
          inputs.nix-community-neovim.packages.${pkgs.stdenv.system}.default
        }/share/nvim/runtime"
      );
    };

  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };
}
