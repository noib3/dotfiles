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
        node_modules = old.node_modules.overrideAttrs {
          installPhase = ''
            runHook preInstall
            mkdir -p $out
            find . -path './node_modules/.bun' -prune -o -type d -name node_modules -exec cp -R --parents {} $out \;
            runHook postInstall
          '';
          outputHash = "sha256-vN0sXYs7pLtpq7U9SorR2z6st/wMfHA3dybOnwIh1pU=";
        };
        patches = (old.patches or [ ]) ++ [
          ./patches/anthropic-provider-label.patch
          ./patches/cursor-style-and-blink.patch
          ./patches/fix-repeated-json-migration-check.patch
          ./patches/multi-account-profiles.patch
          ./patches/usage-tracking.patch
          ./patches/usage-profiles.patch
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
