bspwm_top_padding=15

case $(bspc config -d focused top_padding) in
  -"$bspwm_top_padding")
    window_gap=$(bspc config window_gap)
    border_width=$(bspc config border_width)
    top_padding=0
    ;;
  0)
    window_gap=0
    border_width=0
    top_padding=10
    # top_padding=5
    ;;
  10)
  # 5)
    window_gap=0
    border_width=0
    top_padding=-"$bspwm_top_padding"
    ;;
  *)
    exit 1
    ;;
esac

bspc config -d focused window_gap "$window_gap" \
  && bspc config -d focused border_width "$border_width" \
  && bspc config -d focused top_padding "$top_padding"
