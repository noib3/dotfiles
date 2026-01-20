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

    directory = mkOption {
      type = types.singleLineStr;
      default = "${config.home.homeDirectory}/Dropbox";
      description = "The path to the Dropbox directory";
    };

    ignoreRules = mkOption {
      type = types.listOf types.singleLineStr;
      default = [ ];
      description = ''
        List of Dropbox ignore rules to write to rules.dropboxignore. See
        https://help.dropbox.com/sync/how-to-prevent-files-from-syncing for the
        accepted formats
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages =
      (lib.optional isDarwin pkgs.brewCasks.dropbox)
      ++ (lib.optional isLinux pkgs.dropbox-cli);

    modules.nixpkgs.allowUnfreePackages = [
      "dropbox"
    ]
    # Not sure why Dropbox pulls in Firefox on Linux, but it does.
    ++ lib.lists.optionals pkgs.stdenv.isLinux [
      "firefox-bin"
      "firefox-bin-unwrapped"
    ];

    modules.dropbox.ignoreRules = [
      ".DS_Store"
      "target/"
    ];

    home.file = lib.mkIf (cfg.ignoreRules != [ ]) {
      dropboxIgnoreRules = {
        target = "${cfg.directory}/rules.dropboxignore";
        text = lib.concatStringsSep "\n" cfg.ignoreRules;
      };
    };

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

    home.activation = lib.mkIf isDarwin {
      symlinkDocumentsToDropbox = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        if [ ! -e "${cfg.directory}" ] && [ ! -L "${cfg.directory}" ]; then
          ln -s \
            "${cfg.home.homeDirectory}/Library/CloudStorage/Dropbox" \
            "${cfg.directory}"
        fi
      '';
    };
  };
}
