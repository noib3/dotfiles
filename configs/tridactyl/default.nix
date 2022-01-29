{ colorscheme, font-family, palette }:

let
  colors = import ./colors.nix { inherit colorscheme palette; };
  font = import ./font.nix { family = font-family; };

  home-page = "https://google.com";
in
{
  config = ''
    set modeindicator false

    bind j scrollline 5
    bind k scrollline -5
    bind f hint -J
    bind F hint -Jb
    bind / fillcmdline find
    bind n findnext 1
    bind N findnext -1
    
    unbind --mode=normal t
    unbind --mode=normal gr
    unbind --mode=normal gt

    bind gh open ${home-page}
    bind th tabopen ${home-page}

    bind gma open https://mail.protonmail.com/inbox
    bind tma tabopen https://mail.protonmail.com/inbox

    bind gkp open https://keep.google.com
    bind tkp tabopen https://keep.google.com

    bind gyt open https://youtube.com
    bind tyt tabopen https://youtube.com

    bind gre open https://reddit.com
    bind tre tabopen https://reddit.com

    bind gdf open https://github.com/noib3/dotfiles
    bind tdf tabopen https://github.com/noib3/dotfiles

    bind gbg open https://rarbgunblocked.org/torrents.php
    bind tbg tabopen https://rarbgunblocked.org/torrents.php

    bind glg open https://libgen.li
    bind tlg tabopen https://libgen.li

    bind gn26 open https://app.n26.com/account
    bind tn26 tabopen https://app.n26.com/account

    bind gwi open https://wise.com/user/account/
    bind twi tabopen https://wise.com/user/account/

    bind gt0 open https://www.tradezero.co/account/
    bind tt0 tabopen https://www.tradezero.co/account/

    bind gtw open https://manage.tastyworks.com/index.html
    bind ttw tabopen https://manage.tastyworks.com/index.html

    bind gtra open http://localhost:9091/transmission/web/
    bind ttra tabopen http://localhost:9091/transmission/web/

    bind gbm open http://localhost:5001
    bind tbm tabopen http://localhost:5001

    bind gsy open http://localhost:8384
    bind tsy tabopen http://localhost:8384

    bind grsy open https://46.101.51.224:8384
    bind trsy tabopen https://46.101.51.224:8384

    colorscheme current
  '';

  themes = {
    current = ''
      :root {
        --tridactyl-hintspan-font-family: "${font.family}";
        --tridactyl-hintspan-font-size: ${builtins.toString font.hints.size}px;
        --tridactyl-hintspan-bg: ${colors.hints.bg};
        --tridactyl-hintspan-fg: ${colors.hints.fg};
        --tridactyl-hint-bg: none;
        --tridactyl-hint-outline: none;
        --tridactyl-hint-active-bg: none;
        --tridactyl-hint-active-outline: none;

        --tridactyl-cmdl-font-family: "${font.family}";
        --tridactyl-cmdl-font-size: ${builtins.toString font.commandline.size}px;
        --tridactyl-cmdl-bg: ${colors.commandline.bg};
        --tridactyl-cmdl-fg: ${colors.commandline.fg};
      }

      #command-line-holder,
      #tridactyl-input {
        font-size: ${font.commandline.size};
        height: 1.3em;
        margin-top: -1px;
        margin-bottom: 2px;
      }

      #command-line-holder {
        padding-left: 0.15em;
      }

      #tridactyl-input {
        outline: none;
      }

      #completions {
        display: none;
      }
    '';
  };
}
