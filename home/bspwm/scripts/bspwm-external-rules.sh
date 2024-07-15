wid=$1
# class=$2
# instance=$3
# consequences=$4

# Float Android emulators and keep them visible while other windows are
# fullscreen.
! [[ $(xtitle "$wid") =~ ^Emulator.*$ ]] \
  || echo "state=floating layer=above" \
  # For debugging
  # || (echo "$wid - $(xtitle $wid)" >> ~/diocane)
