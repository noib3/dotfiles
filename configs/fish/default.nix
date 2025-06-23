{
  config,
  lib,
  pkgs,
}:

let
  inherit (pkgs) lib;
  inherit (pkgs.stdenv) isDarwin isLinux;
  inherit (config.lib.mine) dotfilesDir;

  colors = builtins.mapAttrs (name: hex: lib.strings.removePrefix "#" hex) (
    import ./colors.nix { inherit config; }
  );
in
{
  enable = true;

  shellAliases =
    {
      cat = "bat";
      gcl = "git clone";
      grep = "rg";
      ipython = "ipython --no-confirm-exit";
      ls = "ls -Alhv --color --file-type --group-directories-first --quoting-style=literal";
      wget = "${pkgs.wget}/bin/wget --hsts-file=~/.cache/wget/wget-hsts";
    }
    // lib.attrsets.optionalAttrs isDarwin {
      ldd = "otool -L";
      reboot = ''osascript -e "tell app \"System Events\" to restart"'';
      shutdown = ''osascript -e "tell app \"System Events\" to shut down"'';
    }
    // lib.attrsets.optionalAttrs isLinux {
      reboot = "sudo shutdown -r now";
      shutdown = "sudo shutdown now";
    };

  shellAbbrs =
    {
      hmn = "home-manager news --flake ${dotfilesDir}#${config.machine.name}";
      hms = "home-manager switch --flake ${dotfilesDir}#${config.machine.name}";
      ipy = "ipython";
      lg = "lazygit";
      ngc = "nix store gc";
      t = "tdtd";
    }
    // lib.attrsets.optionalAttrs config.machine.hasNixosConfiguration {
      nrs = "nixos-rebuild switch --flake ${dotfilesDir}#${config.machine.name} --use-remote-sudo";
    }
    // lib.attrsets.optionalAttrs config.machine.hasDarwinConfiguration {
      drs = "darwin-rebuild switch --flake ${dotfilesDir}#${config.machine.name}";
    };

  interactiveShellInit = ''
    set fish_greeting ""

    set fish_cursor_default block
    set fish_cursor_insert line
    set fish_cursor_replace_one underscore
    set fish_cursor_visual block

    set fish_color_user green
    set fish_color_host white
    set fish_color_host_remote white
    set fish_color_cwd blue
    set fish_color_command green
    set fish_color_error red
    set fish_color_quote yellow
    set fish_color_valid_path --underline
    set fish_color_redirection white

    set fish_color_param ${colors.param}
    set fish_color_operator ${colors.operator}
    set fish_color_autosuggestion ${colors.autosuggestion} --italics
    set fish_color_comment ${colors.comment} --italics
    set fish_color_end ${colors.end}
    set fish_color_selection --background=${colors.selection_bg}

    fish_vi_key_bindings

    bind \cA beginning-of-line
    bind \cE end-of-line
    bind yy fish_clipboard_copy
    bind Y fish_clipboard_copy
    bind p fish_clipboard_paste

    bind -M visual \cA beginning-of-line
    bind -M visual \cE end-of-line

    bind -M insert \cA beginning-of-line
    bind -M insert \cE end-of-line
    bind -M insert \e\x7F backward-kill-word
    bind -M insert \cW exit
    bind -M insert \cG 'clear; commandline -f repaint'
    bind -M insert \cX\cD fuzzy-cd
    bind -M insert \cX\cE fuzzy-edit
    bind -M insert \cX\cF fuzzy-history
    bind -M insert \cX\cG fuzzy-kill
    bind -M insert \cX\cR fuzzy-ripgrep-fish
    bind -M insert \cS fuzzy-search

    # For some reason the pisces plugin needs to be sourced manually to become
    # active.
    source ~/.config/fish/conf.d/plugin-pisces.fish

    ${pkgs.gnupg}/bin/gpg-connect-agent updatestartuptty /bye > /dev/null
  '';

  plugins = [
    {
      name = "pisces";
      src = pkgs.fetchFromGitHub {
        owner = "laughedelic";
        repo = "pisces";
        rev = "v0.7.0";
        sha256 = "073wb83qcn0hfkywjcly64k6pf0d7z5nxxwls5sa80jdwchvd2rs";
      };
    }
  ];

  functions = {
    fuzzy-cd = builtins.readFile ./functions/fuzzy-cd.fish;
    fuzzy-edit = builtins.readFile ./functions/fuzzy-edit.fish;
    fuzzy-history = builtins.readFile ./functions/fuzzy-history.fish;
    fuzzy-kill = builtins.readFile ./functions/fuzzy-kill.fish;
    fuzzy-ripgrep-fish = "fuzzy-ripgrep && commandline -f repaint";
    fuzzy-search = builtins.readFile ./functions/fuzzy-search.fish;
    gri = builtins.readFile ./functions/gri.fish;
  };
}
