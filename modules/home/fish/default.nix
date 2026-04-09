{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.modules.fish;
  inherit (pkgs.stdenv) isDarwin isLinux;
  inherit (config.lib.mine) dotfilesDir;
  colors = builtins.mapAttrs (name: hex: lib.strings.removePrefix "#" hex) (
    import ./colors.nix { inherit config; }
  );
in
{
  options.modules.fish = {
    enable = mkEnableOption "Fish";
  };

  config = mkIf cfg.enable {
    home.shell.enableFishIntegration = true;

    programs.fish = {
      enable = true;

      shellAliases = {
        cat = "bat";
        gcl = "git clone";
        grep = "rg";
        ipython = "ipython --no-confirm-exit";
        ls = "ls -Alhv --color --file-type --group-directories-first --quoting-style=literal";
        wget = "${pkgs.wget}/bin/wget --hsts-file=~/.cache/wget/wget-hsts";
      }
      // lib.attrsets.optionalAttrs isDarwin {
        reboot = ''osascript -e "tell app \"System Events\" to restart"'';
        shutdown = ''osascript -e "tell app \"System Events\" to shut down"'';
      }
      // lib.attrsets.optionalAttrs isLinux {
        reboot = "sudo shutdown -r now";
        shutdown = "sudo shutdown now";
      };

      shellAbbrs = {
        hmn = "home-manager news --flake ${dotfilesDir}#${config.machines.current.name}";
        hms = "home-manager switch --flake ${dotfilesDir}#${config.machines.current.name}";
        ipy = "ipython";
        lg = "lazygit";
      }
      // lib.attrsets.optionalAttrs config.machines.current.hasNixosConfiguration {
        nrs = "nixos-rebuild switch --flake ${dotfilesDir}#${config.machines.current.name} --sudo";
      }
      // lib.attrsets.optionalAttrs config.machines.current.hasDarwinConfiguration {
        drs = "sudo darwin-rebuild switch --flake ${dotfilesDir}#${config.machines.current.name}";
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

        bind super-left beginning-of-line
        bind super-right end-of-line
        bind yy fish_clipboard_copy
        bind Y fish_clipboard_copy
        bind p fish_clipboard_paste

        bind -M visual super-left beginning-of-line
        bind -M visual super-right end-of-line

        bind -M insert super-left beginning-of-line
        bind -M insert super-right end-of-line
        bind -M insert \e\x7F backward-kill-word
        bind -M insert super-w exit
        bind -M insert super-l 'clear; commandline -f repaint'
        bind -M insert super-d fuzzy-cd
        bind -M insert super-e fuzzy-edit
        bind -M insert super-h fuzzy-history
        bind -M insert super-k fuzzy-kill
        bind -M insert super-r fuzzy-ripgrep-fish
        bind -M insert super-s fuzzy-search

        # For some reason the pisces plugin needs to be sourced manually to
        # become active.
        source ~/.config/fish/conf.d/plugin-pisces.fish

        # The fzf module's fish integration adds `fzf --fish` to the config,
        # which, among other things, sets shift-tab to show shell completions
        # via fzf. I want shift-tab to select the previous completion.
        bind -M insert super-t fzf-completion
        bind -M insert shift-tab 'if commandline --paging-mode; commandline -f complete-and-search; end'

        ${pkgs.gnupg}/bin/gpg-connect-agent updatestartuptty /bye > /dev/null

        # Workaround for https://github.com/NixOS/nix/issues/5131
        if set -q IN_NIX_SHELL
          set -gx SHELL (status fish-path)
        end

        function __repair_stale_pwd --on-event fish_prompt
          if test -n "$PWD"; and not test -d "$PWD"
            set -l physical_pwd (command pwd -P 2> /dev/null)
            if test -n "$physical_pwd"; and test -d "$physical_pwd"
              builtin cd "$physical_pwd" 2> /dev/null
            end
          end
        end

        function __update_cargo_target_dir --on-variable PWD
          ${config.modules.rust.cargo-target-dir-env.meta.mainProgram} \
            --shell fish | source
        end

        __update_cargo_target_dir
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
        fuzzy-ripgrep-fish = "fuzzy-ripgrep; commandline -f repaint";
        fuzzy-search = builtins.readFile ./functions/fuzzy-search.fish;
        gri = builtins.readFile ./functions/gri.fish;
      };
    };
  };
}
