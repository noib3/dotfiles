{
  lib,
  pkgs,
  ...
}:

with lib;
{
  options.scripts = {
    website-blocker = mkOption {
      type = types.package;
      default = import ./website-blocker.nix { inherit pkgs; };
    };
  };
}
