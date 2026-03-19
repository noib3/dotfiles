{
  config,
  pkgs,
  ...
}:

let
  projectHashUtils = builtins.readFile ./project-hash-utils.sh;

  scripts = {
    cargo-target-dir-env = pkgs.writeShellApplication {
      name = "cargo-target-dir-env";
      runtimeEnv = {
        DOCUMENTS = config.lib.mine.documentsDir;
        XDG_STATE_HOME = config.xdg.stateHome;
      };
      text = ''
        ${projectHashUtils}
        ${builtins.readFile ./cargo-target-dir-env.sh}
      '';
    };

    direnv-layout-dir = pkgs.writeShellApplication {
      name = "direnv-layout-dir";
      runtimeEnv = {
        DOCUMENTS = config.lib.mine.documentsDir;
        XDG_STATE_HOME = config.xdg.stateHome;
      };
      text = ''
        ${projectHashUtils}
        ${builtins.readFile ./direnv-layout-dir.sh}
      '';
    };

    fuzzy-ripgrep = import ./fuzzy-ripgrep.nix { inherit pkgs; };

    lf-recursive = import ./lf-recursive.nix { inherit config pkgs; };

    pc = pkgs.writeShellApplication {
      name = "pc";
      runtimeEnv.DOCUMENTS = config.lib.mine.documentsDir;
      text = builtins.readFile ./pc.sh;
    };

    preview = import ./preview.nix { inherit pkgs; };
    rg-pattern = import ./rg-pattern.nix { inherit pkgs; };
    rg-preview = import ./rg-preview.nix { inherit pkgs; };

    td = pkgs.writeShellApplication {
      name = "td";
      runtimeEnv.DOCUMENTS = config.lib.mine.documentsDir;
      text = builtins.readFile ./td.sh;
    };
  };
in
{
  config = {
    nixpkgs.overlays = [
      (final: prev: { inherit scripts; })
    ];
  };
}
