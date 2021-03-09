```sh
cd ~
git clone https://github.com/noib3/dotfiles
mkdir -p ~/.config
ln -sf ~/dotfiles ~/.config/nixpkgs
ln -sf ~/.config/nixpkgs/machines/treed-mongodb/home.nix ~/.config/nixpkgs/home.nix
ln -sf ~/.config/nixpkgs/machines/treed-mongodb/configuration.nix /etc/nixos/configuration.nix
home-manager switch
```
