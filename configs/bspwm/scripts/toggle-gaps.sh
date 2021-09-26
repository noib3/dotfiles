case $(bspc config -d focused top_padding) in
  -20)
    window_gap=$(bspc config window_gap)
    border_width=$(bspc config border_width)
    top_padding=0
    ;;
  0)
    window_gap=0
    border_width=0
    top_padding=5
    ;;
  5)
    window_gap=0
    border_width=0
    top_padding=-20
    ;;
  *)
    exit 1
    ;;
esac

bspc config -d focused window_gap "$window_gap" \
  && bspc config -d focused border_width "$border_width" \
  && bspc config -d focused top_padding "$top_padding"
