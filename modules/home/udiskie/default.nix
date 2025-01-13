{
  config,
  lib,
  ...
}:

with lib;
let
  cfg = config.modules.udiskie;
in
{
  options.modules.udiskie = {
    enable = mkEnableOption "udiskie";
  };

  config = mkIf cfg.enable {
    services.udiskie = {
      enable = true;
      automount = true;
      notify = true;
      tray = "never";
    };
  };
}
