{ pkgs }:

let
  size = 18;
in
{
  enable = pkgs.stdenv.isLinux;

  settings = {
    main = {
      font = "monospace:size=${builtins.toString size}";
      lines = 12;
      width = 45;
      vertical-pad = 8;
      horizontal-pad = 64;
    };

    border = {
      radius = 0;
    };
  };
}
