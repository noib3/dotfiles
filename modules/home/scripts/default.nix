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
      text = builtins.readFile ./pc.sh;
    };

    preview = import ./preview.nix { inherit pkgs; };
    rg-pattern = import ./rg-pattern.nix { inherit pkgs; };
    rg-preview = import ./rg-preview.nix { inherit pkgs; };

    td = pkgs.writeShellApplication {
      name = "td";
      text = builtins.readFile ./td.sh;
    };

    tm = pkgs.writeShellApplication {
      name = "tm";
      text = builtins.readFile ./tm.sh;
      runtimeInputs = [ pkgs.coreutils ]; # Adds GNU's date.
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
