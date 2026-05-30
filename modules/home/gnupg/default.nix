{
  config,
  pkgs,
  lib,
  ...
}@args:

with lib;
let
  cfg = config.modules.gnupg;
  isEmbedded = args ? hostConfig;
  shouldForwardGpgAgent = isEmbedded && args.hostConfig.services.gpg-agent.enable;
in
{
  options.modules.gnupg = {
    enable = mkEnableOption "GnuPG";
  };

  config = mkIf cfg.enable {
    programs.gpg = {
      enable = true;
      # In embedded guests with agent forwarding, GnuPG must use its default
      # homedir so its agent socket path matches Lima's fixed guestSocket.
      homedir = mkIf (!shouldForwardGpgAgent) "${config.xdg.dataHome}/gnupg";
      settings.no-autostart = mkIf shouldForwardGpgAgent true;
    };

    services.gpg-agent =
      let
        sevenDays = 604800;
      in
      {
        enable = !shouldForwardGpgAgent;
        enableExtraSocket = !isEmbedded && config.modules.lima.enable;
        defaultCacheTtl = sevenDays;
        maxCacheTtl = sevenDays;
        defaultCacheTtlSsh = sevenDays;
        maxCacheTtlSsh = sevenDays;
        pinentry.package =
          if pkgs.stdenv.isDarwin then pkgs.pinentry_mac else pkgs.pinentry-qt;
      };

    systemd.user.tmpfiles.rules = optionals shouldForwardGpgAgent [
      "d %t/gnupg 0700 - - - -"
    ];
  };
}
