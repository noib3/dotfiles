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
        extra-substituters = [
          "https://nix-community.cachix.org"
        ];
        extra-trusted-public-keys = [
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs"
        ];
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
