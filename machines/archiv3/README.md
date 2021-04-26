# `/machines/archiv3`

Configuration deployed to a DigitalOcean droplet running NixOS.

## Bootstrapping process

After `ssh`ing in for the first time as root:
```
nix-env -iA nixos.git
nix-channel --add https://nixos.org/channels/nixos-unstable nixos-unstable
nix-channel --update
git clone https://github.com/noib3/dotfil3s
ln -s /root/dotfil3s/machines/archiv3/configuration.nix /etc/nixos/configuration.nix
nixos-rebuild switch
cp -R /root/dotfil3s /home/noib3/dotfil3s
chown -R noib3:users /home/noib3/dotfil3s
ln -sf /home/noib3/dotfil3s/machines/archiv3/configuration.nix /etc/nixos/configuration.nix
su noib3
nix-channel --add https://nixos.org/channels/nixos-20.09 nixos
nix-channel --add https://nixos.org/channels/nixos-unstable nixos-unstable
nix-channel --add https://github.com/nix-community/home-manager/archive/release-20.09.tar.gz home-manager
nix-channel --update
```

Now exit and `ssh` back in, then:
```
nix-shell '<home-manager>' -A install
ln -sf ~/dotfil3s/* ~/.config/nixpkgs/
ln -sf ~/dotfil3s/machines/archiv3/home.nix ~/.config/nixpkgs/home.nix
home-manager switch
```
