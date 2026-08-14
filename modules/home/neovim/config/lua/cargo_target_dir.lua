local resolver = vim.fn.exepath("cargo-target-dir-env")
if resolver == "" then return end

local dynamic_marker = "__cargo_target_dir_dynamic"

---@param directory string
local update = function(directory)
  if vim.env.CARGO_TARGET_DIR and not vim.env[dynamic_marker] then return end

  local result = vim.system({ resolver, directory }, { text = true }):wait()

  if result.code == 0 and result.stdout ~= "" then
    vim.env.CARGO_TARGET_DIR = result.stdout
    vim.env[dynamic_marker] = "1"
    return
  end

  if result.code == 1 then
    if vim.env[dynamic_marker] then
      vim.env.CARGO_TARGET_DIR = nil
      vim.env[dynamic_marker] = nil
    end
    return
  end

  local error_message = vim.trim(result.stderr or "")
  if error_message == "" then
    error_message = ("cargo-target-dir-env exited with status %d"):format(
      result.code
    )
  end
  vim.notify_once(error_message, vim.log.levels.WARN)
end

vim.api.nvim_create_autocmd("DirChanged", {
  group = vim.api.nvim_create_augroup("noib3/update-cargo-target-dir", {
    clear = true,
  }),
  desc = "Updates CARGO_TARGET_DIR for Neovim's working directory",
  callback = function(ev) update(ev.cwd) end,
})

update(vim.fn.getcwd())
