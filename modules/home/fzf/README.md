# `/defaults/fzf`

Hi, this is my fzf setup. It has a couple of cool features that are worth
documenting:

* the `FZF_DEFAULT_COMMAND` uses
  [fd](https://github.com/sharkdp/fd) to list all the files inside the
  `$HOME` folder. The nice thing about fd is that it highlights the search
  results based on the value of the `LS_COLORS` environment variable. This
  allows for some pretty neat coloring effects.

  For example, using sed it's possible to replace the ANSI escape sequence
  used to color directory names with any other sequence. This can be used to
  color directories in a more subtle shade of gray instead of the default blue
  before passing them to fzf.

  The following screenshots compare the outputs of a raw `fd` search versus a
  `sed`-filtered one, basically (in pseudo-code):
  ```
  $ fd --type=files | fzf
  ```
  vs
  ```
  $ fd --type=files | sed 's/blue/gray/' | fzf
  ```

  You be the judge:

| ![fuzzy_edit](/.github/images/fzf/2021-04-12@19:30:02.png) |
|:--:|
| ![fuzzy_edit](/.github/images/fzf/2021-04-12@19:06:44.png) |
| *All the directory names are grayed out, making the file names stand out a lot more* |

* the same sort of trick can be used to color the directories given to the
  `FZF_ALT_C_COMMAND` used to quickly `cd` around your `$HOME`. Comparing the
  raw vs filtered outputs, this time we get:

| ![fuzzy_cd](/.github/images/fzf/2021-04-12@19:30:15.png) |
|:--:|
| ![fuzzy_cd](/.github/images/fzf/2021-04-12@19:07:06.png) |
| *Same logic as above, except now the color of the last directory in every path is left unchanged* |
