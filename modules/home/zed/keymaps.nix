[
  {
    context = "Editor";
    bindings = {
      # Scroll up/down by half a page.
      cmd-up = "vim::ScrollUp";
      cmd-down = "vim::ScrollDown";

      # Scroll up/down visual lines (instead of buffer lines).
      up = "editor::MoveUp";
      down = "editor::MoveDown";
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
      shift-up = [
        "workspace::ActivatePaneInDirection"
        "Up"
      ];
      shift-down = [
        "workspace::ActivatePaneInDirection"
        "Down"
      ];
      shift-left = [
        "workspace::ActivatePaneInDirection"
        "Left"
      ];
      shift-right = [
        "workspace::ActivatePaneInDirection"
        "Right"
      ];

      # LSP-related bindings.
      cmd-x = "editor::FindAllReferences";
      "g t d" = "editor::GoToTypeDefinition";
      shift-a = "editor::ToggleCodeActions";
      shift-r = "editor::Rename";

      # Go to next/previous diagnostic.
      "d n" = "editor::GoToDiagnostic";
      "d p" = "editor::GoToPreviousDiagnostic";

      # Open the command palette.
      space = "command_palette::Toggle";
    };
  }
  {
    context = "Editor && VimControl && !VimWaiting && !menu";
    bindings = {
      # Select up/down treesitter nodes.
      tab = "editor::SelectLargerSyntaxNode";
      shift-tab = "editor::SelectSmallerSyntaxNode";
    };
  }
  {
    context = "Editor && vim_mode == normal && menu";
    bindings = {
      # Select/accept code action.
      up = "editor::ContextMenuPrevious";
      down = "editor::ContextMenuNext";
      return = "editor::ConfirmCodeAction";
    };
  }
  {
    context = "vim_mode == visual";
    bindings = {
      shift-s = "vim::PushAddSurrounds";

      # TODO: this shouldn't be needed, `editor::Move{Up,Down}` should play
      # nice with Vim.
      up = ["workspace::SendKeystrokes" "g k"];
      down = ["workspace::SendKeystrokes" "g j"];

      # TODO: this shouldn't be needed, the default bindings should play nice
      # with Vim.
      cmd-right = ["workspace::SendKeystrokes" "$ left"];
      cmd-left = "vim::FirstNonWhitespace";
    };
  }
]
