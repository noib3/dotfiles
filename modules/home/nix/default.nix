{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

{
  imports = [
    inputs.nix-jettison.homeManagerModules.default
  ];

  config = {
    home.packages = with pkgs; [
      nixVersions.latest
      nixd
      nixfmt
    ];

    nix = {
      package = pkgs.nixVersions.latest;
      plugins.jettison.enable = false;
      settings = {
        experimental-features = [
          "flakes"
          "nix-command"
          "pipe-operators"
        ];
        trusted-substituters = [
          "https://nix-community.cachix.org"
        ]
        ++ (lib.optional config.machines."skunk@linux".isCurrent
          "https://cache.soopy.moe"
        );
        use-xdg-base-directories = true;
        warn-dirty = false;
      };
    };

    # Make `nix develop`, `nix shell` and `nix-shell` use fish instead of bash.
    programs.fish.interactiveShellInit = lib.mkIf config.programs.fish.enable ''
      function nix-shell --description "Start an interactive shell based on a Nix expression"
          ${pkgs.nix-your-shell}/bin/nix-your-shell fish nix-shell -- $argv
      end

      function nix --description "Reproducible and declarative configuration management"
          ${pkgs.nix-your-shell}/bin/nix-your-shell fish nix -- $argv
      end
    '';

    modules.neovim = {
      tree-sitter-parsers = [ pkgs.vimPlugins.nvim-treesitter-parsers.nix ];
      tree-sitter-queries = [ pkgs.vimPlugins.nvim-treesitter.queries.nix ];
    };
  };
}
