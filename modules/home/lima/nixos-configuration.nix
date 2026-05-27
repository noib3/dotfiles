{
  config,
  lib,
  pkgs,
  modulesPath,
  username,
  ...
}:

{
  systemd.tmpfiles.rules = [
    "L+ /bin/bash - - - - ${pkgs.bash}/bin/bash"
  ];

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
      after = [ "cloud-final.service" ];
      wants = [ "cloud-final.service" ];
      wantedBy = [ "multi-user.target" ];
      unitConfig.ConditionPathExists = "/mnt/lima-cidata/user-data";
      path = with pkgs; [
        coreutils
        gnused
        util-linux
      ];
      script = ''
        set -eu

        mounts="$(sed -n 's/^- \[\([^,]*\), \([^,]*\), virtiofs, "\([^"]*\)",.*/\1|\2|\3/p' /mnt/lima-cidata/user-data)"
        [ -n "$mounts" ] || exit 0

        printf '%s\n' "$mounts" | while IFS='|' read -r tag mountPoint options; do
          mkdir -p "$mountPoint"
          chown ${username}: "$mountPoint" || true

          if ! findmnt --mountpoint "$mountPoint" >/dev/null; then
            mount -t virtiofs "$tag" "$mountPoint" -o "$options"
          fi
        done
      '';
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
    };

    lima-guestagent = {
      description = "Lima guest agent";
      after = [
        "cloud-final.service"
        "lima-mounts.service"
      ];
      wants = [
        "cloud-final.service"
        "lima-mounts.service"
      ];
      wantedBy = [ "multi-user.target" ];
      unitConfig.ConditionPathExists = "/mnt/lima-cidata/lima-guestagent";
      serviceConfig = {
        ExecStart = "/mnt/lima-cidata/lima-guestagent daemon --debug=false --vsock-port 2222";
        Restart = "always";
        RestartSec = "3s";
      };
    };
  };

  users.groups.${username} = { };

  users.users.${username} = {
    isNormalUser = false;
    isSystemUser = true;
    uid = 501;
    group = username;
    createHome = true;
  };
}
