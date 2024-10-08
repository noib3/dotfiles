{ colorscheme }:

{
  overlay =
    final: prev:
    let
      pkgs = prev;
      palette = import (../palettes + "/${colorscheme}.nix");
    in
    {
      scripts = {
        fuzzy-ripgrep = import ./fuzzy-ripgrep.nix { inherit pkgs; };
        lf-recursive = import ./lf-recursive.nix { inherit pkgs palette; };
        preview = import ./preview.nix { inherit pkgs; };
        rg-pattern = import ./rg-pattern.nix { inherit pkgs; };
        rg-preview = import ./rg-preview.nix { inherit pkgs; };
        website-blocker = import ./website-blocker.nix { inherit pkgs; };
      };
    };
}
