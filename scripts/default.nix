{ pkgs
, hexlib
, palette
}:

{
  lf-recursive = import ./lf-recursive.nix { inherit pkgs hexlib palette; };
  preview = import ./preview.nix { inherit pkgs; };
  rg-pattern = import ./rg-pattern.nix { inherit pkgs; };
  rg-preview = import ./rg-preview.nix { inherit pkgs; };
  website-blocker = import ./website-blocker.nix { inherit pkgs; };
}
