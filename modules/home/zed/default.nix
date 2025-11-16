{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.modules.zed;
in
{
  options.modules.zed = {
    enable = mkEnableOption "Zed";
  };

  config = mkIf cfg.enable {
    programs.zed-editor = {
      enable = true;
      extensions = [ "nix" ];
      mutableUserKeymaps = false;
      mutableUserSettings = false;
      themes = import ./themes;
      userKeymaps = [
        {
          context = "Editor";
          bindings = {
            # Scroll up/down by half a page.
            "cmd-up" = "vim::ScrollUp";
            "cmd-down" = "vim::ScrollDown";

            # Scroll up/down visual lines (instead of buffer lines).
            "up" = "editor::MoveUp";
            "down" = "editor::MoveDown";
          };
        }
        {
          context = "Editor && vim_mode == normal";
          bindings = {
            # Create splits.
            "s up" = "pane::SplitUp";
            "s down" = "pane::SplitDown";
            "s left" = "pane::SplitLeft";
            "s right" = "pane::SplitRight";

            # Navigate splits.
            "shift-up" = [
              "workspace::ActivatePaneInDirection"
              "Up"
            ];
            "shift-down" = [
              "workspace::ActivatePaneInDirection"
              "Down"
            ];
            "shift-left" = [
              "workspace::ActivatePaneInDirection"
              "Left"
            ];
            "shift-right" = [
              "workspace::ActivatePaneInDirection"
              "Right"
            ];

            "cmd-x" = "editor::FindAllReferences";
            "g t d" = "editor::GoToTypeDefinition";
            "shift-a" = "editor::ToggleCodeActions";
            "shift-r" = "editor::Rename";
          };
        }
        {
          context = "Editor && vim_mode == normal && menu";
          bindings = {
            # Select/accept code action.
            "up" = "editor::ContextMenuPrevious";
            "down" = "editor::ContextMenuNext";
            "return" = "editor::ConfirmCodeAction";
          };
        }
        {
          context = "vim_mode == visual";
          bindings = {
            shift-s = "vim::PushAddSurrounds";
          };
        }
      ];
      userSettings =
        let
          buffer_font = config.fonts.monospace;
          preferred_line_length = 79;
        in
        {
          auto_update = false;
          autosave = "on_focus_change";
          buffer_font_family = buffer_font.name;
          buffer_font_size = buffer_font.size config "zed";
          current_line_highlight = "none";
          cursor_blink = false;
          diagnostics.inline.enabled = true;
          features.edit_prediction_provider = "copilot";
          git = {
            git_gutter = "hide";
            inline_blame.enabled = false;
          };
          go_to_definition_fallback = "none";
          gutter = {
            folds = false;
            line_numbers = true;
            min_line_number_digits = 2;
          };
          indent_guides.enabled = false;
          languages = {
            Nix.language_servers = [
              "nixd"
              "!nil"
            ];
          };
          load_direnv = "shell_hook";
          lsp = {
            nixd.initialization_options = {
              formatting = {
                command = [
                  "nixfmt"
                  "--width"
                  "79"
                ];
              };
            };
            rust-analyzer.initialization_options = {
              highlightRelated.references.enable = false;
              imports = {
                granularity = {
                  enforce = true;
                  group = "module";
                };
                merge = {
                  glob = false;
                };
                preferNoStd = true;
              };
              procMacro.enable = true;
            };
          };
          on_last_window_closed = "quit_app";
          inherit preferred_line_length;
          preview_tabs.enabled = false;
          relative_line_numbers = true;
          scroll_beyond_last_line = "off";
          scrollbar = {
            cursors = false;
            git_diff = false;
            selected_symbol = false;
            selected_text = false;
          };
          search.button = false;
          seed_search_query_from_cursor = "selection";
          selection_highlight = false;
          show_whitespaces = "all";
          soft_wrap = "editor_width";
          status_bar = {
            active_language_button = false;
            cursor_position_button = false;
            line_endings_button = false;
          };
          tab_bar = {
            show_nav_history_buttons = false;
            show_tab_bar_buttons = false;
          };
          tabs = {
            file_icons = true;
            show_close_button = "hidden";
            show_diagnostics = "all";
          };
          telemetry = {
            diagnostics = false;
            metrics = false;
          };
          title_bar = {
            show_menus = false;
            show_onboarding_banner = false;
          };
          theme = "Gruvbox Material Dark";
          toolbar = {
            breadcrumbs = false;
            quick_actions = false;
          };
          use_smartcase_search = true;
          use_system_path_prompts = false;
          use_system_prompts = false;
          # Equivalent of Vim's 'scrolloff'.
          vertical_scroll_margin = 1;
          vim_mode = true;
          wrap_guides = [ preferred_line_length ];
        }
        // lib.optionalAttrs pkgs.stdenv.isDarwin {
          ui_font_family = ".SystemUIFont";
          use_system_window_tabs = true;
        };
    };
  };
}
