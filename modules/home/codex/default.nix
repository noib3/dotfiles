{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  inherit (lib) mkOption types;
  inherit (pkgs.stdenv) isDarwin isLinux;

  cfg = config.modules.codex;

  tomlFormat = pkgs.formats.toml { };

  moduleProviderType = types.submoduleWith {
    modules = [
      {
        freeformType = tomlFormat.type;
        options.active = mkOption {
          type = types.bool;
          default = false;
          description = "Whether Codex should use this model provider.";
        };
      }
    ];
    description = ''
      A model provider configuration. Grep for 'model_providers' in
      https://developers.openai.com/codex/config-reference for the full
      config schema.
    '';
  };

  activeModelProviders =
    cfg.modelProviders |> lib.filterAttrs (_: provider: provider.active);

  codexConfig = {
    model = "gpt-5.5";
    model_reasoning_effort = "high";
    plan_mode_reasoning_effort = "high";
    model_provider = activeModelProviders |> builtins.attrNames |> builtins.head;
    approval_policy = "never";
    sandbox_mode = "danger-full-access";

    model_providers =
      cfg.modelProviders
      |> builtins.mapAttrs (_: provider: removeAttrs provider [ "active" ]);

    tui.model_availability_nux."gpt-5.5" = 4;
  };

  codexLb = pkgs.callPackage ./codex-lb.nix { inherit inputs; };
  codexLbDataDir = "${config.xdg.stateHome}/codex-lb";
  codexLbLogDir = "${codexLbDataDir}/log";
  codexLbEnvironment = {
    CODEX_LB_DATABASE_URL = "sqlite+aiosqlite:///${codexLbDataDir}/store.db";
    CODEX_LB_ENCRYPTION_KEY_FILE = "${codexLbDataDir}/encryption.key";
  };
in
{
  options.modules.codex = {
    enable = lib.mkEnableOption "Codex";

    modelProviders = mkOption {
      type = types.attrsOf moduleProviderType;
      default = { };
      description = "The configured model providers.";
    };

    modelProvider = mkOption {
      type = moduleProviderType;
      default = activeModelProviders |> builtins.attrValues |> builtins.head;
      readOnly = true;
      description = "The active model provider";
    };

    codexLb = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Whether to configure codex-lb as the active Codex model provider and
          run the local codex-lb service.
        '';
      };

      host = mkOption {
        type = types.str;
        default = "127.0.0.1";
        description = "Host address for the local codex-lb endpoint.";
      };

      port = mkOption {
        type = types.port;
        default = 2455;
        description = "Port for the local codex-lb endpoint.";
      };
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        assertions = [
          {
            assertion =
              (activeModelProviders |> builtins.attrNames |> builtins.length) == 1;
            message = "Exactly one modules.codex.modelProviders entry must set active = true.";
          }
        ];

        home = {
          packages = [
            (pkgs.writeShellApplication {
              name = "codex";
              runtimeInputs = [
                pkgs.git
                inputs.codex-cli-nix.packages.${pkgs.stdenv.system}.default
              ];
              text = ''
                project=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null || pwd -P)
                project=''${project%/.git}
                project=''${project//\\/\\\\}
                project=''${project//\"/\\\"}
                exec codex -c "projects={\"$project\"={trust_level=\"trusted\"}}" "$@"
              '';
            })
          ];

          sessionVariables.CODEX_HOME = "${config.xdg.configHome}/codex";

          # When setting a custom CODEX_HOME, Codex will refuse to start if the
          # directory doesn't exist instead of creating it automatically, so
          # let's make sure it exists.
          activation.createCodexState = lib.hm.dag.entryAfter [ "writeBoundary" ] (
            ''
              run mkdir -p ${lib.escapeShellArg config.home.sessionVariables.CODEX_HOME}
            ''
            + lib.optionalString cfg.codexLb.enable ''
              run mkdir -p \
                ${lib.escapeShellArg codexLbDataDir} \
                ${lib.escapeShellArg codexLbLogDir}
            ''
          );
        };

        modules.codex.modelProviders = lib.mkMerge [
          (lib.mkIf cfg.codexLb.enable {
            codex-lb = {
              active = true;
              name = "OpenAI";
              base_url = "http://${cfg.codexLb.host}:${toString cfg.codexLb.port}/backend-api/codex";
              wire_api = "responses";
              supports_websockets = true;
            };
          })
          (lib.mkIf config.modules.cli-proxy-api.enable {
            cli-proxy-api = {
              active = false;
              name = "CLIProxyAPI";
              base_url = "${config.modules.cli-proxy-api.endpoint}/v1";
              experimental_bearer_token = config.modules.cli-proxy-api.apiKey;
              wire_api = "responses";
            };
          })
        ];

        xdg.configFile."codex/config.toml" = {
          source = tomlFormat.generate "codex-config.toml" codexConfig;
          force = true;
        };
      }
      (lib.mkIf (isDarwin && cfg.codexLb.enable) {
        launchd.agents.codex-lb = {
          enable = true;
          config = {
            ProgramArguments = [
              (lib.getExe codexLb)
              "--host"
              cfg.codexLb.host
              "--port"
              (toString cfg.codexLb.port)
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
      (lib.mkIf (isLinux && cfg.codexLb.enable) {
        systemd.user.services.codex-lb = {
          Unit = {
            Description = "Codex load balancer";
            After = [ "network-online.target" ];
          };

          Service = {
            ExecStart = "${lib.getExe codexLb} --host ${cfg.codexLb.host} --port ${toString cfg.codexLb.port}";
            Restart = "on-failure";
            RestartSec = "5s";
            WorkingDirectory = codexLbDataDir;
            Environment = lib.mapAttrsToList (
              name: value: "${name}=${value}"
            ) codexLbEnvironment;
          };

          Install.WantedBy = [ "default.target" ];
        };
      })
    ]
  );
}
