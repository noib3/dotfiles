---@class utils.Logo
---@field icon string The logo, from Nerd Fonts.
---@field color? string The brand's color, as a `#rrggbb` hex string.

---@type table<string, utils.Logo>
return {
  claude = { icon = "\u{ec82}", color = "#D97757" }, -- nf-cod-claude
  github = { icon = "\u{f408}" }, -- nf-oct-mark_github
  openai = { icon = "\u{ec81}" }, -- nf-cod-openai
  agent = { icon = "🤖" },
}
