{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.modules.signal;
in
{
  options.modules.signal = {
    enable = mkEnableOption "Signal desktop client";
  };

  config = mkIf cfg.enable {
    home.packages = [
      (if pkgs.stdenv.isDarwin then pkgs.signal-desktop-bin else pkgs.signal-desktop)
    ];

    modules.nixpkgs.allowUnfreePackages = lib.mkIf pkgs.stdenv.isDarwin [
      (lib.getName pkgs.signal-desktop-bin)
    ];
  };
}
