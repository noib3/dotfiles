{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.modules.codex;
in
{
  options.modules.codex = {
    enable = mkEnableOption "Codex";
  };

  config = mkIf cfg.enable {
    home = {
      packages = [ pkgs.codex ];

      sessionVariables = {
        CODEX_HOME = "${config.xdg.configHome}/codex";
      };
    };
  };
}
