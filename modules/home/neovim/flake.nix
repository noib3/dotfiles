{
  description = "noib3's Neovim configuration";

  inputs = {
    neovim-src.follows = "nix-community-neovim/neovim-src";
    nix-community-neovim.url = "github:nix-community/neovim-nightly-overlay";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Plugins.
    blink-cmp.url = "github:Saghen/blink.cmp";
    blink-emoji-nvim = {
      url = "github:moyiz/blink-emoji.nvim";
      flake = false;
    };
    bufdelete-nvim = {
      url = "github:famiu/bufdelete.nvim";
      flake = false;
    };
    colorful-menu-nvim = {
      url = "github:noib3/colorful-menu.nvim/noib3";
      flake = false;
    };
    comment-nvim = {
      url = "github:numToStr/Comment.nvim";
      flake = false;
    };
    conform-nvim = {
      url = "github:stevearc/conform.nvim";
      flake = false;
    };
    crates-nvim = {
      url = "github:saecki/crates.nvim";
      flake = false;
    };
    fzf-lua = {
      url = "github:ibhagwan/fzf-lua";
      flake = false;
    };
    gitsigns-nvim = {
      url = "github:lewis6991/gitsigns.nvim";
      flake = false;
    };
    gruvbox-nvim = {
      url = "github:ellisonleao/gruvbox.nvim";
      flake = false;
    };
    hop-nvim = {
      url = "github:smoka7/hop.nvim";
      flake = false;
    };
    inc-rename-nvim = {
      url = "github:smjonas/inc-rename.nvim";
      flake = false;
    };
    incline-nvim = {
      url = "github:b0o/incline.nvim";
      flake = false;
    };
    lsp-progress-nvim = {
      url = "github:linrongbin16/lsp-progress.nvim";
      flake = false;
    };
    lualine-nvim = {
      url = "github:nvim-lualine/lualine.nvim";
      flake = false;
    };
    neotab-nvim = {
      url = "github:kawre/neotab.nvim";
      flake = false;
    };
    neotest = {
      url = "github:nvim-neotest/neotest";
      flake = false;
    };
    nomad.url = "github:nomad/nomad";
    nvim-autopairs = {
      url = "github:windwp/nvim-autopairs";
      flake = false;
    };
    nvim-colorizer-lua = {
      url = "github:NiklasV1/nvim-colorizer.lua";
      flake = false;
    };
    nvim-lastplace = {
      url = "github:ethanholz/nvim-lastplace";
      flake = false;
    };
    nvim-lspconfig = {
      url = "github:neovim/nvim-lspconfig";
      flake = false;
    };
    nvim-nio = {
      url = "github:nvim-neotest/nvim-nio";
      flake = false;
    };
    nvim-notify = {
      url = "github:rcarriga/nvim-notify";
      flake = false;
    };
    nvim-surround = {
      url = "github:kylechui/nvim-surround";
      flake = false;
    };
    nvim-treesitter = {
      url = "github:nvim-treesitter/nvim-treesitter/main";
      flake = false;
    };
    nvim-treesitter-endwise = {
      url = "github:RRethy/nvim-treesitter-endwise";
      flake = false;
    };
    nvim-ts-context-commentstring = {
      url = "github:JoosepAlviste/nvim-ts-context-commentstring";
      flake = false;
    };
    nvim-web-devicons = {
      url = "github:nvim-tree/nvim-web-devicons";
      flake = false;
    };
    plenary-nvim = {
      url = "github:nvim-lua/plenary.nvim";
      flake = false;
    };
    rustaceanvim = {
      url = "github:mrcjkb/rustaceanvim";
      flake = false;
    };
    toggleterm-nvim = {
      url = "github:akinsho/toggleterm.nvim";
      flake = false;
    };
    tokyonight-nvim = {
      url = "github:folke/tokyonight.nvim";
      flake = false;
    };
    treesitter-modules-nvim = {
      url = "github:MeanderingProgrammer/treesitter-modules.nvim";
      flake = false;
    };
    trouble-nvim = {
      url = "github:folke/trouble.nvim";
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

      eachSystem =
        fun:
        nixpkgs.lib.genAttrs systems (system: fun nixpkgs.legacyPackages.${system});
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
      "https://nomad.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "nomad.cachix.org-1:jQ4al6yxQyvUBB7YJVJbMbc9rASokqamqvPhBUrVjww="
    ];
  };
}
