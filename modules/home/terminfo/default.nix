{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.modules.terminfo;
in
{
  options.modules.terminfo = {
    enable = mkEnableOption "Terminfo configuration";

    entries = mkOption {
      type = types.attrsOf (types.functionTo types.package);
      default = { };
      description = ''
        Terminfo source builders keyed by terminfo database name. Each value is
        called with the current Home Manager package set and should return a
        directory containing one or more terminfo directories.
      '';
    };

    directory = mkOption {
      type = types.singleLineStr;
      readOnly = true;
      default = "${config.xdg.dataHome}/terminfo";
      description = ''
        The $TERMINFO directory storing the configured terminfo entries
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = hasPrefix "${config.home.homeDirectory}/" cfg.directory;
        message = "modules.terminfo.directory must be under config.home.homeDirectory";
      }
    ];

    home.sessionVariables = {
      TERMINFO = cfg.directory;
    };

    home.file."terminfo" = {
      target = cfg.directory |> removePrefix "${config.home.homeDirectory}/";
      source = pkgs.runCommandLocal "terminfo-entries" { } (
        let
          terminfoEntries = cfg.entries |> mapAttrsToList (_: mkEntry: mkEntry pkgs);
        in
        ''
          mkdir -p "$out"
        ''
        + (concatMapStringsSep "\n" (
          entry: "cp -r \"${entry}/.\" \"$out\""
        ) terminfoEntries)
        # If there are no terminfo entries, add an empty file to ensure the
        # directory is still created.
        + (lib.optionalString (length terminfoEntries == 0) "touch $out/.keep")
      );
      recursive = true;
    };
  };
}
