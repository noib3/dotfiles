function clear_no_scrollback --description "Really clear the screen (no \
scrollback)"
  clear && printf "\e[3J"
  commandline -f repaint
end
