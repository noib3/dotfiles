{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.modules.brave;
  inherit (pkgs.stdenv) isDarwin isLinux;
in
{
  options.modules.brave = {
    enable = mkEnableOption "Brave";
  };

  config = mkIf cfg.enable {
    programs.brave = {
      enable = true;
      package = pkgs.brave;
      extensions = [
        { id = "ghmbeldphafepmbegfdlkpapadhbakde"; } # Proton Pass
      ];
    };

    home.activation = lib.mkIf isDarwin {
      setBraveAsDefaultBrowser = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        $DRY_RUN_CMD ${pkgs.defaultbrowser}/bin/defaultbrowser browser
      '';
      setBraveSearchEngines = lib.hm.dag.entryAfter [ "writeBoundary" ] (
        import ./set-search-engines.nix { inherit config pkgs lib; }
      );
    };

    xdg.mimeApps = lib.mkIf isLinux {
      enable = true;
      defaultApplications = {
        "text/html" = [ "brave.desktop" ];
        "x-scheme-handler/http" = [ "brave.desktop" ];
        "x-scheme-handler/https" = [ "brave.desktop" ];
      };
    };
  };
}
