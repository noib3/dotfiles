{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.modules.terminfo;

  enabledTerminalTerminfoNames =
    if config.modules.terminals.enabled == null then
      [ ]
    else
      config.modules.terminals.enabled.terminfo |> attrNames;

  selectedTerm =
    if cfg.term != null then
      cfg.term
    else if enabledTerminalTerminfoNames == [ ] then
      null
    else
      head enabledTerminalTerminfoNames;

  terminfoEntries =
    removeAttrs config.modules.terminals [
      "enabled"
      "_module"
    ]
    |> attrValues
    |> concatMap (terminal: attrValues terminal.terminfo);
in
{
  options.modules.terminfo = {
    enable = mkEnableOption "Terminfo configuration";

    term = mkOption {
      type = types.nullOr types.singleLineStr;
      default = null;
      example = "xterm-ghostty";
      description = "The terminfo entry name to export as $TERM";
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
        assertion = cfg.term != null || length enabledTerminalTerminfoNames <= 1;
        message = ''
          Couldn't determine what to set $TERM to because the enabled terminal
          has multiple terminfo entries. Set modules.terminfo.term explicitly.
        '';
      }
      {
        assertion = hasPrefix "${config.home.homeDirectory}/" cfg.directory;
        message = "modules.terminfo.directory must be under config.home.homeDirectory";
      }
    ];

    home.sessionVariables = {
      TERMINFO = cfg.directory;
    }
    // optionalAttrs (selectedTerm != null) {
      TERM = selectedTerm;
    };

    home.file."terminfo" = {
      target = cfg.directory |> removePrefix "${config.home.homeDirectory}/";
      source = pkgs.runCommandLocal "terminfo-entries" { } (
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
