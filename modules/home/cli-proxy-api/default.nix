{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) mkOption types;

  cfg = config.modules.cli-proxy-api;

  stateDir = "${config.xdg.stateHome}/cli-proxy-api";
  authDir = "${stateDir}/auth";
  configFile = "${config.xdg.configHome}/cli-proxy-api/config.yaml";

  cliProxyApiPackage =
    let
      version = "7.2.54";
      source =
        {
          aarch64-darwin = {
            artifact = "CLIProxyAPI_${version}_darwin_aarch64.tar.gz";
            hash = "sha256-7aNJ3aDzxXWUSnSfRLG2MRmmVNA3Bd8iiL2wcuk53Mw=";
          };
          x86_64-darwin = {
            artifact = "CLIProxyAPI_${version}_darwin_amd64.tar.gz";
            hash = "sha256-xc9Bvi/75gsQC1U/mSvGFGZau616dxm6vz6/njKcZRs=";
          };
          aarch64-linux = {
            artifact = "CLIProxyAPI_${version}_linux_aarch64.tar.gz";
            hash = "sha256-uj/sBrDpi2mAV1rxvEMBJv1JhvZ3Ex69d0TB8vDpfGg=";
          };
          x86_64-linux = {
            artifact = "CLIProxyAPI_${version}_linux_amd64.tar.gz";
            hash = "sha256-OkLshkaEeRDHflgUnMXWLKzYM3LwJhlGTZBEKHRsiWE=";
          };
        }.${pkgs.stdenv.hostPlatform.system};
    in
    pkgs.stdenvNoCC.mkDerivation {
      pname = "cli-proxy-api";
      inherit version;
      src = pkgs.fetchurl {
        url = "https://github.com/router-for-me/CLIProxyAPI/releases/download/v${version}/${source.artifact}";
        inherit (source) hash;
      };
      sourceRoot = ".";
      dontConfigure = true;
      dontBuild = true;
      installPhase = ''
        runHook preInstall
        install -Dm755 cli-proxy-api "$out/bin/CLIProxyAPI"
        runHook postInstall
      '';
      meta.mainProgram = "CLIProxyAPI";
    };
in
{
  options.modules.cli-proxy-api = {
    enable = lib.mkEnableOption "CLIProxyAPI";

    package = mkOption {
      type = types.package;
      default = cliProxyApiPackage;
      description = "The packaged CLIProxyAPI release.";
    };

    apiKey = mkOption {
      type = types.singleLineStr;
      default = "sk-cli-proxy-api-local";
      readOnly = true;
      description = "Bearer token accepted by CLIProxyAPI's model API endpoints.";
    };

    host = mkOption {
      type = types.str;
      default = "127.0.0.1";
      readOnly = true;
      description = "Host address for the local CLIProxyAPI endpoint.";
    };

    port = mkOption {
      type = types.port;
      default = 8317;
      readOnly = true;
      description = "Port for the local CLIProxyAPI endpoint.";
    };

    endpoint = mkOption {
      type = types.str;
      default = "http://${cfg.host}:${toString cfg.port}";
      readOnly = true;
      description = "Base URL for the local CLIProxyAPI endpoint.";
    };

    settings = mkOption {
      type = types.attrs;
      default = {
        api-keys = [ cfg.apiKey ];
        auth-dir = authDir;
        debug = false;
        host = cfg.host;
        port = cfg.port;
        logging-to-file = true;
        redis-usage-queue-retention-seconds = 3600;
        remote-management = {
          allow-remote = false;
          secret-key = "password";
          panel-github-repository = "https://github.com/router-for-me/Cli-Proxy-API-Management-Center";
        };
        routing = {
          strategy = "round-robin";
          session-affinity = false;
          session-affinity-ttl = "1h";
        };
        usage-statistics-enabled = true;
      };
      readOnly = true;
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        home.packages = [ cfg.package ];
        xdg.configFile."cli-proxy-api/config.yaml".source =
          (pkgs.formats.yaml { }).generate "cli-proxy-api-config.yaml" cfg.settings;
      }
      (lib.mkIf pkgs.stdenv.isDarwin {
        launchd.agents.cli-proxy-api = {
          enable = true;
          config = {
            ProgramArguments = [
              (lib.getExe cfg.package)
              "-config"
              configFile
            ];
            RunAtLoad = true;
            KeepAlive = {
              SuccessfulExit = false;
            };
          };
        };
      })
      (lib.mkIf pkgs.stdenv.isLinux {
        systemd.user.services.cli-proxy-api = {
          Unit = {
            Description = "CLIProxyAPI";
            After = [ "network-online.target" ];
          };

          Service = {
            ExecStart = "${lib.getExe cfg.package} -config ${configFile}";
            Restart = "on-failure";
            RestartSec = "5s";
          };

          Install.WantedBy = [ "default.target" ];
        };
      })
    ]
  );
}
