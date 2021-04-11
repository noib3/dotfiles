The purpose of this `default.nix` is to be able to define different highlight
groups, or the same highlight group but with different attributes, depending
on the global color scheme being used.

For example when using the `afterglow` color scheme I might have
```nix
  # In /colorschemes/afterglow/neovim.nix
  # ...
  highlights = {
    # ...
    "SpellBad" = {
      guifg = "#ac4142";
      gui = "underline";
    };
    # ...
  };
  # ...
```
or, with `onedark`:
```nix
  # In /colorschemes/onedark/neovim.nix
  # ...
  highlights = {
    # ...
    "SpellBad" = {
      guifg = "#e06c75";
      gui = "underline";
    };

    "SpellCap" = {
      guifg = "#d19a66";
      gui = "NONE";
    };
    # ...
  };
  # ...
```

A (neo)vim-only solution to this problem could have been to define different
"patching" functions for each `colorscheme`, together with an `autocmd` that
calls every function when the relative `colorscheme` has been set, i.e.:
```vim
function! s:patch_afterglow()
  hi SpellBad guifg=#ac4142 gui=underline
endfunction

function! s:patch_onedark()
  hi SpellBad guifg=#e06c75 gui=underline
  hi SpellCap guifg=#d19a66 gui=NONE
endfunction

augroup colorschemes
  autocmd!
  autocmd ColorScheme afteglow call s:patch_afterglow()
  autocmd ColorScheme onedark call s:patch_onedark()
augroup END
```
but I prefer the first method for consistency reasons, as it allows me to put
neovim's `colorscheme`-related code in the `/colorscheme` directory together
with the color specifications for all the other programs.
