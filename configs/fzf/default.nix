{ lib, colors }:

with lib; let
  # Returns the list obtained by splitting the input string every two
  # characters.
  #
  # Example:
  #   splitEveryTwo "61afef" => [ "61" "af" "ef" ]
  splitEveryTwo = string:
    lists.flatten (
      builtins.filter builtins.isList (
        builtins.split "(.{2})" string
      )
    );

  # Returns <base> ** <exponent>.
  # Taken from https://gist.github.com/corpix/f761c82c9d6fdbc1b3846b37e1020e11.
  # 
  # Example:
  #   pow 16 2 => 256
  pow = base: exponent:
    let
      pow' = base: exponent: value:
        if exponent == 0 then
          1
        else if exponent <= 1 then
          value
        else
          (pow' base (exponent - 1) (value * base));
    in
    pow' base exponent base;

  # Converts a two character string from hexadecimal into decimal.
  #
  # Example:
  #   hexToDec "61" => "97"
  hexToDec = string:
    let
      hexToInt = {
        "0" = 0;
        "1" = 1;
        "2" = 2;
        "3" = 3;
        "4" = 4;
        "5" = 5;
        "6" = 6;
        "7" = 7;
        "8" = 8;
        "9" = 9;
        "a" = 10;
        "b" = 11;
        "c" = 12;
        "d" = 13;
        "e" = 14;
        "f" = 15;
      };
    in
    builtins.toString (
      lists.foldl (a: v: a + v) 0 (
        lists.imap0
          (i: v: (pow 16 i) * hexToInt."${v}")
          (lists.reverseList (strings.stringToCharacters string))
      )
    );

  # Converts a color from hexadecimal to the format used in ANSI escape
  # sequences.
  #
  # Example:
  #   toANSIFormat "#61afef" => "1;38;2;97;175;239"
  toANSIFormat = color:
    "1;38;2;" + (
      concatStringsSep ";" (
        builtins.map (x: hexToDec x) (
          splitEveryTwo (strings.removePrefix "#" color)
        )
      )
    );

  dirs = toANSIFormat colors.directories;
  gods = toANSIFormat colors.grayed-out-directories;
in
{
  defaultCommand = ''
    fd --base-directory=$HOME --hidden --type=f --color=always \
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
