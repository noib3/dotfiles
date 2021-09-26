{ colors }:

let
  lib = import <nixpkgs/lib>;
  hexlib = import ../../colorschemes/hexlib.nix;

  # Converts a color from hexadecimal to the format used in ANSI escape
  # sequences.
  #
  # Example:
  #   toANSIFormat "#61afef" => "1;38;2;97;175;239"
  toANSIFormat = with lib; color:
    "1;38;2;" + (
      concatStringsSep ";" (
        builtins.map (x: builtins.toString (hexlib.toDec x)) (
          hexlib.splitEveryTwo (strings.removePrefix "#" color)
        )
      )
    );

  dirs = toANSIFormat colors.directories;
  gods = toANSIFormat colors.grayed-out-directories;
in
{
  defaultCommand = ''
    fd --base-directory=$HOME --hidden --type=f --color=always \
      | sort -r \
      | sed 's/\x1b\[${dirs}m/\x1b\[${gods}m/g'
  '';

  defaultOptions = [
    "--reverse"
    "--no-bold"
    "--info=inline"
    "--height=8"
    "--hscroll-off=50"
    "--ansi"
    "--preview-window=sharp"
    "--preview-window=border-left"
    "--color='hl:-1:underline'"
    "--color='fg+:-1:regular:italic'"
    "--color='hl+:-1:underline:italic'"
    "--color='prompt:4:regular'"
    "--color='pointer:1'"
    "--color='bg+:${colors.current-line.bg}'"
    "--color='border:${colors.border}'"
  ];

  changeDirWidgetCommand = ''
    fd --base-directory=$HOME --hidden --type=d --color=always \
      | sed 's/\x1b\[${dirs}m/\x1b\[${gods}m/g' \
      | sed 's/\(.*\)\x1b\[${gods}m/\1\x1b\[${dirs}m/'
  '';

  changeDirWidgetOptions = [
    "--prompt='Cd> '"
    "--preview='ls --color=always ~/{}'"
  ];

  enableFishIntegration = true;
}
