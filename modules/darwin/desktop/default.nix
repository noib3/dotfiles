{
  config,
  pkgs,
  lib,
  ...
}:

with lib;
let
  cfg = config.modules.desktop;
in
{
  options.modules.desktop = {
    enable = mkEnableOption "Desktop config";
    hostName = mkOption {
      type = types.str;
      example = "macbook-pro";
      description = "The hostname of the machine";
    };
  };

  config = mkIf cfg.enable {
    # Workaround for https://github.com/nix-darwin/nix-darwin/issues/943.
    # nix-darwin doesn't add the XDG profile path to PATH when
    # `use-xdg-base-directories` is enabled.
    environment.profiles = mkOrder 700 [
      "\${XDG_STATE_HOME:-$HOME/.local/state}/nix/profile"
    ];

    environment.systemPackages = with pkgs; [
      home-manager
      neovim
    ];

    modules = {
      fish.enable = true;
      yabai.enable = true;
    };

    networking = with cfg; {
      computerName = hostName;
      hostName = hostName;
      localHostName = hostName;
    };

    nix = {
      linux-builder.enable = true;

      settings = {
        experimental-features = [
          "flakes"
          "nix-command"
          "pipe-operators"
        ];
        trusted-users = [
          "root"
          config.system.primaryUser
        ];
        use-xdg-base-directories = true;
        warn-dirty = false;
      };
    };

    system.stateVersion = 5;
  };
}
