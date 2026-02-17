{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.services.yabai;

  toYabaiConfig =
    opts:
    concatStringsSep "\n" (
      mapAttrsToList (name: value: "yabai -m config ${name} ${toString value}") opts
    );

  configFile = pkgs.writeShellScript "yabairc" ''
    ${optionalString (cfg.config != { }) (toYabaiConfig cfg.config)}
    ${optionalString (cfg.extraConfig != "") cfg.extraConfig}
  '';
in
{
  options.services.yabai = {
    enable = mkEnableOption "yabai window manager";

    package = mkPackageOption pkgs "yabai" { };

    errorLogFile = mkOption {
      type = with types; nullOr (either path str);
      default = "${config.home.homeDirectory}/Library/Logs/yabai/yabai.err.log";
      example = "/Users/noib3/Library/Logs/yabai/yabai.err.log";
      description = "Absolute path to log all stderr output.";
    };

    outLogFile = mkOption {
      type = with types; nullOr (either path str);
      default = "${config.home.homeDirectory}/Library/Logs/yabai/yabai.out.log";
      example = "/Users/noib3/Library/Logs/yabai/yabai.out.log";
      description = "Absolute path to log all stdout output.";
    };

    config = mkOption {
      type = types.attrs;
      default = { };
      description = "Key/value pairs to pass to yabai's config domain.";
    };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      description = "Extra commands to append to yabai's config file.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.yabai" pkgs lib.platforms.darwin)
    ];

    home.packages = [ cfg.package ];

    launchd.agents.yabai = {
      enable = true;
      config = {
        ProgramArguments = [
          (getExe cfg.package)
        ]
        ++ optionals (cfg.config != { } || cfg.extraConfig != "") [
          "-c"
          "${configFile}"
        ];
        ProcessType = "Interactive";
        KeepAlive = true;
        RunAtLoad = true;
        StandardErrorPath = cfg.errorLogFile;
        StandardOutPath = cfg.outLogFile;
        EnvironmentVariables = {
          PATH = "${config.home.profileDirectory}/bin:/run/current-system/sw/bin:/usr/bin:/bin:/usr/sbin:/sbin";
        };
      };
    };
  };
}
