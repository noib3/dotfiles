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

  bun_1_3_13 = pkgs.bun.overrideAttrs (_: rec {
    version = "1.3.13";
    src =
      {
        aarch64-darwin = pkgs.fetchurl {
          url = "https://github.com/oven-sh/bun/releases/download/bun-v${version}/bun-darwin-aarch64.zip";
          hash = "sha256-VGfj9l26Umuf6pjwzOBO+vwMY+Fpcz7Ce4dqOtMtoZA=";
        };
        aarch64-linux = pkgs.fetchurl {
          url = "https://github.com/oven-sh/bun/releases/download/bun-v${version}/bun-linux-aarch64.zip";
          hash = "sha256-cLrkGzkIsKEg4eWMXIrzDnSvrjuNEbDT/djnh937SyI=";
        };
        x86_64-darwin = pkgs.fetchurl {
          url = "https://github.com/oven-sh/bun/releases/download/bun-v${version}/bun-darwin-x64-baseline.zip";
          hash = "sha256-qYumpIDyL9qbNDYmuQak4mqlNhi/hdK8WSjs8rpF8O0=";
        };
        x86_64-linux = pkgs.fetchurl {
          url = "https://github.com/oven-sh/bun/releases/download/bun-v${version}/bun-linux-x64.zip";
          hash = "sha256-ecB3H6i5LDOq5B4VoODTB+qZ0OLwAxfHHGxTI3p44lo=";
        };
      }
      .${system};
  });

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
        patches = (old.patches or [ ]) ++ [
          ./patches/anthropic-provider-label.patch
          ./patches/cursor-style-and-blink.patch
          ./patches/fix-repeated-json-migration-check.patch
          ./patches/multi-account-profiles.patch
          ./patches/storage-static-helpers.patch
          ./patches/usage-tracking.patch
          ./patches/usage-profiles.patch
        ];
        postConfigure = (old.postConfigure or "") + ''
          if [ -e node_modules/.bun/node_modules/prettier ] && [ ! -e node_modules/prettier ]; then
            chmod u+w node_modules
            ln -s .bun/node_modules/prettier node_modules/prettier
          fi
        '';
        nativeBuildInputs =
          (lib.filter (pkg: lib.getName pkg != "bun") (old.nativeBuildInputs or [ ]))
          ++ [ bun_1_3_13 ]
          ++ lib.optionals (isDarwin && isx86_64) [ pkgs.sysctl ];
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
      };
      tui = {
        cursor_blink = false;
        cursor_style = "line";
        scroll_acceleration.enabled = true;
        theme = "system";
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
      };
  };
}
