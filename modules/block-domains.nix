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
      type = types.listOf types.str;
      default = [ ];
      description = ''
        A list of times when the given domains will be blocked, in (HH:mm:ss)
        format.
      '';
      example = [ "9:00" ];
    };

    unblockAt = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = ''
        A list of times when the given domains will be unblocked, in (HH:mm:ss)
        format.
      '';
      example = [ "18:00" ];
    };
  };

  config = 
  let
    blockDomainsServiceName = "block-domains";

    unblockDomainsServiceName = "unblock-domains";

    mkBlockDomainsTimer = time: {
      description = "Block domains at ${time}";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = time;
        Unit = "${blockDomainsServiceName}.service";
        Persistent = "true";
      };
    };

    mkUnblockDomainsTimer = time: {
      description = "Unblock domains at ${time}";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = time;
        Unit = "${unblockDomainsServiceName}.service";
        Persistent = "true";
      };
    };

    blockDomainsTimers = builtins.listToAttrs (
      map
      (time: {
        name = "block-domains-${builtins.replaceStrings [":"] ["-"] time}";
        value = mkBlockDomainsTimer time;
      })
      cfg.blockAt
    );

    unblockDomainsTimers = builtins.listToAttrs (
      map
      (time: {
        name = "unblock-domains-${builtins.replaceStrings [":"] ["-"] time}";
        value = mkUnblockDomainsTimer time;
      })
      cfg.unblockAt
    );

    # The script to execute to block the domains.
    blockDomains = builtins.concatStringsSep "\n" (
      map (domain: "${website-blocker} block ${domain} || true") cfg.blocked
    );

    # The script to execute to unblock the domains.
    unblockDomains = builtins.concatStringsSep "\n" (
      map (domain: "${website-blocker} unblock ${domain} || true") cfg.blocked
    );
  in
  mkIf cfg.enable {
    systemd = {
      timers = blockDomainsTimers // unblockDomainsTimers;

      services.${blockDomainsServiceName} = {
        description = "Block certain domains";
        enable = true;
        script = blockDomains;
      };

      services.${unblockDomainsServiceName} = {
        description = "Unblock the blocked domains";
        enable = true;
        script = unblockDomains;
      };
    };
  };
}

# [1]: https://codeberg.org/davidak/nixos-config/src/branch/main/modules/disable-internet-at-night/default.nix
