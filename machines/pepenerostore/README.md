# Bootstrapping instructions

**NOTE:** it's assumed that `git` is installed and that the current user is
named `pepe`. If the user has a different name, change the values of
`home.username` and `home.homeDirectory` in `home.nix` after cloning this
repository.

## Installing nix and home-manager on a non-NixOS Linux server

First install nix and add the `nixos`, `nixos-unstable` and `home-manager`
channels:

```sh
sh <(curl -L https://nixos.org/nix/install)
nix-channel --add https://nixos.org/channels/nixos-20.09 nixos
nix-channel --add https://nixos.org/channels/nixos-unstable nixos-unstable
nix-channel --add https://github.com/nix-community/home-manager/archive/release-20.09.tar.gz home-manager
nix-channel --update
```

Next clone this repository, symlink it into place and log out:

```sh
cd ~
git clone git@github.com:noib3/dotfiles.git
mkdir -p ~/.config
ln -sf ~/dotfiles/* ~/.config/nixpkgs/
ln -sf ~/.config/nixpkgs/machines/pepenerostore/home.nix ~/.config/nixpkgs/home.nix
exit
```

After logging back in a simple `home-manager switch` should be all that's left
to do to have a development environment configured the way I like.

## Installing WordPress with all its dependencies
