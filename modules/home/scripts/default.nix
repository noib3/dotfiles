{
  config,
  pkgs,
  ...
}:

let
  scripts = {
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
