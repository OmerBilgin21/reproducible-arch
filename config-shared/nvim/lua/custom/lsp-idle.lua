local M = {}

local IDLE_MS = 5 * 60 * 1000

local timer = nil
local slept = {}
local armed = true

local function notify(action, names)
  vim.notify(("lsp: %s %s"):format(action, table.concat(names, ", ")), vim.log.levels.INFO)
end

local function collect()
  local seen = {}
  local names = {}

  for _, client in ipairs(vim.lsp.get_clients()) do
    if not seen[client.name] and vim.lsp.is_enabled(client.name) then
      seen[client.name] = true
      names[#names + 1] = client.name
    end
  end

  return names
end

local function stop_timer()
  if timer then
    timer:stop()
    timer:close()
    timer = nil
  end
end

function M.sleep()
  if #slept > 0 then
    return
  end

  local names = collect()
  if #names == 0 then
    return
  end

  slept = names
  vim.lsp.enable(names, false)
  notify("slept", names)
end

function M.wake()
  if #slept == 0 then
    return
  end

  local names = slept
  slept = {}
  vim.lsp.enable(names, true)
  notify("restarting", names)
end

local function start_timer()
  stop_timer()

  timer = vim.uv.new_timer()
  timer:start(
    IDLE_MS,
    0,
    vim.schedule_wrap(function()
      stop_timer()
      M.sleep()
    end)
  )
end

function M.setup()
  local group = vim.api.nvim_create_augroup("LspIdle", { clear = true })

  vim.api.nvim_create_autocmd("FocusLost", {
    group = group,
    callback = function()
      if armed then
        start_timer()
      end
    end,
  })

  vim.api.nvim_create_autocmd("FocusGained", {
    group = group,
    callback = function()
      stop_timer()
      M.wake()
    end,
  })

  vim.api.nvim_create_user_command("LspIdleSleep", function()
    stop_timer()
    M.sleep()
  end, { desc = "Stop language servers now" })

  vim.api.nvim_create_user_command("LspIdleWake", function()
    stop_timer()
    M.wake()
  end, { desc = "Restart language servers stopped by LspIdle" })

  vim.api.nvim_create_user_command("LspIdleToggle", function()
    armed = not armed
    if not armed then
      stop_timer()
    end
    vim.notify(("lsp idle: %s"):format(armed and "armed" or "disarmed"), vim.log.levels.INFO)
  end, { desc = "Toggle automatic shutdown of language servers when unfocused" })
end

return M
