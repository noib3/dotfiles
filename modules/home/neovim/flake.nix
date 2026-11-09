{
  description = "noib3's Neovim configuration";

  inputs = {
    neovim-src = {
      url = "github:noib3/neovim/noib3";
      flake = false;
    };
    nix-community-neovim = {
      url = "github:nix-community/neovim-nightly-overlay";
      inputs.neovim-src.follows = "neovim-src";
    };
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Remove once nixpkgs has Zig 0.17.
    zig-overlay = {
      url = "github:mitchellh/zig-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Plugins.
    blink-cmp = {
      url = "github:Saghen/blink.cmp";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
    # Only used for its C library, libvscode-diff.
    codediff-nvim = {
      url = "github:esmuellert/codediff.nvim";
      flake = false;
    };
    copilot-lua = {
      url = "github:noib3/copilot.lua/fix-insert-special-key-passthrough";
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
      url = "github:b0o/incline.nvim/pull/96/head";
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
    nvim-lint = {
      url = "github:mfussenegger/nvim-lint";
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
    inputs@{
      self,
      nixpkgs,
      treefmt-nix,
      ...
    }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      unfreePackages = [
        "copilot-language-server"
      ];

      mkPkgs =
        {
          system,
        }:
        import nixpkgs {
          inherit system;
          config = {
            allowUnfreePredicate =
              pkg: builtins.elem (nixpkgs.lib.getName pkg) unfreePackages;
          };
        };

      eachSystem =
        fun:
        nixpkgs.lib.genAttrs systems (
          system:
          fun (mkPkgs {
            inherit system;
          })
        );

      mkTreefmt =
        pkgs:
        treefmt-nix.lib.evalModule pkgs {
          projectRootFile = "flake.nix";
          programs.nixfmt = {
            enable = true;
            width = 80;
          };
        };
    in
    {
      homeManagerModules.default = import ./module.nix { inherit inputs mkPkgs; };

      packages = eachSystem (
        pkgs:
        let
          nvim = pkgs.callPackage ./package { inherit inputs; };
        in
        {
          default = nvim;
          setupHook = pkgs.writeText "nvim-setup-hook" ''
            ${pkgs.lib.concatStringsSep "\n" (
              pkgs.lib.mapAttrsToList (
                name: value: "export ${name}=${pkgs.lib.escapeShellArg "${value}"}"
              ) (nvim.override { includeConfig = false; }).env
            )}
          '';
        }
      );

      checks = eachSystem (
        pkgs:
        let
          nvim = self.packages.${pkgs.stdenv.system}.default;
          emmylua_check = pkgs.lib.getExe' pkgs.emmylua-check "emmylua_check";

          # The configuration's settings, with the `lua` directories of the
          # plugins in this repo as the workspace roots, and only the other
          # plugins as libraries. Otherwise the plugins in this repo would be
          # both, and EmmyLua would see each of their classes twice.
          pluginsConfig =
            let
              config = builtins.fromJSON (builtins.readFile ./plugins/.emmyrc.json);
              library = map (
                entry:
                if entry.path or null == "$NVIM_PLUGINS_LUA" then
                  entry // { path = "${nvim.thirdPartyLua}"; }
                else
                  entry
              ) config.workspace.library;
              plugins = builtins.attrNames (
                pkgs.lib.filterAttrs (_: type: type == "directory") (builtins.readDir ./plugins)
              );
              missing = builtins.filter (
                name: !builtins.elem "./${name}/lua" config.workspace.workspaceRoots
              ) plugins;
            in
            assert pkgs.lib.assertMsg (missing == [ ])
              "plugins/.emmyrc.json's workspaceRoots are missing ${toString missing}";
            pkgs.writeText "emmyrc.json" (
              builtins.toJSON (pkgs.lib.recursiveUpdate config { workspace.library = library; })
            );
        in
        {
          default =
            pkgs.runCommand "check-config"
              {
                env.NVIM_PLUGINS_LUA = nvim.env.NVIM_PLUGINS_LUA;
                env.VIMRUNTIME = "${nvim.neovim}/share/nvim/runtime";
              }
              ''
                ${emmylua_check} --warnings-as-errors ${./config} 2>&1 | tee "$out"
                ${emmylua_check} --warnings-as-errors --config ${pluginsConfig} ${./plugins} \
                  2>&1 | tee -a "$out"
              '';
        }
      );

      tests = eachSystem (
        pkgs:
        let
          nvim = self.packages.${pkgs.stdenv.system}.default;
          localPlugins = builtins.attrNames (builtins.readDir ./plugins);

          # The `lua` directories of the other plugins, which the tests can
          # require, as a single runtimepath entry.
          thirdPartyRtp = pkgs.linkFarm "nvim-third-party-rtp" [
            {
              name = "lua";
              path = nvim.thirdPartyLua;
            }
          ];

          rtp = pkgs.lib.concatStringsSep "," (
            map (name: "${./plugins}/${name}") localPlugins ++ [ "${thirdPartyRtp}" ]
          );
        in
        {
          # Runs the `tests/*.lua` files of the plugins in this repo, each
          # in its own headless Neovim, and exits with an error if any of them
          # failed.
          plugins = pkgs.writeShellApplication {
            name = "test-neovim-plugins";
            runtimeInputs = [
              pkgs.git
              pkgs.jujutsu
            ];
            text = ''
              # The tests' repos and jj's config are kept out of the user's.
              tmp=$(mktemp -d)
              trap 'rm -rf "$tmp"' EXIT
              export HOME="$tmp" TMPDIR="$tmp"
              export JJ_USER=test JJ_EMAIL=test@example.com
              export LIBVSCODE_DIFF=${nvim.env.LIBVSCODE_DIFF}

              failed=0
              for test in ${./plugins}/*/tests/*.lua; do
                echo "--- ''${test#${./plugins}/}"
                if ! TEST_FILE="$test" ${nvim.neovim}/bin/nvim --headless --clean -n -i NONE \
                  --cmd "set rtp^=${rtp}" \
                  -c "luafile ${./tests/run.lua}"; then
                  failed=1
                fi
              done
              exit "$failed"
            '';
          };
        }
      );

      formatter = eachSystem (pkgs: (mkTreefmt pkgs).config.build.wrapper);
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
