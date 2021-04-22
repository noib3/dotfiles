# `/machines/archiv3`

Configuration deployed to a DigitalOcean droplet running NixOS.

## Bootstrapping process
```sh
cd ~
git clone https://github.com/noib3/dotfil3s
mkdir -p ~/.config/nixpkgs
ln -sf ~/dotfil3s/* ~/.config/nixpkgs/
ln -sf ~/.config/nixpkgs/machines/archiv3/home.nix ~/.config/nixpkgs/home.nix
sudo ln -sf /home/nix/.config/nixpkgs/machines/archiv3/configuration.nix /etc/nixos/configuration.nix
sudo nixos-rebuild switch
home-manager switch
```
