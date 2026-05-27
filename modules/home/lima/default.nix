{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.modules.lima;

  guestSystem =
    builtins.replaceStrings [ "darwin" ] [ "linux" ]
      config.machines.current.system;

  headlessMachine = lib.evalModules {
    specialArgs = { inherit inputs; };
    modules = [
      ../../lib/headless-nixos-machine
      {
        headlessNixosMachine = {
          name = cfg.machineName;
          system = guestSystem;
          username = config.home.username;
          colorscheme = config.modules.colorschemes.name;
          machines = removeAttrs config.machines [ "current" ];
          extraConfig = import ./nixos-module.nix {
            enableGhosttyTerminfo = config.modules.ghostty.enable;
          };
        };
      }
    ];
  };

  limaArch = builtins.elemAt (lib.splitString "-" guestSystem) 0;
  limaHome = "${config.xdg.stateHome}/lima";
  limaPackage = pkgs.lima.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      substituteInPlace pkg/hostagent/requirements.go \
        --replace-fail '#!/bin/bash -c \"$(printf' '#!/bin/sh -c \"$(printf'
    '';
  });
  nixosImage = headlessMachine.config.nixosConfiguration.config.formats.qcow;
in
{
  options.modules.lima = {
    enable = mkEnableOption "Lima";

    machineName = mkOption {
      type = types.singleLineStr;
      default = "lima";
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
  };

  config = mkIf cfg.enable {
    home = {
      packages = [
        # Patch Lima to use #!/bin/sh instead of #!/bin/bash.
        limaPackage
      ];
      sessionVariables.LIMA_HOME = limaHome;
    };

    home.activation.resetLimaOnImageChange =
      let
        marker = "${limaHome}/_hm/${cfg.instanceName}.image";
        markerDir = "${limaHome}/_hm";
        instanceDir = "${limaHome}/${cfg.instanceName}";
        limactl = lib.getExe' limaPackage "limactl";
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
            if [[ "$status" == "Running" ]]; then
              run ${limactl} stop ${escapeShellArg cfg.instanceName}
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
          name: "${config.home.username}"
          home: "/home/${config.home.username}"
          shell: "/run/current-system/sw/bin/fish"
        mountType: "virtiofs"
        images:
        - location: "${nixosImage}"
          arch: "${limaArch}"

        cpus: ${toString cfg.cpus}
        memory: "${cfg.memory}"
        disk: "${cfg.disk}"

        mounts:
        - location: "${config.xdg.cacheHome}/lima/shared"
          mountPoint: "/mnt/lima"
          writable: true

        containerd:
          system: false
          user: false
      '';
    };

    xdg.cacheFile."lima/shared/.keep".text = "";
  };
}
