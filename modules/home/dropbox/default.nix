{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.modules.dropbox;
in
{
  options.modules.dropbox = {
    enable = mkEnableOption "Dropbox";
  };

  config = mkIf cfg.enable {
    home.packages = lib.mkIf pkgs.stdenv.isLinux [ pkgs.dropbox-cli ];

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
