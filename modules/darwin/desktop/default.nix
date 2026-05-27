{
  config,
  pkgs,
  lib,
  ...
}:

with lib;
let
  cfg = config.modules.desktop;
  inherit (config.machines.current) cores;

  linuxBuilderQemu =
    pkgs.darwin.linux-builder.nixosConfig.virtualisation.qemu.package;

  # nixpkgs uses gic-version=2 for aarch64-darwin QEMU, which caps ARM virt
  # guests at 8 vCPUs. We override it to pass gic-version=max so the Linux
  # builder can use every host core.
  linuxBuilderQemuGicMax =
    (pkgs.symlinkJoin {
      name = "${linuxBuilderQemu.name}-gic-max";
      paths = [ linuxBuilderQemu ];
      postBuild = ''
        rm -f "$out/bin/qemu-system-aarch64"
        cat > "$out/bin/qemu-system-aarch64" <<'EOF'
        #!${pkgs.bash}/bin/bash
        args=()
        for arg in "$@"; do
          args+=("''${arg//gic-version=2/gic-version=max}")
        done
        exec ${linuxBuilderQemu}/bin/qemu-system-aarch64 "''${args[@]}"
        EOF
        chmod +x "$out/bin/qemu-system-aarch64"
      '';
    })
    // {
      inherit (linuxBuilderQemu) stdenv;
    };

  linuxBuilderPackage = pkgs.darwin.linux-builder.override {
    modules = [
      {
        virtualisation.darwin-builder.diskSize = 80 * 1024;
      }
      (lib.optionalAttrs (cores != null) {
        virtualisation.cores = cores;
        virtualisation.qemu.package = linuxBuilderQemuGicMax;
      })
    ];
  };
in
{
  options.modules.desktop = {
    enable = mkEnableOption "Desktop config";
  };

  config = mkIf cfg.enable {
    # Workaround for https://github.com/nix-darwin/nix-darwin/issues/943.
    # nix-darwin doesn't add the XDG profile path to PATH when
    # `use-xdg-base-directories` is enabled.
    environment.profiles = mkOrder 700 [
      "\${XDG_STATE_HOME:-$HOME/.local/state}/nix/profile"
    ];

    environment.systemPackages = with pkgs; [
      brewCasks.proton-drive
      brewCasks.protonvpn
      home-manager
      neovim
    ];

    modules = {
      fish.enable = true;
    };

    networking = rec {
      inherit (config.machines.current) hostName;
      computerName = hostName;
      localHostName = hostName;
    };

    nix = {
      linux-builder = {
        enable = true;
        package = linuxBuilderPackage;
      };

      settings = {
        experimental-features = [
          "flakes"
          "nix-command"
          "pipe-operators"
        ];
        keep-outputs = true;
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
