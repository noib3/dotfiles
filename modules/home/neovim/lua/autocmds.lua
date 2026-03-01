---@param name string
---@return number
local create_augroup = function(name)
  return vim.api.nvim_create_augroup(name, { clear = true })
end

--- Returns an iterator over the windows currently displaying the given buffer.
--- @param buf number
local buf_get_wins = function(buf)
  return vim
    .iter(vim.api.nvim_list_wins())
    :filter(function(win) return vim.api.nvim_win_get_buf(win) == buf end)
end

vim.api.nvim_create_autocmd("VimResized", {
  group = create_augroup("noib3/rebalance-splits"),
  desc = "Rebalances window splits when terminal is resized",
  command = "wincmd =",
})

vim.api.nvim_create_autocmd({ "VimLeave", "VimSuspend" }, {
  group = create_augroup("noib3/reset-cursor"),
  desc = "Resets the cursor to a vertical bar before exiting Neovim",
  command = "set guicursor=a:ver25",
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
  callback = function()
    vim.opt_local.statusline = "%{b:term_title}"
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    if vim.startswith(vim.api.nvim_buf_get_name(0), "term://") then
      vim.cmd("startinsert")
    end
  end,
})

vim.api.nvim_create_autocmd("User", {
  group = create_augroup("noib3/handle-nvim-launch-in-terminal"),
  pattern = "NvimLaunchedFromEmbeddedTerminal",
  callback = function(ev)
    local term_buf = ev.buf
    assert(vim.bo[term_buf].buftype == "terminal")

    local filenames = ev.data
    local file_buf

    if #filenames == 0 then
      vim.cmd.enew()
      file_buf = vim.api.nvim_get_current_buf()
    else
      -- Create new buffers for each file.
      for _, filename in ipairs(filenames) do
        local buf = vim.fn.bufadd(filename)
        vim.api.nvim_set_option_value("buflisted", true, { buf = buf })
        vim.fn.bufload(buf)
        -- Set the buffer's filetype.
        local ft = vim.filetype.match({ buf = buf, filename = filename })
        if ft and ft ~= "" then
          vim.api.nvim_buf_call(
            buf,
            function() vim.cmd("setfiletype " .. ft) end
          )
        end
        if not file_buf then file_buf = buf end
      end
      -- Display the first file in all the windows currently showing the
      -- terminal.
      for win in buf_get_wins(term_buf) do
        vim.api.nvim_win_set_buf(win, file_buf)
      end
    end

    -- Unlist the terminal buffer (to keep up the illusion that the newly opened
    -- file has "swallowed" the terminal).
    vim.bo[term_buf].buflisted = false

    -- The list of windows currently displaying the opened file.
    local file_wins = {}

    -- Keep the list updated.
    vim.api.nvim_create_autocmd({ "BufWinEnter", "BufWinLeave" }, {
      buffer = file_buf,
      callback = function() file_wins = buf_get_wins(file_buf):totable() end,
    })

    vim.api.nvim_create_autocmd("BufDelete", {
      buffer = file_buf,
      once = true,
      callback = function()
        -- Return early if the original terminal buffer has since been deleted.
        if not vim.api.nvim_buf_is_valid(term_buf) then return end
        -- Re-list the terminal buffer to make it show up in buffer lists again.
        vim.bo[term_buf].buflisted = true
        -- Restore insert mode in the terminal.
        vim.api.nvim_buf_call(term_buf, vim.cmd.startinsert)
        -- Display the terminal on all the windows that were displaying the
        -- deleted buffer (scheduled to ensure BufDelete has fully completed).
        vim.schedule(function()
          for _, win in ipairs(file_wins) do
            vim.api.nvim_win_set_buf(win, term_buf)
          end
        end)
      end,
    })
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
    local palette = require("generated.palette")
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

local format_rgb = function(r, g, b)
  return string.format("rgb:%02x/%02x/%02x", r, g, b)
end

local send_term_reply = function(ev, reply)
  local chan = vim.bo[ev.buf].channel
  if type(chan) == "number" and chan > 0 then
    vim.api.nvim_chan_send(chan, reply)
  end
end

local rgb_from_number = function(n)
  local r = math.floor(n / 0x10000) % 0x100
  local g = math.floor(n / 0x100) % 0x100
  local b = n % 0x100
  return r, g, b
end

local rgb_from_color_name = function(color)
  if type(color) ~= "string" then return nil end

  if color:match("^#%x%x%x%x%x%x$") then
    local n = tonumber(color:sub(2), 16)
    if n then return rgb_from_number(n) end
    return nil
  end

  local n = vim.api.nvim_get_color_by_name(color)
  if type(n) ~= "number" or n < 0 then return nil end
  return rgb_from_number(n)
end

vim.api.nvim_create_autocmd("TermRequest", {
  group = create_augroup("noib3/reply-osc4"),
  desc = "Replies to OSC 4 color queries in :terminal",
  callback = function(ev)
    local seq = ev.data and ev.data.sequence or ""
    local idx = seq:match("^\27%]4;(%d+);%?$")
      or seq:match("^\27%]4;(%d+);%?\7$")
      or seq:match("^\27%]4;(%d+);%?\27\\$")
    idx = tonumber(idx)
    if not idx or idx < 0 or idx > 15 then return end

    local r, g, b = rgb_from_color_name(vim.g["terminal_color_" .. idx])
    if not r or not g or not b then return end

    local reply = string.format("\27]4;%d;%s\7", idx, format_rgb(r, g, b))
    send_term_reply(ev, reply)
  end,
})

vim.api.nvim_create_autocmd("TermRequest", {
  group = create_augroup("noib3/reply-osc10"),
  desc = "Replies to OSC 10 color queries in :terminal",
  callback = function(ev)
    local seq = ev.data and ev.data.sequence or ""
    if
      seq ~= "\27]10;?"
      and not seq:match("^\27%]10;%?\7$")
      and not seq:match("^\27%]10;%?\27\\$")
    then
      return
    end

    local normal = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
    if type(normal.fg) ~= "number" then return end

    local r, g, b = rgb_from_number(normal.fg)
    local reply = string.format("\27]10;%s\7", format_rgb(r, g, b))
    send_term_reply(ev, reply)
  end,
})

vim.api.nvim_create_autocmd("TermRequest", {
  group = create_augroup("noib3/reply-osc11"),
  desc = "Replies to OSC 11 color queries in :terminal",
  callback = function(ev)
    local seq = ev.data and ev.data.sequence or ""
    if
      seq ~= "\27]11;?"
      and not seq:match("^\27%]11;%?\7$")
      and not seq:match("^\27%]11;%?\27\\$")
    then
      return
    end

    local normal = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
    if type(normal.bg) ~= "number" then return end

    local r, g, b = rgb_from_number(normal.bg)
    local reply = string.format("\27]11;%s\7", format_rgb(r, g, b))
    send_term_reply(ev, reply)
  end,
})
