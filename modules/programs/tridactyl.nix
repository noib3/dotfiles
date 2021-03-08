{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.programs.tridactyl;
in
{ }

# if nativeMessenger is true execute the following command:
# curl -fsSl https://raw.githubusercontent.com/tridactyl/native_messenger/master/installers/install.sh -o /tmp/trinativeinstall.sh && sh /tmp/trinativeinstall.sh master
