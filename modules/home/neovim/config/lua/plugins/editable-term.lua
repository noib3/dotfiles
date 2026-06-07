require("editable_term").setup({
  term_keys = {
    goto_line_start = "\27[H",
    goto_line_end = "\27[F",
    clear_current_line = "<c-u><c-k>",
    forward_char = "\27[C",
    clear_suggestions = "<c-n>",
  },
})
