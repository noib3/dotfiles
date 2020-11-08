function reset_cursor_line --on-event fish_prompt --description "Reset the \
cursor shape to a vertical line every time the prompt is drawn"
  printf "\e[5 q"
end
