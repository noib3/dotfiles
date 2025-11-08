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
          run mkdir -p "${terminfo_dir}"
          run cp -r "${enabledTerminal.terminfoSrc}/"* "${terminfo_dir}"
          # The files we copied from the Nix store are read-only, so make them
          # writable or we won't be able to update them the next time the
          # activation script is run.
          run chmod -R +w "${terminfo_dir}"
        '';
      };
    }
  );
}
