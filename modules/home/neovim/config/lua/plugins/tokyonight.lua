if vim.env.COLORSCHEME ~= "tokyonight" then return end

vim.g.tokyonight_style = "night"
vim.g.tokyonight_transparent = true
vim.cmd("colorscheme tokyonight-night")
