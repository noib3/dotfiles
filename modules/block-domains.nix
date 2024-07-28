# Adapted from [1].

{ config, lib, pkgs, ... }:

let
  inherit (lib) mkOption mkEnableOption mkIf types;
  cfg = config.services.block-domains;
  website-blocker = "${pkgs.scripts.website-blocker}/bin/website-blocker";
in
{
  options.services.block-domains = {
    enable = mkEnableOption "block certain domains";

    blocked = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = ''
        A list of domains to block.
      '';
      example = [ "youtube.com" "instagram.com" ];
    };

    blockAt = mkOption {
      type = types.str;
      default = "9:00";
      description = ''
        Configure when to start blocking the given domains (HH:mm:ss).
      '';
      example = "9:00";
    };

    unblockAt = mkOption {
      type = types.str;
      default = "18:00";
      description = ''
        Configure when to stop blocking the given domains (HH:mm:ss).
      '';
      example = "18:00";
    };
  };

  config = 
  let
    blockDomains = builtins.concatStringsSep "\n" (
      map (domain: "${website-blocker} block ${domain} || true") cfg.blocked
    );

    unblockDomains = builtins.concatStringsSep "\n" (
      map (domain: "${website-blocker} unblock ${domain} || true")  cfg.blocked
    );
  in
  mkIf cfg.enable {
    systemd = {
      timers.block-domains = {
        description = "Block domains timer";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = cfg.blockAt;
          Unit = "block-domains.service";
          Persistent = "true";
        };
      };

      services.block-domains = {
        description = "Block certain domains";
        enable = true;
        script = blockDomains;
      };

      timers.unblock-domains = {
        description = "Unblock domains timer";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = cfg.unblockAt;
          Unit = "unblock-domains.service";
          Persistent = "true";
        };
      };

      services.unblock-domains = {
        description = "Unblock the blocked domains";
        enable = true;
        script = unblockDomains;
      };
    };
  };
}

# [1]: https://codeberg.org/davidak/nixos-config/src/branch/main/modules/disable-internet-at-night/default.nix
