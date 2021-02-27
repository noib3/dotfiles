```sh
cd ~
git clone https://github.com/noib3/dotfiles
mkdir -p ~/.config
ln -s ~/dotfiles ~/.config/nixpkgs
ln ~/.config/nixpkgs/machines/vps-treed/home.nix ~/.config/nixpkgs/home.nix
home-manager switch
```
