{
  pkgs,
  lib,
  system,
  username,
  hostConfig,
  ...
}:

{
  imports = [
    ../.
    ../../lib/machines
  ];

  home.username = username;
  machines = hostConfig.machines // {
    current = {
      inherit system;
      name = hostConfig.modules.lima.machineName;
      isHeadless = true;
    };
  };
  modules.colorschemes.${hostConfig.modules.colorschemes.name}.enable = true;
  modules.terminals.ghostty = lib.mkIf hostConfig.modules.ghostty.enable (
    let
      ghosttyTerminfo = pkgs.runCommandLocal "ghostty-terminfo" { } ''
        mkdir -p "$out"
        cp -r "${pkgs.ghostty.terminfo}/share/terminfo/." "$out"
      '';
    in
    {
      package = ghosttyTerminfo;
      launchCommand = "false";
      terminfo.xterm-ghostty = ghosttyTerminfo;
    }
  );
}
