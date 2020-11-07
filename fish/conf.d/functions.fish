function fish_mode_prompt; end

function reset_line_cursor --on-event fish_prompt
  printf "\e[5 q"
end
