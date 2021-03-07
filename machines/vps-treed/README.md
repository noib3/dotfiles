```sh
cd ~
git clone https://github.com/noib3/dotfiles
mkdir -p ~/.config
ln -sf ~/dotfiles ~/.config/nixpkgs
ln -sf ~/.config/nixpkgs/machines/vps-treed/home.nix ~/.config/nixpkgs/home.nix
ln -sf ~/.config/nixpkgs/machines/vps-treed/configuration.nix /etc/nixos/configuration.nix
home-manager switch
```
