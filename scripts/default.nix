{ pkgs
, hexlib
, palette
}:

{
  lf-recursive = import ./lf-recursive.nix { inherit pkgs hexlib palette; };
}
