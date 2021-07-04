function open {
  text_files=()
  image_files=()

  while read file; do
    case $(file -b --mime-type "$HOME/$file") in
      text/*|application/json|inode/x-empty)
        text_files+=($(echo "$HOME/$file" | sed "s/\ /\\\ /g"))
        ;;
      image/*)
        setsid -f sxiv "$HOME/$file"
        # image_files+=("$f")
        ;;
      video/*)
        setsid -f mpv --no-terminal "$HOME/$file"
        ;;
      application/pdf)
        setsid -f zathura "$HOME/$file"
        ;;
    esac
  done

  # (( ${#image_files[@]} )) && open "${image_files[@]}"
  if (( ${#text_files[@]} )); then
    filenames="$(echo ${text_files[@]})"
    alacritty \
      --class 'fuzzy-opened' \
      -e sh -c "sleep 0.2 && $EDITOR $filenames"
  fi
}

fd --base-directory=$HOME --hidden --type=f | dmenu -p 'Open>' | open
