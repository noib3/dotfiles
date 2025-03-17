{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.modules.terminfo;

  terminals = {
    alacritty = {
      enabled = config.programs.alacritty.enable;
      terminfoName = "alacritty";
      terminfoSrc = "${pkgs.alacritty.terminfo}/share/terminfo";
    };
  };

  enabledTerminal =
    terminals
    |> filterAttrs (_: term: term.enabled)
    |> attrValues
    |> (terms: if terms == [ ] then null else head terms);
in
{
  options.modules.terminfo = {
    enable = mkEnableOption "Terminfo configuration";
  };

  config = mkIf (cfg.enable && enabledTerminal != null) (
    let
      terminfo_dir = "${config.xdg.dataHome}/terminfo";
    in
    {
      home.sessionVariables = {
        TERM = enabledTerminal.terminfoName;
        TERMINFO = terminfo_dir;
      };

      home.activation = {
        copyTerminfo = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          $DRY_RUN_CMD mkdir -p "${terminfo_dir}"
          $DRY_RUN_CMD cp -r "${enabledTerminal.terminfoSrc}/"* "${terminfo_dir}"
        '';
      };
    }
  );
}
