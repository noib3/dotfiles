# Defines the key type used for key bindings.

{ lib }:

with lib;
types.addCheck types.attrs (
  x:
  x ? code
  && builtins.isInt x.code
  && x ? modifiers
  && builtins.isInt x.modifiers
  && x ? plus
  && builtins.isFunction x.plus
)
