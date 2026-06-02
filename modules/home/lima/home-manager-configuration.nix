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

  hostModelProvider = hostConfig.modules.codex.modelProvider;
  shouldProxyModelProvider = hostModelProvider ? base_url;
  hostModelProviderUrlParts =
    if !shouldProxyModelProvider then
      null
    else
      builtins.match "^(http)://([^/:]+)(:([0-9]+))?(/.*)?$" hostModelProvider.base_url;
  hostModelProviderEndpoint =
    if !shouldProxyModelProvider then
      null
    else if hostModelProviderUrlParts == null then
      throw "The Lima Codex proxy can only forward HTTP model provider URLs."
    else
      let
        rawHost = builtins.elemAt hostModelProviderUrlParts 1;
        rawPort = builtins.elemAt hostModelProviderUrlParts 3;
        rawPath = builtins.elemAt hostModelProviderUrlParts 4;
      in
      {
        host =
          if
            builtins.elem rawHost [
              "0.0.0.0"
              "127.0.0.1"
              "localhost"
            ]
          then
            "host.lima.internal"
          else
            rawHost;
        port = if rawPort == null then "80" else rawPort;
        path = if rawPath == null then "" else rawPath;
      };

  modelProviderProxyHost = "127.0.0.1";
  modelProviderProxyPort = 2455;
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
  modules.codex = {
    codexLb.enable = false;
    modelProviders = lib.mkIf shouldProxyModelProvider {
      host-proxy = hostModelProvider // {
        active = true;
        base_url = "http://${modelProviderProxyHost}:${toString modelProviderProxyPort}${hostModelProviderEndpoint.path}";
      };
    };
  };
  modules.colorschemes.${hostConfig.modules.colorschemes.name}.enable = true;
  modules.terminfo.entries = hostConfig.modules.terminfo.entries;
  systemd.user.services.codex-provider-proxy = lib.mkIf shouldProxyModelProvider {
    Unit = {
      Description = "Codex provider proxy";
      After = [ "network-online.target" ];
    };

    Service = {
      ExecStart = "${lib.getExe pkgs.socat} TCP-LISTEN:${toString modelProviderProxyPort},bind=${modelProviderProxyHost},reuseaddr,fork TCP:${hostModelProviderEndpoint.host}:${hostModelProviderEndpoint.port}";
      Restart = "on-failure";
      RestartSec = "5s";
    };

    Install.WantedBy = [ "default.target" ];
  };
}
