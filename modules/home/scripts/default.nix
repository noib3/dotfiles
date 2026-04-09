{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.modules.scripts = lib.mkOption {
    type = lib.types.attrsOf lib.types.path;
    readOnly = true;
    default = {
      fuzzy-ripgrep = pkgs.writeShellApplication {
        name = "fuzzy-ripgrep";
        runtimeInputs = with pkgs; [
          config.modules.scripts.rg-pattern
          fzf
          git
          gnused
          uutils-coreutils-noprefix # Contains `head`
        ];
        text = builtins.readFile ./fuzzy-ripgrep.sh;
      };

      lf-recursive = import ./lf-recursive.nix { inherit config pkgs; };

      pc = pkgs.writeShellApplication {
        name = "pc";
        text = builtins.readFile ./pc.sh;
      };

      preview = import ./preview.nix { inherit pkgs; };

      rg-pattern = pkgs.writeShellApplication {
        name = "rg-pattern";
        runtimeInputs = with pkgs; [
          gnused
          ripgrep
        ];
        text = builtins.readFile ./rg-pattern.sh;
      };

      rg-preview = pkgs.writeShellApplication {
        name = "rg-preview";
        runtimeInputs = with pkgs; [
          bat
          file
          gnugrep
          gnupg
        ];
        text = ''
          ${builtins.readFile ./preview-common.sh}
          ${builtins.readFile ./rg-preview.sh}
        '';
      };

      td = pkgs.writeShellApplication {
        name = "td";
        text = builtins.readFile ./td.sh;
      };

      tm = pkgs.writeShellApplication {
        name = "tm";
        runtimeInputs = [ pkgs.coreutils ]; # Adds GNU's date.
        text = builtins.readFile ./tm.sh;
      };
    };
  };

  config.home.packages = builtins.attrValues config.modules.scripts;
}
