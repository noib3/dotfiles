{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  nix = pkgs.nixVersions.latest;

  nixWrapper = pkgs.writeShellApplication {
    name = "nix";
    runtimeInputs = [
      nix
      pkgs.jq
    ];
    runtimeEnv = {
      DOCUMENTS = config.lib.mine.documentsDir;
      XDG_STATE_HOME = config.xdg.stateHome;
    };
    text = ''
      ${builtins.readFile ../scripts/project-hash-utils.sh}
      ${builtins.readFile ./nix-wrapper.sh}
    '';
    # A lower priority makes our wrapper have precendece over the real Nix
    # binary.
    meta.priority = (nix.meta.priority or 5) - 1;
  };
in
{
  imports = [
    inputs.nix-jettison.homeManagerModules.default
  ];

  config = {
    home.packages = with pkgs; [
      # We add the original Nix package because it contains the legacy nix-*
      # commands used by home-manager.
      nix
      nixWrapper
      nixd
      nixfmt
    ];

    nix = {
      package = nix;
      plugins.jettison.enable = false;
      settings = {
        experimental-features = [
          "flakes"
          "nix-command"
          "pipe-operators"
        ];
        use-xdg-base-directories = true;
        warn-dirty = false;
      };
    };

    # Make `nix develop` and `nix shell` use fish instead of bash.
    programs.fish.interactiveShellInit = lib.mkIf config.programs.fish.enable ''
      function nix --description "Reproducible and declarative configuration management"
          ${pkgs.nix-your-shell}/bin/nix-your-shell fish nix -- $argv
      end
    '';

    programs.nix-index.enable = true;

    launchd.agents.nix-collect-garbage = lib.mkIf pkgs.stdenv.isDarwin {
      enable = true;
      config = {
        ProgramArguments = [
          (lib.getExe' nix "nix-collect-garbage")
          "-d"
        ];
        StartCalendarInterval = [
          {
            Hour = 4;
            Minute = 0;
          }
        ];
      };
    };
  };
}
