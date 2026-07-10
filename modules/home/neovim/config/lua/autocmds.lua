local terminal = require("terminal")

---@param name string
---@return number
local create_augroup = function(name)
  return vim.api.nvim_create_augroup(name, { clear = true })
end

vim.api.nvim_create_autocmd("VimResized", {
  group = create_augroup("noib3/rebalance-splits"),
  desc = "Rebalances window splits when terminal is resized",
  command = "wincmd =",
})

vim.api.nvim_create_autocmd({ "VimLeave", "VimSuspend" }, {
  group = create_augroup("noib3/reset-cursor"),
  desc = "Resets the cursor to a vertical one before exiting Neovim",
  command = "set guicursor=a:ver25-blinkon0",
})

vim.api.nvim_create_autocmd("BufWritePre", {
  group = create_augroup("noib3/remove-trailing-whitespace-on-save"),
  desc = "Removes trailing whitespace and trailing newlines on save",
  callback = function()
    local cur_search = vim.fn.getreg("/")
    local cur_view = vim.fn.winsaveview()
    vim.cmd([[%s/\s\+$//e]])
    vim.cmd([[%s/\($\n\s*\)\+\%$//e]])
    vim.fn.setreg("/", cur_search)
    vim.fn.winrestview(cur_view)
  end,
})

vim.api.nvim_create_autocmd("TermOpen", {
  group = create_augroup("noib3/setup-terminal"),
  desc = "Disables line numbers and enters insert mode in terminals",
  callback = function(ev)
    terminal.register_base(ev.buf)
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    if vim.startswith(vim.api.nvim_buf_get_name(0), "term://") then
      vim.cmd("startinsert")
    end
  end,
})

local closing_last_terminal = false

vim.api.nvim_create_autocmd("BufDelete", {
  group = create_augroup("noib3/track-closing-terminal"),
  callback = function(ev)
    local is_empty_buffer = function(buf)
      return vim.bo[buf].buftype == "" and vim.api.nvim_buf_get_name(buf) == ""
    end

    if vim.bo[ev.buf].buftype ~= "terminal" then return end

    closing_last_terminal = vim.iter(vim.fn.getbufinfo({ buflisted = 1 })):all(
      function(info) return info.bufnr == ev.buf or is_empty_buffer(info.bufnr) end
    )
  end,
})

vim.api.nvim_create_autocmd("TermClose", {
  group = create_augroup("noib3/quit-on-last-terminal-exited"),
  callback = function()
    if not closing_last_terminal then return end
    vim.schedule(function() vim.cmd("q") end)
  end,
})

vim.api.nvim_create_autocmd("TermRequest", {
  group = create_augroup("noib3/respond-to-terminal-osc52-clipboard-queries"),
  desc = "Answers OSC 52 clipboard read queries",
  callback = function(ev)
    local seq = ev.data and ev.data.sequence or ""
    local selectors = seq:match("^\27%]52;([^;]*);%?$")
    if not selectors then return end

    local channel = vim.bo[ev.buf].channel
    if channel == 0 then return end

    local is_primary_selection = selectors ~= "" and selectors:match("^[p]+$")
    local register = is_primary_selection and "*" or "+"
    local ok, contents = pcall(vim.fn.getreg, register)
    assert(type(contents) == "string")

    if not ok then
      vim.notify(
        ("OSC 52 clipboard read failed: %s"):format(contents),
        vim.log.levels.WARN
      )
      return
    end

    local response = ("\27]52;%s;%s%s"):format(
      selectors,
      vim.base64.encode(contents),
      ev.data.terminator
    )
    vim.api.nvim_chan_send(channel, response)
  end,
})

vim.api.nvim_create_autocmd("TermRequest", {
  group = create_augroup("noib3/track-shell-prompt"),
  desc = "Tracks when terminals are at an OSC 133 shell prompt",
  callback = function(ev)
    local seq = ev.data and ev.data.sequence or ""
    local marker = seq:match("^\27%]133;([ABCD])")
    if not marker then return end
    vim.b[ev.buf].terminal_shell_prompt_active = marker == "B"
  end,
})

local nvim_flatten_group = create_augroup("noib3/nvim-flatten")

vim.api.nvim_create_autocmd("User", {
  group = nvim_flatten_group,
  pattern = "NvimFlattenWillSwallow",
  desc = "Hides terminals while recursive nvim launches replace them",
  callback = function()
    if vim.bo.buftype == "terminal" then vim.bo.buflisted = false end
  end,
})

vim.api.nvim_create_autocmd("User", {
  group = nvim_flatten_group,
  pattern = "NvimFlattenDidShow",
  desc = "Relists terminals after recursive nvim launches return to them",
  callback = function()
    if vim.bo.buftype == "terminal" then vim.bo.buflisted = true end
  end,
})

vim.api.nvim_create_autocmd("BufAdd", {
  group = create_augroup("noib3/disable-wrapping-in-lock-files"),
  pattern = "*.lock,lazy-lock.json",
  desc = "Disable soft wrapping in lock files",
  callback = function() vim.wo.wrap = false end,
})

vim.api.nvim_create_autocmd("ColorScheme", {
  group = create_augroup("noib3/set-cursor-hl-group"),
  desc = "Sets the Cursor highlight group to be the opposite of Normal",
  callback = function()
    local normal = vim.api.nvim_get_hl(0, { name = "Normal" })
    vim.api.nvim_set_hl(0, "Cursor", {
      fg = normal.bg,
      bg = normal.fg,
    })
  end,
})

vim.api.nvim_create_autocmd("ColorScheme", {
  group = create_augroup("noib3/set-terminal-colors"),
  desc = "Sets terminal colors from the colorscheme palette",
  callback = function()
    local palette = require("palette")
    -- Normal colors.
    vim.g.terminal_color_0 = palette.normal.black
    vim.g.terminal_color_1 = palette.normal.red
    vim.g.terminal_color_2 = palette.normal.green
    vim.g.terminal_color_3 = palette.normal.yellow
    vim.g.terminal_color_4 = palette.normal.blue
    vim.g.terminal_color_5 = palette.normal.magenta
    vim.g.terminal_color_6 = palette.normal.cyan
    vim.g.terminal_color_7 = palette.normal.white
    -- Bright colors.
    vim.g.terminal_color_8 = palette.bright.black
    vim.g.terminal_color_9 = palette.bright.red
    vim.g.terminal_color_10 = palette.bright.green
    vim.g.terminal_color_11 = palette.bright.yellow
    vim.g.terminal_color_12 = palette.bright.blue
    vim.g.terminal_color_13 = palette.bright.magenta
    vim.g.terminal_color_14 = palette.bright.cyan
    vim.g.terminal_color_15 = palette.bright.white
  end,
})
