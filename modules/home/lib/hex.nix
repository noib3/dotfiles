{ lib }:

with lib;
rec {
  # Returns the list obtained by splitting the input string every two
  # characters.
  #
  # Example:
  #   splitEveryTwo "61afef" => [ "61" "af" "ef" ]
  splitEveryTwo =
    string: lists.flatten (builtins.filter builtins.isList (builtins.split "(.{2})" string));

  # Returns <base> ** <exponent>.
  # Taken from https://gist.github.com/corpix/f761c82c9d6fdbc1b3846b37e1020e11
  #
  # Example:
  #   pow 16 2 => 256
  pow =
    base: exponent:
    let
      pow' =
        base: exponent: value:
        if exponent == 0 then
          1
        else if exponent <= 1 then
          value
        else
          (pow' base (exponent - 1) (value * base));
    in
    pow' base exponent base;

  # Converts a color from hexadecimal to the format used in ANSI escape
  # sequences.
  #
  # Example:
  #   toANSI "#61afef" => "1;38;2;97;175;239"
  toANSI =
    color:
    "1;38;2;"
    + (concatStringsSep ";" (
      builtins.map (x: builtins.toString (toDec x)) (splitEveryTwo (removePrefix "#" color))
    ));

  # Converts a two character string from hexadecimal into decimal.
  #
  # Example:
  #   toDec "61" => 97
  toDec =
    hex:
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
    lists.foldl (a: v: a + v) 0 (
      lists.imap0 (i: v: (pow 16 i) * hexToInt."${v}") (
        lists.reverseList (strings.stringToCharacters hex)
      )
    );

  # Converts a string from decimal into hexadecimal.
  # Taken from https://gist.github.com/corpix/f761c82c9d6fdbc1b3846b37e1020e11
  #
  # Example:
  #   toHex 97 => "61"
  toHex =
    dec:
    let
      intToHex = [
        "0"
        "1"
        "2"
        "3"
        "4"
        "5"
        "6"
        "7"
        "8"
        "9"
        "a"
        "b"
        "c"
        "d"
        "e"
        "f"
      ];
      toHex' = q: a: if q > 0 then (toHex' (q / 16) ((elemAt intToHex (mod q 16)) + a)) else a;

      append_zero_if_needed = str: if (builtins.stringLength str) == 1 then "0" + str else str;
    in
    append_zero_if_needed (toHex' dec "");

  min = x: y: if x < y then x else y;

  # Scales a color given in hex format by the given percentage.
  #
  # Example:
  #   scale 1.2 "#3e4452" => "#4a5162"
  scale =
    scalar: color:
    "#"
    + (concatStrings (
      builtins.map (x: toHex (min (builtins.floor ((toDec x) * scalar)) 255)) (
        splitEveryTwo (strings.removePrefix "#" color)
      )
    ));
}
