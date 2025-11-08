{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.modules.duckduckgo;
in
{
  options.modules.duckduckgo = {
    enable = mkEnableOption "DuckDuckGo browser";
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = !pkgs.stdenv.isLinux;
        message = "The DuckDuckGo browser is not available on Linux";
      }
    ];

    home.packages = lib.mkIf pkgs.stdenv.isDarwin [
      pkgs.brewCasks.duckduckgo
    ];

    # home.activation = lib.mkIf pkgs.stdenv.isDarwin {
    #   setDuckDuckGoAsDefaultBrowser = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    #     run ${pkgs.defaultbrowser}/bin/defaultbrowser duckduckgo
    #   '';
    # };
  };
}
