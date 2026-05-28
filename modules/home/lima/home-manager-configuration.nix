{
  config,
  pkgs,
  lib,
  system,
  username,
  hostConfig,
  ...
}:

let
  limaFlakeConfigUri = "${config.lib.mine.dotfilesDir}#homeConfigurations.${builtins.toJSON hostConfig.machines.current.homeConfigurationName}.config.modules.lima.homeConfiguration";
in
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
  modules.fish = {
    homeManagerNewsAbbreviation = "FLAKE_CONFIG_URI=${lib.escapeShellArg limaFlakeConfigUri} home-manager news";
    homeManagerSwitchAbbreviation = "FLAKE_CONFIG_URI=${lib.escapeShellArg limaFlakeConfigUri} home-manager switch";
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
