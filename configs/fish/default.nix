{ colorscheme, palette, pkgs ? import <nixpkgs> { } }:

let
  colors =
    builtins.mapAttrs
      (name: hex: pkgs.lib.strings.removePrefix "#" hex)
      (import ./colors.nix { inherit colorscheme palette; });
in
{
  shellAliases = {
    cat = "bat";
    grep = "rg";
    ipython = "ipython --no-confirm-exit";
    ls = "ls -Alhv --color --file-type --group-directories-first --quoting-style=literal";
    wget = "wget --hsts-file=~/.cache/wget/wget-hsts";
  } // (
    if pkgs.stdenv.isLinux then
      {
        reboot = "sudo shutdown -r now";
        shutdown = "sudo shutdown now";
        xclip = "xclip -selection c";
      }
    else if pkgs.stdenv.isDarwin then
      {
        reboot = ''osascript -e "tell app \"System Events\" to restart"'';
        shutdown = ''osascript -e "tell app \"System Events\" to shut down"'';
      }
    else { }
  );

  shellAbbrs = {
    hmn = "home-manager news";
    hms = "home-manager switch";
    ipy = "ipython";
    lg = "lazygit";
  } // (
    if pkgs.stdenv.isLinux then
      {
        nrs = "sudo nixos-rebuild switch";
      }
    else { }
  );

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
    bind -M insert \cX\cR 'fuzzy_ripgrep; commandline -f repaint'
    bind -M insert \cS fuzzy-search

    # For some reason the pisces plugin needs to be sourced manually to become
    # active.
    source ~/.config/fish/conf.d/plugin-pisces.fish

    direnv hook fish | source

    ${pkgs.gnupg}/bin/gpg-connect-agent updatestartuptty /bye > /dev/null
  '' + (
    if pkgs.stdenv.isDarwin then
      ''
        bass source ~/.nix-profile/etc/profile.d/nix{,-daemon}.sh 2>/dev/null \
          || true
      ''
    else ""
  );

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
  ] ++ (
    if pkgs.stdenv.isDarwin then
      [
        {
          name = "bass";
          src = pkgs.fetchFromGitHub {
            owner = "edc";
            repo = "bass";
            rev = "2fd3d2157d5271ca3575b13daec975ca4c10577a";
            sha256 = "0mb01y1d0g8ilsr5m8a71j6xmqlyhf8w4xjf00wkk8k41cz3ypky";
          };
        }
      ]
    else [ ]
  );

  functions = {
    fuzzy-cd = builtins.readFile ./functions/fuzzy-cd.fish;
    fuzzy-edit = builtins.readFile ./functions/fuzzy-edit.fish;
    fuzzy-history = builtins.readFile ./functions/fuzzy-history.fish;
    fuzzy-kill = builtins.readFile ./functions/fuzzy-kill.fish;
    fuzzy-search = builtins.readFile ./functions/fuzzy-search.fish;
  };
}
