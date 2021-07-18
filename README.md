# :european_castle: dotfiles

Hi, this is the repository where I keep all the configuration files for the
programs I use across my machines. I use
[home-manager](https://github.com/nix-community/home-manager) to manage my user
environments, which means most of the configuration files are written in Nix.

## Repository structure

The repository is structured as follows:

  * `/colorschemes`: every subfolder inside it represents a different color
  scheme and it contains a `background.png` file along with color
  specifications for various programs. For example:

  ``` nix
  # /colorschemes/afterglow/bspwm.nix
  {
    normal_border = "#393939";
    active_border = "#393939";
    focused_border = "#797979";
  }
  ```
  ``` nix
  # /colorschemes/gruvbox/bspwm.nix
  {
    normal_border = "#3c3836";
    active_border = "#3c3836";
    focused_border = "#a89984";
  }
  ```

  * `/machines`: every subfolder inside it represents a different machine
  (some using NixOS, others macOS) and it usually contains:

    * that machine's `home.nix`, i.e. home-manager's entry point;
    * a `configuration.nix` if that machine uses NixOS;
    * a `fonts` directory containing font size configurations for various
    fonts and programs;

  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; along with other miscellaneous files related to that machine;

  * `/programs`: this is the heart of this repository as it is where the base
  configurations for all the programs I'm using live.

## Gallery

The following screenshots were taken on the
[blade](https://github.com/noib3/dotfiles/blob/master/machines/blade) machine
using the
[onedark](https://github.com/noib3/dotfiles/blob/master/colorschemes/onedark)
color scheme together with the [Fira
Code](https://github.com/noib3/dotfiles/blob/master/machines/blade/fonts/fira-code)
Nerd font.

| *Clean* |
| :--: |
| ![clean](./machines/blade/screenshots/clean.png) |

| *System infos* |
| :--: |
| ![sysinfos](./machines/blade/screenshots/sysinfos.png) |

| *Notifications* |
| :--: |
| ![notifications](./machines/blade/screenshots/notifications.png) |

| *qutebrowser* |
| :--: |
| ![qutebrowser](./machines/blade/screenshots/qutebrowser.png) |

| *Editing this README inside neovim with markdown previews* |
| :--: |
| ![qutebrowser](./machines/blade/screenshots/markdown-preview.png) |

| *Fzf inside neovim with ueberzug image previews* |
| :--: |
| ![qutebrowser](./machines/blade/screenshots/neovim-fzf-image-previews.png) |
