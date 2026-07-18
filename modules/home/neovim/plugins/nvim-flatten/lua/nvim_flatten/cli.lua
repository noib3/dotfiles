local fallback_exit_code = 125
local fallback = function() os.exit(fallback_exit_code) end

local original_args = {}
for index = 1, #arg do
  original_args[index] = arg[index]
end

if not vim.env.NVIM or vim.env.NVIM == "" then fallback() end

local can_flatten = true
local after_double_dash = false
local commands = {}
local file_args = {}
local index = 1

while index <= #original_args do
  local value = original_args[index]

  if after_double_dash then
    file_args[#file_args + 1] = value
  elseif value == "--" then
    after_double_dash = true
  elseif value == "+" then
    commands[#commands + 1] = "$"
  elseif vim.startswith(value, "+") then
    commands[#commands + 1] = value:sub(2)
  elseif value == "-c" then
    index = index + 1
    if index > #original_args then
      can_flatten = false
      break
    end
    commands[#commands + 1] = original_args[index]
  elseif vim.startswith(value, "-c") then
    commands[#commands + 1] = value:sub(3)
  elseif vim.startswith(value, "-") then
    can_flatten = false
    break
  else
    file_args[#file_args + 1] = value
  end

  index = index + 1
end

if not can_flatten then fallback() end

local filepaths = vim
  .iter(file_args)
  :map(function(path) return vim.fs.abspath(path) end)
  :totable()

local wrapper_pid = vim.uv.os_getpid()
local finished = false
local signal = assert(vim.uv.new_signal())

signal:start(vim.uv.constants.SIGUSR1, function() finished = true end)

local launch_code = [[
local wrapper_pid, filepaths, commands, environment = ...
local done = function()
  pcall(vim.uv.kill, wrapper_pid, vim.uv.constants.SIGUSR1)
end

vim.schedule(function()
  local ok, err = pcall(vim.api.nvim_exec_autocmds, "User", {
    pattern = "NvimFlattenLaunch",
    modeline = false,
    data = {
      filepaths = filepaths,
      commands = commands,
      environment = environment,
      on_done = done,
    },
  })

  if not ok then
    vim.notify(
      ("nvim-flatten: failed to launch flattened buffer: %s"):format(err),
      vim.log.levels.ERROR
    )
    done()
  end
end)

return true
]]

local ok, channel = pcall(vim.fn.sockconnect, "pipe", vim.env.NVIM, {
  rpc = true,
})

if ok and type(channel) == "number" and channel > 0 then
  ok = pcall(
    vim.rpcrequest,
    channel,
    "nvim_exec_lua",
    launch_code,
    { wrapper_pid, filepaths, commands, vim.fn.environ() }
  )
  pcall(vim.fn.chanclose, channel)
else
  ok = false
end

if not ok then
  signal:stop()
  signal:close()
  fallback()
end

vim.wait(vim._maxint, function() return finished end, 50)

signal:stop()
signal:close()
