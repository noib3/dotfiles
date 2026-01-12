{
  config,
  pkgs,
  lib,
  ...
}:

with lib;
let
  cfg = config.modules.gnupg;
in
{
  options.modules.gnupg = {
    enable = mkEnableOption "GnuPG";
  };

  config = mkIf cfg.enable {
    programs.gpg = {
      enable = true;
      homedir = "${config.xdg.dataHome}/gnupg";
    };

    services.gpg-agent =
      let
        seven_days = 604800;
      in
      {
        enable = true;
        defaultCacheTtl = seven_days;
        maxCacheTtl = seven_days;
        defaultCacheTtlSsh = seven_days;
        maxCacheTtlSsh = seven_days;
        pinentry.package =
          if pkgs.stdenv.isDarwin then pkgs.pinentry_mac else pkgs.pinentry-qt;
      };
  };
}
