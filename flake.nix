{
  description = "noib3's dotfiles";

  inputs = {
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nur.url = "github:nix-community/NUR";
    brew-nix = {
      url = "github:BatteredBunny/brew-nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nix-darwin.follows = "nix-darwin";
    };
    codex-cli-nix = {
      url = "github:sadjow/codex-cli-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    claude-code-nix = {
      url = "github:sadjow/claude-code-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    neovim = {
      url = "git+https://github.com/neovim/neovim.git?ref=refs/pull/37938/head&shallow=1";
      flake = false;
    };
    nix-community-neovim = {
      url = "github:nix-community/neovim-nightly-overlay";
      inputs.neovim-src.follows = "neovim";
    };
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-jettison = {
      url = "git+ssh://git@github.com/noib3/nix-jettison";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    opencode = {
      url = "github:anomalyco/opencode/production";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs:
    let
      machines = import ./machines {
        inherit inputs;
        colorscheme = "gruvbox";
        fonts = (import ./fonts).iosevka;
        userName = "noib3";
      };
    in
    machines.forEach (machine: {
      nixosConfigurations.${machine.name} = machine.nixosConfiguration;
      darwinConfigurations.${machine.name} = machine.darwinConfiguration;
      homeConfigurations.${machine.name} = machine.homeConfiguration;
    });
}
