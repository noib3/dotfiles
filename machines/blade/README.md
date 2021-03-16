```sh
cd ~
git clone git@github.com:noib3/dotfiles.git
mkdir -p ~/.config
ln -sf ~/dotfiles/* ~/.config/nixpkgs/
ln -sf ~/.config/nixpkgs/machines/blade/home.nix ~/.config/nixpkgs/home.nix
home-manager switch
```
