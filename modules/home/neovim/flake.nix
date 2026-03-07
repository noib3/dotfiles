{
  description = "noib3's Neovim configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix-community-neovim.url = "github:nix-community/neovim-nightly-overlay";
    neovim-src.follows = "nix-community-neovim/neovim-src";
  };

  outputs =
    inputs:
    let
      eachSystem = inputs.nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
    in
    {
      homeManagerModules.default = import ./module.nix inputs;

      packages = eachSystem (
        system:
        let
          pkgs = inputs.nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.callPackage ./package.nix { inherit inputs; };
        }
      );

      devShells = eachSystem (
        system:
        let
          pkgs = inputs.nixpkgs.legacyPackages.${system};
        in
        {
          develop-neovim = pkgs.mkShell {
            name = "develop-neovim";
          };
        }
      );

      vimRuntime = eachSystem (
        system: "${inputs.nix-community-neovim.packages.${system}.default}/share/nvim/runtime"
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
