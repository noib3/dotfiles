{ font
, colors
}:

''
  diff --git a/config.def.h b/config.def.h
  index fe056c0..5a25ab9 100644
  --- a/config.def.h
  +++ b/config.def.h
  @@ -3,25 +3,25 @@
   
   static int topbar = 1;                      /* -b  option; if 0, dmenu appears at bottom     */
   static int colorprompt = 1;                /* -p  option; if 1, prompt uses SchemeSel, otherwise SchemeNorm */
  -static int fuzzy = 1;                      /* -F  option; if 0, dmenu doesn't use fuzzy matching     */
  +static int fuzzy = 0;                      /* -F  option; if 0, dmenu doesn't use fuzzy matching     */
   /* -fn option overrides fonts[0]; default X11 font or font set */
   static const char *fonts[] = {
  -	"monospace:size=10"
  +	"${font.family}:size=${toString font.size}"
   };
   static const char *prompt      = NULL;      /* -p  option; prompt to the left of input field */
   static const char *colors[SchemeLast][2] = {
   	/*     fg         bg       */
  -	[SchemeNorm] = { "#bbbbbb", "#222222" },
  -	[SchemePrompt] = { "#bbbbbb", "#222222" },
  -	[SchemeSel] = { "#eeeeee", "#005577" },
  -	[SchemeSelHighlight] = { "#ffc978", "#005577" },
  -	[SchemeNormHighlight] = { "#ffc978", "#222222" },
  +	[SchemeNorm] = { "${colors.normal.fg}", "${colors.normal.bg}" },
  +	[SchemePrompt] = { "${colors.prompt.fg}", "${colors.prompt.bg}" },
  +	[SchemeSel] = { "${colors.selected.fg}", "${colors.selected.bg}" },
  +	[SchemeSelHighlight] = { "${colors.highlight.fg}", "${colors.selected.bg}" },
  +	[SchemeNormHighlight] = { "${colors.highlight.fg}", "${colors.normal.bg}" },
   	[SchemeOut] = { "#000000", "#00ffff" },
   };
   /* -l option; if nonzero, dmenu uses vertical list with given number of lines */
   static unsigned int lines      = 0;
   /* -h option; minimum height of a menu line */
  -static unsigned int lineheight = 0;
  +static unsigned int lineheight = ${toString font.lineheight};
   static unsigned int min_lineheight = 8;
   
   /*
''
