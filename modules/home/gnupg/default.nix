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
        sevenDays = 604800;
      in
      {
        enable = true;
        defaultCacheTtl = sevenDays;
        maxCacheTtl = sevenDays;
        defaultCacheTtlSsh = sevenDays;
        maxCacheTtlSsh = sevenDays;
        pinentry.package =
          if pkgs.stdenv.isDarwin then pkgs.pinentry_mac else pkgs.pinentry-qt;
      };
  };
}
