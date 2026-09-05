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
      fuzzy-cd-directory = pkgs.writeShellApplication {
        name = "fuzzy-cd-directory";
        runtimeInputs = [ config.programs.fzf.package ];
        text = builtins.readFile ./fuzzy-cd-directory.sh;
      };

      fuzzy-edit-files = pkgs.writeShellApplication {
        name = "fuzzy-edit-files";
        runtimeInputs = [
          config.modules.scripts.lf-recursive
          config.modules.scripts.preview
          config.programs.fzf.package
          pkgs.git
        ];
        text = builtins.readFile ./fuzzy-edit-files.sh;
      };

      fuzzy-ripgrep = pkgs.writeShellApplication {
        name = "fuzzy-ripgrep";
        runtimeInputs = with pkgs; [
          config.modules.scripts.rg-pattern
          config.programs.fzf.package
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

      tw = pkgs.writeShellApplication {
        name = "tw";
        runtimeInputs = [ pkgs.coreutils ]; # Adds GNU's date.
        text = builtins.readFile ./tw.sh;
      };

      yo = pkgs.writeShellApplication {
        name = "yo";
        text = builtins.readFile ./yo.sh;
      };

      nw = pkgs.writeShellApplication {
        name = "nw";
        runtimeInputs = [ pkgs.coreutils ]; # Adds GNU's date.
        text = builtins.readFile ./nw.sh;
      };
    };
  };

  config.home.packages = builtins.attrValues config.modules.scripts;
}
