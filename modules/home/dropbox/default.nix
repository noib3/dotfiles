{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.modules.dropbox;
  inherit (pkgs.stdenv) isDarwin isLinux;
in
{
  options.modules.dropbox = {
    enable = mkEnableOption "Dropbox";
  };

  config = mkIf cfg.enable {
    home.packages =
      (lib.optional isDarwin pkgs.brewCasks.dropbox) ++ (lib.optional isLinux pkgs.dropbox-cli);

    modules.nixpkgs.allowUnfreePackages = [
      "dropbox"
    ]
    # Not sure why Dropbox pulls in Firefox on Linux, but it does.
    ++ lib.lists.optionals pkgs.stdenv.isLinux [
      "firefox-bin"
      "firefox-bin-unwrapped"
    ];

    systemd.user.services.dropbox = lib.mkIf pkgs.stdenv.isLinux {
      Unit = {
        Description = "dropbox";
      };

      Install = {
        WantedBy = [ "default.target" ];
      };

      Service =
        let
          dropboxCmd = "${pkgs.dropbox-cli}/bin/dropbox";
        in
        {
          Type = "simple";
          ExecStop = "${dropboxCmd} stop";
          ExecStart = toString (
            pkgs.writeShellScript "dropbox-start" ''
              # get the dropbox bins if needed
              if [[ ! -f $HOME/.dropbox-dist/VERSION ]]; then
                ${pkgs.coreutils}/bin/yes | ${dropboxCmd} update
              fi

              ${pkgs.dropbox}/bin/dropbox
            ''
          );
        };
    };
  };
}
