let
  pulseaudio-sink = "bluez_sink.5C_44_3E_31_27_86.a2dp_sink";
in
''
  case "$1" in
    lower)
      pactl set-sink-volume ${pulseaudio-sink} -5%
      ;;
    raise)
      pactl set-sink-volume ${pulseaudio-sink} +5%
      ;;
    mute)
      pactl set-sink-mute ${pulseaudio-sink} toggle
      ;;
    *)
      exit 1
      ;;
  esac
''
