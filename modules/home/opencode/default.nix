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

  inherit (pkgs.stdenv.hostPlatform) system isDarwin isx86_64;

  bun2nix = inputs.bun2nix.packages.${system}.default;

  opencodeAnthropicAuthBunNix =
    pkgs.runCommand "opencode-anthropic-auth-bun.nix"
      { nativeBuildInputs = [ bun2nix ]; }
      ''
        bun2nix \
          --lock-file ${inputs.opencode-anthropic-auth}/bun.lock \
          --output-file $out
      '';

  opencodeAnthropicAuth = pkgs.stdenvNoCC.mkDerivation {
    pname = "opencode-anthropic-auth";
    version = "0.1.0";
    src = inputs.opencode-anthropic-auth;
    nativeBuildInputs = [
      bun2nix.hook
      pkgs.nodejs
    ];
    bunDeps = bun2nix.fetchBunDeps {
      bunNix = opencodeAnthropicAuthBunNix;
    };
    dontRunLifecycleScripts = true;
    postPatch = ''
      substituteInPlace tsconfig.build.json \
        --replace-fail '"types": ["bun-types"]' '"types": ["bun"]'
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
          outputHash =
            {
              aarch64-darwin = "sha256-vN0sXYs7pLtpq7U9SorR2z6st/wMfHA3dybOnwIh1pU=";
              aarch64-linux = lib.fakeHash;
              x86_64-darwin = "sha256-P8fgyBcZJmY5VbNxNer/EL4r/F28dNxaqheaqNZH488=";
              x86_64-linux = lib.fakeHash;
            }
            .${system};
        };
        patches = (old.patches or [ ]) ++ [
          ./patches/anthropic-provider-label.patch
          ./patches/cursor-style-and-blink.patch
          ./patches/fix-repeated-json-migration-check.patch
          ./patches/multi-account-profiles.patch
          ./patches/usage-tracking.patch
          ./patches/usage-profiles.patch
        ];
        nativeBuildInputs =
          (old.nativeBuildInputs or [ ])
          ++ lib.optionals (isDarwin && isx86_64) [
            pkgs.sysctl
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
        autoupdate = "notify";
        plugin = [
          "file://${opencodeAnthropicAuth}"
        ];
        permission = {
          bash = {
            "home-manager switch*" = "ask";
            "nix build*" = "ask";
          };
          edit = {
            "*" = "allow";
            "*.env" = "deny";
            "*.env.*" = "deny";
          };
          external_directory = {
            "/**" = "allow";
          };
          read = {
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
