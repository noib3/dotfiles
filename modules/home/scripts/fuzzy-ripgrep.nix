{ pkgs }:

let
  rg-pattern = import ./rg-pattern.nix { inherit pkgs; };
in
pkgs.writeShellApplication {
  name = "fuzzy-ripgrep";

  runtimeInputs = with pkgs; [
    fzf
    git
    rg-pattern
    gnused
    # Contains `head`.
    uutils-coreutils-noprefix
  ];

  text = "${builtins.readFile ./fuzzy-ripgrep.sh}";
}
