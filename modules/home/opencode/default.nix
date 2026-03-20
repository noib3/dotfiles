{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

with lib;
let
  cfg = config.modules.opencode;

  opencodeAnthropicAuthDeps = pkgs.stdenvNoCC.mkDerivation {
    pname = "opencode-anthropic-auth-deps";
    version = "0.1.0";
    src = inputs.opencode-anthropic-auth;
    nativeBuildInputs = [ pkgs.bun ];
    buildPhase = ''
      bun install --frozen-lockfile --no-progress --ignore-scripts --no-cache
      rm -rf node_modules/.cache
    '';
    installPhase = ''
      mkdir -p $out
      cp -r node_modules $out/
    '';
    outputHashAlgo = "sha256";
    outputHashMode = "recursive";
    outputHash = "sha256-ik8TVMjmjQgBCF/wjukBx0BrEp4rNkMl200jCZL2HDQ=";
  };

  opencodeAnthropicAuth = pkgs.stdenvNoCC.mkDerivation {
    pname = "opencode-anthropic-auth";
    version = "0.1.0";
    src = inputs.opencode-anthropic-auth;
    nativeBuildInputs = [
      pkgs.bun
      pkgs.nodejs
    ];
    configurePhase = ''
      cp -r ${opencodeAnthropicAuthDeps}/node_modules .
    '';
    buildPhase = ''
      bun run build
    '';
    installPhase = ''
      mkdir -p $out
      cp -r dist package.json node_modules $out/
    '';
  };

  opencodePackage =
    (inputs.opencode.packages.${pkgs.stdenv.system}.default).overrideAttrs
      (old: {
        # Workaround for https://github.com/anomalyco/opencode/issues/18227
        node_modules = old.node_modules.overrideAttrs {
          outputHash = "sha256-kZGUAE0fxFkFYrarWLQ6e40r5ZAF+GkRF2oZM8/erOM=";
        };
        patches = (old.patches or [ ]) ++ [
          ./patches/anthropic-provider-label.patch
          ./patches/cursor-style-and-blink.patch
        ];
      });
in
{
  options.modules.opencode = {
    enable = mkEnableOption "OpenCode";
  };

  config = mkIf cfg.enable {
    programs.opencode = {
      enable = true;
      package = opencodePackage;
      settings = {
        plugin = [
          "file://${opencodeAnthropicAuth}"
        ];
        permission = {
          external_directory = {
            "/**" = "allow";
          };
          read = {
            "*" = "allow";
            "*.env" = "deny";
            "*.env.*" = "deny";
          };
          edit = {
            "*" = "allow";
            "*.env" = "deny";
            "*.env.*" = "deny";
          };
        };
        tui = {
          cursor_blink = false;
          cursor_style = "line";
          scroll_acceleration.enabled = true;
          theme = "system";
        };
      };
    };

    xdg.configFile =
      let
        jsonFormat = pkgs.formats.json { };

        inherit (config.programs.opencode) settings;

        opencodeSettings = removeAttrs settings [
          "theme"
          "keybinds"
          "tui"
        ];

        tuiSettings =
          (optionalAttrs (settings ? theme) { theme = settings.theme; })
          // (optionalAttrs (settings ? keybinds) { keybinds = settings.keybinds; })
          // (settings.tui or { });
      in
      {
        "opencode/opencode.json" = mkForce {
          source = jsonFormat.generate "opencode.json" (
            {
              "$schema" = "https://opencode.ai/config.json";
            }
            // opencodeSettings
          );
        };

        "opencode/tui.json" = {
          force = true;
          source = jsonFormat.generate "opencode-tui.json" (
            {
              "$schema" = "https://opencode.ai/tui.json";
            }
            // tuiSettings
          );
        };
      };
  };
}
