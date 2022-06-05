{ config
, lib
, pkgs
, ...
}:

with lib;
let
  inherit (pkgs.stdenv.hostPlatform) isDarwin;

  cfg = config.services.skhd;
in
{
  options.services.skhd = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to enable the skhd hotkey daemon.";
    };

    package = mkOption {
      type = types.package;
      default = pkgs.skhd;
      description = "Package providing skhd.";
    };

    configPath = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = ''
        path to a skhd configuration file. This is written to
        <filename>$XDG_CONFIG_HOME/skhd/skhdrc</filename>. If defined, this
        will override <option>services.skhd.keybindings</option>.
      '';
    };

    keybindings = mkOption {
      type = types.lines;
      default = "";
      example = ''
        alt + shift - r   :   yabai quit
      '';
      description = ''
        skhd keybindings configuration to be written
        to <filename>$XDG_CONFIG_HOME/skhd/skhdrc</filename>.
        If <option>services.skhd.configPath</option> is defined and non-null,
        that will take precedence over this option.
      '';
    };
  };

  config = mkMerge [
    {
      assertions = [
        {
          assertion = cfg.enable -> isDarwin;
          message = "skhd is only supported on darwin";
        }
      ];
    }

    (mkIf cfg.enable {
      # the skhd binary should be available to shells for keypress simulation
      # functionality, e.g. exiting out of modes after running a script.
      home.packages = [ cfg.package ];

      xdg.configFile."skhd/skhdrc" = {
        source =
          if cfg.configPath != null
          then cfg.configPath
          else cfg.keybindings;
        onChange = "${cfg.package}/bin/skhd -r";
      };

      launchd.agents.skhd = {
        enable = lib.mkDefault true;
        # path = [ config.environment.systemPath ];
        config = {
          ProgramArguments = [
            "${cfg.package}/bin/skhd"
            "-c"
            "${config.xdg.configHome}/skhd/skhdrc"
          ];
          KeepAlive = true;
          ProcessType = "Interactive";
          EnvironmentVariables = {
            PATH = concatStringsSep ":" [
              "${config.home.homeDirectory}/.nix-profile/bin"
              "/run/current-system/sw/bin"
              "/nix/var/nix/profiles/default/"
            ];
          };
          StandardOutPath = "${config.xdg.cacheHome}/skhd.out.log";
          StandardErrorPath = "${config.xdg.cacheHome}/skhd.err.log";
        };
      };
    })
  ];
}
