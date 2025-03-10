{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.modules.brave;
in
{
  options.modules.brave = {
    enable = mkEnableOption "Brave";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.brave ];

    home.activation = lib.mkIf pkgs.stdenv.isDarwin {
      setBraveAsDefaultBrowser = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        $DRY_RUN_CMD ${pkgs.defaultbrowser}/bin/defaultbrowser browser
      '';
    };

    xdg.mimeApps = lib.mkIf pkgs.stdenv.isLinux {
      enable = true;
      defaultApplications = {
        "text/html" = [ "brave.desktop" ];
        "x-scheme-handler/http" = [ "brave.desktop" ];
        "x-scheme-handler/https" = [ "brave.desktop" ];
      };
    };
  };
}
