{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

with lib;
let
  inherit (pkgs.stdenv) isDarwin isLinux;

  cfg = config.modules.codex;

  codexHome = "${config.xdg.configHome}/codex";

  codexConfig = {
    model = "gpt-5.5";
    model_reasoning_effort = "xhigh";
    model_provider = "codex-lb";

    model_providers."codex-lb" = {
      name = "OpenAI";
      base_url = "http://${codexLbHost}:${toString codexLbPort}/backend-api/codex";
      wire_api = "responses";
      supports_websockets = true;
    };

    projects =
      [
        "${config.home.homeDirectory}/Dev/neovim"
        "${config.home.homeDirectory}/Dev/snowstorm/snowstorm"
        "${config.lib.mine.documentsDir}/dotfiles"
      ]
      |> map (proj: {
        name = proj;
        value = {
          trust_level = "trusted";
        };
      })
      |> builtins.listToAttrs;

    tui.model_availability_nux."gpt-5.5" = 4;
  };

  codexLb = pkgs.callPackage ./codex-lb.nix { };
  codexLbHost = "127.0.0.1";
  codexLbPort = 2455;
  codexLbDataDir = "${config.xdg.stateHome}/codex-lb";
  codexLbLogDir = "${codexLbDataDir}/log";
  codexLbEnvironment = {
    CODEX_LB_DATABASE_URL = "sqlite+aiosqlite:///${codexLbDataDir}/store.db";
    CODEX_LB_ENCRYPTION_KEY_FILE = "${codexLbDataDir}/encryption.key";
  };
in
{
  options.modules.codex = {
    enable = mkEnableOption "Codex";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      home = {
        packages = [
          inputs.codex-cli-nix.packages.${pkgs.stdenv.system}.default
        ];

        sessionVariables.CODEX_HOME = codexHome;

        # When setting a custom CODEX_HOME, Codex will refuse to start if the
        # directory doesn't exist instead of creating it automatically, so
        # let's make sure it exists.
        activation.createCodexState = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          run mkdir -p \
            ${escapeShellArg codexHome} \
            ${escapeShellArg codexLbDataDir} \
            ${escapeShellArg codexLbLogDir}
        '';
      };

      xdg.configFile."codex/config.toml" = {
        source = (pkgs.formats.toml { }).generate "codex-config.toml" codexConfig;
        force = true;
      };
    }
    (mkIf isDarwin {
      launchd.agents.codex-lb = {
        enable = true;
        config = {
          ProgramArguments = [
            (lib.getExe codexLb)
            "--host"
            codexLbHost
            "--port"
            (toString codexLbPort)
          ];
          RunAtLoad = true;
          KeepAlive = {
            SuccessfulExit = false;
          };
          WorkingDirectory = codexLbDataDir;
          EnvironmentVariables = codexLbEnvironment;
          StandardOutPath = "${codexLbLogDir}/codex-lb.out.log";
          StandardErrorPath = "${codexLbLogDir}/codex-lb.err.log";
        };
      };
    })
    (mkIf isLinux {
      systemd.user.services.codex-lb = {
        Unit = {
          Description = "Codex load balancer";
          After = [ "network-online.target" ];
        };

        Service = {
          ExecStart = "${lib.getExe codexLb} --host ${codexLbHost} --port ${toString codexLbPort}";
          Restart = "on-failure";
          RestartSec = "5s";
          WorkingDirectory = codexLbDataDir;
          Environment = mapAttrsToList (
            name: value: "${name}=${value}"
          ) codexLbEnvironment;
        };

        Install.WantedBy = [ "default.target" ];
      };
    })
  ]);
}
