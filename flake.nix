{
  description = "noib3's dotfiles";

  inputs = {
    brew-api = {
      url = "github:BatteredBunny/brew-api";
      flake = false;
    };
    brew-nix = {
      url = "github:BatteredBunny/brew-nix";
      inputs.brew-api.follows = "brew-api";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nix-darwin.follows = "nix-darwin";
    };
    claude-code-nix = {
      url = "github:sadjow/claude-code-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    codex-cli-nix = {
      url = "github:sadjow/codex-cli-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    codex-lb = {
      url = "github:Soju06/codex-lb";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-parts.url = "github:hercules-ci/flake-parts";
    jujutsu = {
      url = "github:jj-vcs/jj";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.rust-overlay.follows = "rust-overlay";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    neovim = {
      url = ./modules/home/neovim;
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.treefmt-nix.follows = "treefmt-nix";
    };
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
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
      "https://cache.sub60.dev/noib3/dotfiles"
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "cache.sub60.dev/noib3/dotfiles-1:ZpBUDFsYAQAi2hHs6ot+3m5+wZYXHyGBhEsgobh3k7I="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };
}
