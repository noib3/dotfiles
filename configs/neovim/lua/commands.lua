local vim_add_command = vim.api.nvim_add_user_command
local vim_echo = vim.api.nvim_echo
local vim_loop = vim.loop

---@type userdata
local rn_start_handle

---`:h nvim_add_user_command`
---@diagnostic disable: duplicate-doc-class
---@class CmdOpts
---@field args   string
---@field bang   boolean
---@field line1  number
---@field line2  number
---@field range  number
---@field count  number
---@field reg    string
---@field mods   string

---@param msg  string
---@param type  '"Info"' | '"Warning"' | '"Error"'
local echo = function(msg, type)
  local hlgroup =
    (type == 'Info' and 'Question')
    or (type == 'Warning' and 'ErrorMsg')
    or (type == 'Error' and 'WarningMsg')

  vim_echo(
    {
      {'React Native: ', hlgroup},
      {msg, 'Normal'},
    },
    true,
    {}
  )
end

---@param opts  CmdOpts
local rn_start = function(opts)
  local cmd = opts.args or 'npx react-native'
  rn_start_handle, _ = vim_loop.spawn(cmd, { args = {'start'} })
  echo('Started Metro', 'Info')
end

local rn_stop = function()
  local ret = rn_start_handle:kill('SIGINT')
  echo('Stopped Metro?', 'Info')
  print(ret)
end

---@param opts  CmdOpts
local rn_run_android = function(opts)
  local cmd = opts.args or 'npx react-native'
  rn_start_handle, _ = vim_loop.spawn(cmd, { args = {'run-android'} })
end

local setup = function()
  vim_add_command('RnStart', rn_start, { nargs = '*' })
  vim_add_command('RnStop', rn_stop, {})
  vim_add_command('RnRunAndroid', rn_run_android, { nargs = '*' })
end

return {
  setup = setup,
}

-- https://github.com/luvit/luv/blob/master/docs.md#uvspawnfile-options-onexit
-- https://teukka.tech/vimloop.html
