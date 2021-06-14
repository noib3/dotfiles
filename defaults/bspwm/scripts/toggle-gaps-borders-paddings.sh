#!/usr/bin/env bash
#
# Toggles window gaps, borders and paddings.

polybar_height=23
off_border_width=0

case "$1" in
  on)
    window_gap=22
    border_width=2
    top_padding=0
    bottom_padding=0
    left_padding=0
    right_padding=0
    ;;
  off)
    window_gap=0
    border_width="$off_border_width"
    top_padding="-$((polybar_height + off_border_width))"
    bottom_padding="-$off_border_width"
    left_padding="-$off_border_width"
    right_padding="-$off_border_width"
    ;;
  *)
    exit 1
    ;;
esac

bspc config -d focused window_gap "$window_gap" \
  && bspc config -d focused top_padding "$top_padding" \
  && bspc config -d focused bottom_padding "$bottom_padding" \
  && bspc config -d focused left_padding "$left_padding" \
  && bspc config -d focused right_padding "$right_padding" \
  && bspc config -d focused border_width "$border_width"
