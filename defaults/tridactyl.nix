{ font, colors }:

{
  config = ''
    colorscheme current

    set modeindicator false

    bind j scrollline 5
    bind k scrollline -5
    bind f hint -J
    bind F hint -Jb
    bind / fillcmdline find
    bind n findnext 1
    bind N findnext -1
    
    source $SECRETSDIR/tridactyl/website-bindings
  '';

  themes = {
    current = ''
      :root {
        --tridactyl-hintspan-font-family: "${font.family}";
        --tridactyl-hintspan-font-size: ${font.hintspan_size};
        --tridactyl-hintspan-bg: ${colors.hintspan_bg};
        --tridactyl-hintspan-fg: ${colors.hintspan_fg};
        --tridactyl-hint-bg: none;
        --tridactyl-hint-outline: none;
        --tridactyl-hint-active-bg: none;
        --tridactyl-hint-active-outline: none;

        --tridactyl-cmdl-font-family: "${font.family}";
        --tridactyl-cmdl-font-size: ${font.cmdl_size};
        --tridactyl-cmdl-bg: ${colors.cmdl_bg};
        --tridactyl-cmdl-fg: ${colors.cmdl_fg};
      }

      #command-line-holder,
      #tridactyl-input {
        font-size: ${font.cmdl_size};
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
