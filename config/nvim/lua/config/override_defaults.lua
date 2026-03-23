local M = {}

local map_kind = {
  F = 3,
  C = 5,
  A = 6,
  T = 7,
  R = 14,
  S = 19,
}

function M.tabline()
  local s = ""
  for i = 1, vim.fn.tabpagenr("$") do
    if i == vim.fn.tabpagenr() then
      s = s .. "%#TabLineSel#"
    else
      s = s .. "%#TabLine#"
    end
    s = s .. "%" .. i .. "T"
    s = s .. " " .. i .. " "
    local buflist = vim.fn.tabpagebuflist(i)
    local winnr = vim.fn.tabpagewinnr(i)
    local bufname = vim.fn.bufname(buflist[winnr])
    local filename = bufname ~= "" and vim.fn.fnamemodify(bufname, ":t") or "[No Name]"
    s = s .. filename .. " "
  end
  s = s .. "%#TabLineFill#%T"
  return s
end

function M.foldtext()
  local start_line = vim.fn.getline(vim.v.foldstart)
  local end_line = vim.fn.getline(vim.v.foldend)
  local indent = start_line:match("^%s*") or ""
  local text = start_line:gsub("^%s*", ""):gsub("%s*$", "")

  if text == "" then
    text = end_line:gsub("^%s*", ""):gsub("%s*$", "")
  end

  local line_count = vim.v.foldend - vim.v.foldstart + 1
  local suffix = (" %s [%d lines]"):format(vim.v.folddashes, line_count)
  local available_width = vim.api.nvim_win_get_width(0)
    - vim.fn.strdisplaywidth(indent)
    - vim.fn.strdisplaywidth(suffix)

  if available_width < 0 then
    available_width = 0
  end

  if vim.fn.strdisplaywidth(text) > available_width then
    local truncated = math.max(available_width - 3, 0)
    text = vim.fn.strcharpart(text, 0, truncated)
    if available_width >= 3 then
      text = text .. "..."
    end
  end

  local padding = math.max(available_width - vim.fn.strdisplaywidth(text), 1)
  return indent .. text .. string.rep(" ", padding) .. suffix
end

-- begin dadbod completion override

function M.new()
  return setmetatable({}, { __index = M })
end

function M:get_trigger_characters()
  return { '"', "`", "[", "]", "." }
end

function M:enabled()
  return vim.tbl_contains({ "sql", "mysql", "plsql" }, vim.bo.filetype)
end

function M:get_completions(ctx, callback)
  local cursor_col = ctx.cursor[2]
  local line = ctx.line
  local word_start = cursor_col + 1

  local triggers = self:get_trigger_characters()
  while word_start > 1 do
    local char = line:sub(word_start - 1, word_start - 1)
    if vim.tbl_contains(triggers, char) or char:match("%s") then
      break
    end
    word_start = word_start - 1
  end

  local input = line:sub(word_start, cursor_col)

  -- Only pass the first character so dadbod returns a broad candidate set
  -- (satisfies the non-empty guard), then blink handles fuzzy ranking.
  local base = input:sub(1, 1)

  local results = vim.api.nvim_call_function("vim_dadbod_completion#omni", { 0, base })

  if not results then
    callback({ context = ctx, is_incomplete_forward = true, is_incomplete_backward = true, items = {} })
    return function() end
  end

  local by_word = {}
  for _, item in ipairs(results) do
    local key = item.word .. item.kind
    if by_word[key] == nil then
      by_word[key] = item
    end
  end

  local items = {}
  for _, item in pairs(by_word) do
    table.insert(items, {
      label = item.abbr or item.word,
      dup = 0,
      insertText = item.word,
      labelDetails = item.menu and { description = item.menu } or nil,
      documentation = item.info or "",
      kind = map_kind[item.kind] or vim.lsp.protocol.CompletionItemKind.Text,
    })
  end

  callback({
    context = ctx,
    is_incomplete_forward = true,
    is_incomplete_backward = true,
    items = items,
  })

  return function() end
end

-- end dadbod completion override

return M
