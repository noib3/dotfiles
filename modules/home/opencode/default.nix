{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

with lib;
let
  cfg = config.modules.opencode;
in
{
  options.modules.opencode = {
    enable = mkEnableOption "OpenCode";
  };

  config = mkIf cfg.enable {
    programs.opencode = {
      enable = true;
      package = inputs.opencode.packages.${pkgs.stdenv.system}.default;
      settings = {
        theme = "system";
      };
    };
  };
}
