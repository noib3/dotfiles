{ font ,colors }:

''
  diff --git a/config.def.h b/config.def.h
  index fe056c0..5a25ab9 100644
  --- a/config.def.h
  +++ b/config.def.h
  @@ -6,15 +6,15 @@ static int colorprompt = 1;                /* -p  option; if 1, prompt uses Sche
   static int fuzzy = 1;                      /* -F  option; if 0, dmenu doesn't use fuzzy matching     */
   /* -fn option overrides fonts[0]; default X11 font or font set */
   static const char *fonts[] = {
  -	"monospace:size=10"
  +	"${font.family}:pixelsize=${font.pixelsize}"
   };
   static const char *prompt      = NULL;      /* -p  option; prompt to the left of input field */
   static const char *colors[SchemeLast][2] = {
   	/*     fg         bg       */
  -	[SchemeNorm] = { "#bbbbbb", "#222222" },
  -	[SchemeSel] = { "#eeeeee", "#005577" },
  -	[SchemeSelHighlight] = { "#ffc978", "#005577" },
  -	[SchemeNormHighlight] = { "#ffc978", "#222222" },
  +	[SchemeNorm] = { "${colors.normal.fg}", "${colors.normal.bg}" },
  +	[SchemeSel] = { "${colors.selected.fg}", "${colors.selected.bg}" },
  +	[SchemeSelHighlight] = { "${colors.highlight.fg}", "${colors.selected.bg}" },
  +	[SchemeNormHighlight] = { "${colors.highlight.fg}", "${colors.normal.bg}" },
   	[SchemeOut] = { "#000000", "#00ffff" },
   };
   /* -l option; if nonzero, dmenu uses vertical list with given number of lines */
''
