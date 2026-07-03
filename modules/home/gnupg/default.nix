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
  publicKeysHostDir = "${config.xdg.stateHome}/gnupg/lima-public-keys";
  publicKeysGuestDir = "/run/gnupg-host-public-keys";
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

    modules.lima.mounts = mkIf config.modules.lima.enable [
      {
        location = publicKeysHostDir;
        mountPoint = publicKeysGuestDir;
        writeable = false;
      }
    ];

    home.activation.exportGpgPublicKeys = mkIf config.modules.lima.enable (
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        dir=${lib.escapeShellArg publicKeysHostDir}
        run mkdir -p "$dir"
        run chmod 700 "$dir"
        run ${lib.getExe pkgs.gnupg} --batch --yes --armor --export --output "$dir/host-public-keys.asc"
        run chmod 600 "$dir/host-public-keys.asc"
      ''
    );

    home.activation.importHostGpgPublicKeys =
      mkIf (isEmbedded && args.hostConfig.modules.gnupg.enable)
        (
          lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            dir=${lib.escapeShellArg publicKeysGuestDir}
            if [[ -s "$dir/host-public-keys.asc" ]]; then
              run ${lib.getExe pkgs.gnupg} --batch --import "$dir/host-public-keys.asc"
            fi
          ''
        );
  };
}
