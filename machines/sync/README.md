# `/machines/sync`

Configuration deployed to a DigitalOcean droplet running NixOS.

## Bootstrapping process
```sh
cd ~
git clone https://github.com/noib3/dotfil3s
mkdir -p ~/.config/nixpkgs
ln -sf ~/dotfiles/* ~/.config/nixpkgs/
ln -sf ~/.config/nixpkgs/machines/sync/home.nix ~/.config/nixpkgs/home.nix
sudo ln -sf /home/nix/.config/nixpkgs/machines/sync/configuration.nix /etc/nixos/configuration.nix
sudo nixos-rebuild switch
home-manager switch
```
