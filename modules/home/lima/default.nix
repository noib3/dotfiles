{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.lima;

  inherit (lib) escapeShellArg mkOption types;
  inherit (config.home) username;

  guestSystem =
    builtins.replaceStrings [ "darwin" ] [ "linux" ]
      config.machines.current.system;

  headlessMachine = lib.evalModules {
    specialArgs = { inherit inputs; };
    modules = [
      ../../lib/headless-nixos-machine
      {
        name = cfg.machineName;
        system = guestSystem;
        inherit username;
        machines = removeAttrs config.machines [ "current" ];
        extraConfig = import ./nixos-configuration.nix;
      }
    ];
  };

  nixosImage = headlessMachine.config.nixosConfiguration.config.formats.qcow;

  limaArch = builtins.elemAt (lib.splitString "-" guestSystem) 0;
  limaHome = "${config.xdg.stateHome}/lima";
in
{
  options.modules.lima = {
    enable = lib.mkEnableOption "Lima";

    machineName = mkOption {
      type = types.singleLineStr;
      default = "${config.machines.current.hostName}-lima";
      description = "Name of the generated headless NixOS machine used as the Lima guest image.";
    };

    instanceName = mkOption {
      type = types.str;
      default = "nixos";
      description = "Name of the Lima NixOS instance.";
    };

    cpus = mkOption {
      type = types.ints.positive;
      default = 4;
      description = "Number of vCPUs assigned to the Lima NixOS instance.";
    };

    memory = mkOption {
      type = types.str;
      default = "8GiB";
      description = "Memory assigned to the Lima NixOS instance.";
    };

    disk = mkOption {
      type = types.str;
      default = "40GiB";
      description = "Disk size assigned to the Lima NixOS instance.";
    };

    homeConfiguration = mkOption {
      type = types.nullOr types.raw;
      readOnly = true;
      description = "Home Manager configuration for the Lima guest.";
      default = inputs.home-manager.lib.homeManagerConfiguration {
        pkgs = inputs.nixpkgs.legacyPackages.${guestSystem};
        modules = [ ./home-manager-configuration.nix ];
        extraSpecialArgs = {
          inherit inputs username;
          hostConfig = config;
          system = guestSystem;
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home = {
      packages = [
        pkgs.lima
      ];
      sessionVariables.LIMA_HOME = limaHome;
    };

    home.activation.resetLimaOnImageChange =
      let
        marker = "${limaHome}/_hm/${cfg.instanceName}.image";
        markerDir = "${limaHome}/_hm";
        instanceDir = "${limaHome}/${cfg.instanceName}";
        limactl = lib.getExe' pkgs.lima "limactl";
        recordImage = pkgs.writeShellScript "record-lima-${cfg.instanceName}-image" ''
          printf '%s\n' ${escapeShellArg (toString nixosImage)} > ${escapeShellArg marker}
        '';
      in
      lib.hm.dag.entryAfter [ "linkGeneration" ] ''
        export LIMA_HOME=${escapeShellArg limaHome}

        oldImage=
        if [[ -f ${escapeShellArg marker} ]]; then
          oldImage="$(<${escapeShellArg marker})"
        fi

        if [[ "$oldImage" != ${escapeShellArg (toString nixosImage)} ]]; then
          run mkdir -p ${escapeShellArg markerDir}

          if [[ -d ${escapeShellArg instanceDir} ]]; then
            status="$(${limactl} list --format '{{.Status}}' ${escapeShellArg cfg.instanceName} 2>/dev/null || true)"
            if [[ -n "$status" && "$status" != "Stopped" ]]; then
              run ${limactl} stop --force ${escapeShellArg cfg.instanceName}
            fi

            while IFS= read -r -d "" path; do
              run rm -rf "$path"
            done < <(find ${escapeShellArg instanceDir} -mindepth 1 -maxdepth 1 ! -name lima.yaml -print0)
          fi

          run ${recordImage}
        fi
      '';

    xdg.stateFile = {
      "lima/${cfg.instanceName}/lima.yaml".text = ''
        # Start with:
        #   limactl start ${cfg.instanceName}
        #
        # This boots the NixOS image from:
        #   modules.lima's generated headless NixOS machine
        vmType: vz
        arch: "${limaArch}"
        user:
          name: "${username}"
          home: "/home/${username}"
          shell: "/run/current-system/sw/bin/fish"
        ssh:
          forwardAgent: true
        mountType: "virtiofs"
        images:
        - location: "${nixosImage}"
          arch: "${limaArch}"

        cpus: ${toString cfg.cpus}
        memory: "${cfg.memory}"
        disk: "${cfg.disk}"

        mounts:
        - location: "${config.lib.mine.documentsDir}"
          mountPoint: "/home/${username}/Documents"
          writable: true

        portForwards:
        - guestIP: "0.0.0.0"
          guestPort: 5355
          proto: "any"
          ignore: true

        containerd:
          system: false
          user: false
      '';
    };
  };
}
