{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:

{
  system.build.qcow = lib.mkForce (
    import "${modulesPath}/../lib/make-disk-image.nix" {
      inherit lib config pkgs;
      diskSize = 40 * 1024;
      format = "qcow2";
      partitionTableType = "hybrid";
    }
  );

  systemd.services = {
    lima-mounts = {
      description = "Mount Lima shared directories";
      after = [ "mnt-lima\\x2dcidata.mount" ];
      wants = [ "mnt-lima\\x2dcidata.mount" ];
      before = [ "lima-guestagent.service" ];
      wantedBy = [ "multi-user.target" ];
      unitConfig.ConditionPathExists = "/mnt/lima-cidata/user-data";
      path = with pkgs; [
        coreutils
        gnused
        util-linux
      ];
      script = ''
        set -eu

        mount_line="$(sed -n 's/^- \[\([^,]*\), \/mnt\/lima, virtiofs, "\([^"]*\)",.*/\1 \2/p' /mnt/lima-cidata/user-data | head -n1)"
        [ -n "$mount_line" ] || exit 0

        tag="''${mount_line%% *}"
        options="''${mount_line#* }"

        mkdir -p /mnt/lima
        if ! findmnt --mountpoint /mnt/lima >/dev/null; then
          mount -t virtiofs "$tag" /mnt/lima -o "$options"
        fi
      '';
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
    };

    lima-guestagent = {
      description = "Lima guest agent";
      after = [
        "lima-mounts.service"
        "network-online.target"
      ];
      wants = [
        "lima-mounts.service"
        "network-online.target"
      ];
      wantedBy = [ "multi-user.target" ];
      unitConfig.ConditionPathIsExecutable = "/mnt/lima-cidata/lima-guestagent";
      serviceConfig = {
        EnvironmentFile = "/mnt/lima-cidata/lima.env";
        ExecStart = "/mnt/lima-cidata/lima-guestagent daemon --debug=\${LIMA_CIDATA_DEBUG} --vsock-port \${LIMA_CIDATA_VSOCK_PORT}";
        Restart = "always";
        RestartSec = "3s";
      };
    };
  };
}
