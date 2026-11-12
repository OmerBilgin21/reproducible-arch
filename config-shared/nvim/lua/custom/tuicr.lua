local M = {}

local CLAUDE_PROMPT = table.concat({
  "/custom-review",
  "When the review is done, also post every finding into the tuicr session that is open for this repository.",
  'Get its slug from `tuicr review list --repo .` and use the entry with "active": true; ask me if there is not exactly one.',
  'For each finding run `tuicr review add --session <slug> --target-file <path> --line <n> --end-line <n> --side new --type <type> --username Claude "<finding>"`,',
  "with type issue for critical and warning findings and suggestion for suggestions.",
  "Then run `tuicr review comments --session <slug>` and check that every comment sits on a line that is part of the diff.",
}, " ")

local PASSTHROUGH = { "<C-n>", "<C-p>", "<C-t>", "<C-g>", "<C-b>", "<C-a>", "<S-Tab>", "<M-Left>", "<M-Right>" }

local state = {
  tab = nil,
  tuicr_buf = nil,
  claude_buf = nil,
}

local function is_valid(buf)
  return buf ~= nil and vim.api.nvim_buf_is_valid(buf)
end

local function delete(buf)
  if is_valid(buf) then
    vim.api.nvim_buf_delete(buf, { force = true })
  end
end

local function start_term(cmd, on_exit)
  local buf = vim.api.nvim_get_current_buf()
  vim.fn.jobstart(cmd, {
    term = true,
    on_exit = function()
      vim.schedule(function()
        on_exit(buf)
      end)
    end,
  })
  vim.bo[buf].buflisted = false
  vim.api.nvim_create_autocmd("BufEnter", { buffer = buf, command = "startinsert" })
  vim.cmd.startinsert()
  return buf
end

local function teardown()
  local tab, tuicr_buf, claude_buf = state.tab, state.tuicr_buf, state.claude_buf
  state.tab, state.tuicr_buf, state.claude_buf = nil, nil, nil
  if tab and vim.api.nvim_tabpage_is_valid(tab) and #vim.api.nvim_list_tabpages() > 1 then
    vim.cmd("tabclose " .. vim.api.nvim_tabpage_get_number(tab))
  end
  delete(claude_buf)
  delete(tuicr_buf)
end

local function claude_win()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(state.tab)) do
    if vim.api.nvim_win_get_buf(win) == state.claude_buf then
      return win
    end
  end
end

local function show_claude()
  local reuse = is_valid(state.claude_buf)
  local buf = reuse and state.claude_buf or vim.api.nvim_create_buf(false, false)
  vim.api.nvim_open_win(buf, true, { split = "right", win = -1, width = math.floor(vim.o.columns * 0.3) })
  if not reuse then
    state.claude_buf = start_term({ "claude", CLAUDE_PROMPT }, delete)
  end
end

function M.in_tab()
  return state.tab ~= nil and state.tab == vim.api.nvim_get_current_tabpage()
end

function M.toggle_claude()
  local win = is_valid(state.claude_buf) and claude_win()
  if win then
    vim.api.nvim_win_hide(win)
    return
  end
  show_claude()
end

function M.open(args)
  if state.tab and vim.api.nvim_tabpage_is_valid(state.tab) then
    vim.api.nvim_set_current_tabpage(state.tab)
    return
  end

  vim.cmd.tabnew()
  state.tab = vim.api.nvim_get_current_tabpage()
  vim.t.name = "tuicr"
  local tuicr_win = vim.api.nvim_get_current_win()

  state.tuicr_buf = start_term(vim.list_extend({ "tuicr" }, args or {}), function(buf)
    if buf == state.tuicr_buf then
      teardown()
    end
  end)
  for _, lhs in ipairs(PASSTHROUGH) do
    vim.keymap.set("t", lhs, lhs, { buffer = state.tuicr_buf })
  end

  show_claude()
  vim.api.nvim_set_current_win(tuicr_win)
end

vim.api.nvim_create_autocmd("TabClosed", {
  group = vim.api.nvim_create_augroup("Tuicr", { clear = true }),
  callback = function()
    if state.tab and not vim.api.nvim_tabpage_is_valid(state.tab) then
      teardown()
    end
  end,
})

return M
