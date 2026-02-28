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
    flake-parts.url = "github:hercules-ci/flake-parts";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    neovim = {
      url = "github:neovim/neovim";
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
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
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
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = machines.systems;

      imports = [ ./modules/flake ];

      flake = machines.forEach (machine: {
        nixosConfigurations.${machine.name} = machine.nixosConfiguration;
        darwinConfigurations.${machine.name} = machine.darwinConfiguration;
        homeConfigurations.${machine.name} = machine.homeConfiguration;
      });

      perSystem =
        {
          config,
          lib,
          pkgs,
          ...
        }:
        {
          # Workaround for https://github.com/NixOS/nix/issues/8881 so that
          # we can run individual checks with `nix run .#check-<foo>`.
          apps = lib.mapAttrs' (name: check: {
            name = "check-${name}";
            value = {
              type = "app";
              program =
                (pkgs.writeShellScript "check-${name}" ''
                  # Force evaluation of ${check}.
                  echo -e "\033[1;32m✓\033[0m Check '${name}' passed"
                '').outPath;
            };
          }) config.checks;
        };
    };
}
