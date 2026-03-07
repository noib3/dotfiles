{
  description = "noib3's Neovim configuration";

  inputs = {
    neovim-src.follows = "nix-community-neovim/neovim-src";
    nix-community-neovim.url = "github:nix-community/neovim-nightly-overlay";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Plugins.
    bufdelete-nvim = {
      url = "github:famiu/bufdelete.nvim";
      flake = false;
    };
    nvim-lspconfig = {
      url = "github:neovim/nvim-lspconfig";
      flake = false;
    };
    nvim-ts-context-commentstring = {
      url = "github:JoosepAlviste/nvim-ts-context-commentstring";
      flake = false;
    };
    comment-nvim = {
      url = "github:numToStr/Comment.nvim";
      flake = false;
    };
    crates-nvim = {
      url = "github:saecki/crates.nvim";
      flake = false;
    };
    gitsigns-nvim = {
      url = "github:lewis6991/gitsigns.nvim";
      flake = false;
    };
    inc-rename-nvim = {
      url = "github:smjonas/inc-rename.nvim";
      flake = false;
    };
    lsp-progress-nvim = {
      url = "github:linrongbin16/lsp-progress.nvim";
      flake = false;
    };
    neotab-nvim = {
      url = "github:kawre/neotab.nvim";
      flake = false;
    };
    nvim-lastplace = {
      url = "github:ethanholz/nvim-lastplace";
      flake = false;
    };
    nvim-surround = {
      url = "github:kylechui/nvim-surround";
      flake = false;
    };
  };

  outputs =
    inputs@{ nixpkgs, nix-community-neovim, ... }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      eachSystem = fun: nixpkgs.lib.genAttrs systems (system: fun nixpkgs.legacyPackages.${system});
    in
    {
      homeManagerModules.default = import ./module.nix inputs;

      packages = eachSystem (pkgs: {
        default = pkgs.callPackage ./package { inherit inputs; };
      });

      checks = eachSystem (pkgs: {
        default =
          pkgs.runCommand "check-config"
            {
              env.VIMRUNTIME = "${
                nix-community-neovim.packages.${pkgs.stdenv.system}.default
              }/share/nvim/runtime";
            }
            ''
              ${pkgs.lib.getExe pkgs.lua-language-server} \
                --check ${./config} \
                --logpath="$TMPDIR" \
                --metapath="$TMPDIR/meta" \
                2>&1 | tee "$out"
            '';
      });

      devShells = eachSystem (pkgs: {
        develop-neovim = pkgs.mkShell {
          name = "develop-neovim";
        };
      });
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
