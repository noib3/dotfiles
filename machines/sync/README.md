```sh
cd ~
git clone https://github.com/noib3/dotfiles
mkdir -p ~/.config
ln -sf ~/dotfiles ~/.config/nixpkgs
ln -sf ~/.config/nixpkgs/machines/sync/home.nix ~/.config/nixpkgs/home.nix
ln -sf ~/.config/nixpkgs/machines/sync/configuration.nix /etc/nixos/configuration.nix
home-manager switch
```
