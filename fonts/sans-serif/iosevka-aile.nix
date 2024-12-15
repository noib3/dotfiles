{ pkgs, ... }:

{
  name = "Iosevka Aile";
  package = pkgs.iosevka-bin.override { variant = "Aile"; };
  size = _config: _program: 16.5;
}
