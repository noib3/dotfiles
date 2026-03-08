{
  config,
  lib,
  ...
}:

with lib;
let
  cfg = config.modules.bat;
in
{
  options.modules.bat = {
    enable = mkEnableOption "bat";
  };

  config = mkIf cfg.enable {
    programs.bat = {
      enable = true;
      config = {
        decorations = "never";
        paging = "never";
        theme = "TwoDark";
      };
    };
  };
}
