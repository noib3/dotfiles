```sh
cd ~
git clone git@github.com:noib3/dotfiles.git
mkdir -p ~/.config
ln -sf ~/dotfiles/* ~/.config/nixpkgs/
ln -sf ~/.config/nixpkgs/machines/pepenerostore/home.nix ~/.config/nixpkgs/home.nix
su
ln -sf /home/nix/.config/nixpkgs/machines/pepenerostore/configuration.nix /etc/nixos/configuration.nix
nixos-rebuild switch
exit
home-manager switch
```
