function open {
  while read file; do
    case $(file -b --mime-type "$HOME/$file") in
      text/*|application/json|inode/x-empty)
        setsid -f alacritty -e sh -c "sleep 0.2 && $EDITOR '$file'"
        ;;
      image/*)
        setsid -f feh "$HOME/$file"
        ;;
      video/*)
        setsid -f mpv --no-terminal "$HOME/$file"
        ;;
      application/pdf)
        setsid -f zathura "$HOME/$file"
        ;;
    esac
  done
}

fd --base-directory=$HOME --hidden --type=f \
  | sort -r \
  | dmenu -p 'Open>' \
  | open
