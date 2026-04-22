{
  description = "noib3's dotfiles";

  inputs = {
    brew-nix = {
      url = "github:BatteredBunny/brew-nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nix-darwin.follows = "nix-darwin";
    };
    bun2nix = {
      url = "github:nix-community/bun2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    claude-code-nix = {
      url = "github:sadjow/claude-code-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    codex-cli-nix = {
      url = "github:sadjow/codex-cli-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-parts.url = "github:hercules-ci/flake-parts";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    neovim = {
      url = ./modules/home/neovim;
      inputs.nixpkgs.follows = "nixpkgs";
      # inputs.neovim-src.follows = "neovim-src";
    };
    neovim-src = {
      url = "github:neovim/neovim";
      flake = false;
    };
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-jettison = {
      url = "git+ssh://git@github.com/noib3/nix-jettison";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    opencode = {
      url = "github:anomalyco/opencode/production";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    opencode-anthropic-auth = {
      url = "github:ex-machina-co/opencode-anthropic-auth";
      flake = false;
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
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ ./modules/flake ];

      _module.args = {
        colorscheme = "gruvbox";
        fontstack = "iosevka";
        username = "noib3";
      };

      perSystem =
        {
          config,
          lib,
          pkgs,
          ...
        }:
        {
          # Workaround for https://github.com/NixOS/nix/issues/8881 so that we
          # can run individual checks with `nix run .#check-<foo>`.
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

  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org"
      "https://nomad.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "nomad.cachix.org-1:jQ4al6yxQyvUBB7YJVJbMbc9rASokqamqvPhBUrVjww="
    ];
  };
}
