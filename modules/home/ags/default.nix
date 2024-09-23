{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.modules.ags;
in
{
  options.modules.ags = {
    enable = mkEnableOption "Ags";
  };

  config = mkIf cfg.enable ({
    home.packages = [
      (pkgs.hiPrio (
        pkgs.writeShellApplication {
          name = "ags";
          runtimeInputs = [ pkgs.bun ];
          text = "${pkgs.ags}/bin/ags";
        }
      ))
    ];

    programs.ags = import ./config.nix { inherit pkgs; };
  });
}
