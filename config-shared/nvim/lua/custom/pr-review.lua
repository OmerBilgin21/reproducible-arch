local M = {}

local MODEL = "sonnet"

local SIGNS = {
  mine = "▌",
  claude = "◇",
  viable = "◆",
}

local SPINNER = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }

local HL = {
  mine = "PrReviewMine",
  claude = "PrReviewClaude",
  viable = "PrReviewViable",
  more = "PrReviewMore",
  progress = "PrReviewProgress",
}

local HL_LINKS = {
  [HL.mine] = "DiagnosticInfo",
  [HL.claude] = "DiagnosticWarn",
  [HL.viable] = "DiagnosticOk",
  [HL.more] = "Comment",
  [HL.progress] = "DiagnosticInfo",
}

local PROMPT = [[
You are reviewing a git diff for a pull request. The unified diff is on stdin.

The diff was produced with `git diff <merge-base>`, so every hunk is a genuine
change made on this branch. Nothing in it comes from the base branch having
moved ahead.

Rules:
- Only comment on lines that are part of the diff: added or modified lines,
  the ones prefixed with `+` in the hunk bodies. Never comment on unchanged
  context lines, on removed lines, or on any other part of the file.
- Report every line number as it appears in the NEW version of the file: the
  absolute 1-based line number you get by counting in the post-image, which is
  what the `+c,d` side of each `@@ -a,b +c,d @@` header anchors. Never report
  diff-relative offsets, and never report line numbers from the old version.
- `file` is the path relative to the repository root, exactly as it appears on
  the `+++ b/` side of the diff header.
- `end_line` must be >= `line`. For a comment about a single line, set
  `end_line` equal to `line`.
- Emit only actionable review comments: bugs, correctness problems, security
  issues, unhandled edge cases, performance traps, API misuse, and violations
  of conventions visible in the surrounding code. Every comment must say what
  is wrong and what to do about it.
- Do not emit praise, summaries, restatements of what the code does, meta-notes
  about the review itself, formatting nitpicks a formatter would fix, or
  comments hedged as "consider whether...". If nothing is actionable, return an
  empty array.
- `comment` is plain markdown. No headings. Put code suggestions in fenced code
  blocks.

You may use Read, Grep, and Glob to inspect surrounding code for context, but
you may still only comment on lines that are in the diff.

Return JSON matching the provided schema and nothing else.
]]

local SCHEMA = {
  type = "object",
  properties = {
    comments = {
      type = "array",
      items = {
        type = "object",
        properties = {
          file = { type = "string" },
          line = { type = "integer" },
          end_line = { type = "integer" },
          comment = { type = "string" },
        },
        required = { "file", "line", "end_line", "comment" },
        additionalProperties = false,
      },
    },
  },
  required = { "comments" },
  additionalProperties = false,
}

M.state = {
  initialized = false,
  ns = nil,
  ns_ui = nil,
  augroup = nil,
  root = nil,
  base = nil,
  merge_base = nil,
  pr = nil,
  job = nil,
  raw = nil,
  next_id = 1,
  comments = {},
  by_path = {},
  by_mark = {},
  attached = {},
  progress = {},
}

local state = M.state

local function notify(msg, level)
  vim.notify("pr-review: " .. msg, level or vim.log.levels.INFO)
end

local function run(cmd, opts)
  opts = vim.tbl_extend("force", { text = true, cwd = state.root }, opts or {})
  local ok, res = pcall(function()
    return vim.system(cmd, opts):wait(opts.timeout or 15000)
  end)
  if not ok then
    return nil, tostring(res)
  end
  if res.code ~= 0 then
    return nil, vim.trim(res.stderr or "") ~= "" and vim.trim(res.stderr) or ("exit " .. res.code)
  end
  return vim.trim(res.stdout or ""), nil
end

local function resolve_repo()
  if state.root then
    return state.root
  end
  local ok, out = pcall(function()
    return vim.system({ "git", "rev-parse", "--show-toplevel" }, { text = true }):wait(5000)
  end)
  if not ok or out.code ~= 0 then
    return nil
  end
  local top = vim.trim(out.stdout)
  state.root = vim.fs.normalize(vim.uv.fs_realpath(top) or top)
  return state.root
end

local function resolve_base()
  if state.base then
    return state.base
  end
  local out = run({ "gh", "pr", "view", "--json", "baseRefName", "--jq", ".baseRefName" }, { timeout = 8000 })
  if out and out ~= "" then
    state.base = "origin/" .. out
    return state.base
  end
  out = run({ "git", "rev-parse", "--abbrev-ref", "origin/HEAD" })
  if out and out ~= "" then
    state.base = out
    return state.base
  end
  state.base = "origin/main"
  return state.base
end

local function under(path, root)
  local prefix = root .. "/"
  if path:sub(1, #prefix) == prefix then
    return path:sub(#prefix + 1)
  end
  return nil
end

local function rel_path(name)
  if not name or name == "" or not state.root then
    return nil
  end
  name = vim.fs.normalize(name)
  local direct = under(name, state.root)
  if direct then
    return direct
  end
  local real = vim.uv.fs_realpath(name)
  if not real then
    return nil
  end
  return under(vim.fs.normalize(real), state.root)
end

local function is_right_side(bufnr)
  local ok, lib = pcall(require, "diffview.lib")
  if not ok then
    return false
  end
  local view = lib.get_current_view()
  local entry = view and view.cur_entry
  if not entry then
    return false
  end
  local name = vim.api.nvim_buf_get_name(bufnr)
  if entry.path and rel_path(name) == entry.path then
    return true
  end
  local b = entry.layout and entry.layout.b
  return b ~= nil and b.file ~= nil and b.file.bufnr == bufnr
end

local function sign_for(comment)
  if comment.source == "mine" then
    return SIGNS.mine, HL.mine
  end
  if comment.status == "viable" then
    return SIGNS.viable, HL.viable
  end
  return SIGNS.claude, HL.claude
end

local function label_for(comment)
  return comment.source == "mine" and "you" or "claude"
end

local function rank(comment)
  if comment.source == "mine" then
    return 1
  end
  return comment.status == "viable" and 2 or 3
end

local function preview_text(body)
  local first = vim.split(body, "\n", { plain = true })[1] or ""
  first = vim.trim(first)
  if #first > 70 then
    first = first:sub(1, 69) .. "…"
  end
  return first
end

local function resolve_pos(comment)
  if comment.bufnr and comment.mark_id and vim.api.nvim_buf_is_valid(comment.bufnr) then
    local ok, mark = pcall(vim.api.nvim_buf_get_extmark_by_id, comment.bufnr, state.ns, comment.mark_id, {
      details = true,
    })
    if ok and mark and mark[1] then
      local line = mark[1] + 1
      local end_line = (mark[3] and mark[3].end_row and mark[3].end_row + 1) or line
      return line, math.max(end_line, line)
    end
  end
  return comment.line, comment.end_line
end

local function unplace(comment)
  if comment.bufnr and comment.mark_id and vim.api.nvim_buf_is_valid(comment.bufnr) then
    pcall(vim.api.nvim_buf_del_extmark, comment.bufnr, state.ns, comment.mark_id)
    local marks = state.by_mark[comment.bufnr]
    if marks then
      marks[comment.mark_id] = nil
    end
  end
  comment.bufnr = nil
  comment.mark_id = nil
end

local function place(comment, bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end
  unplace(comment)
  local count = vim.api.nvim_buf_line_count(bufnr)
  local row = math.min(math.max(comment.line, 1), count) - 1
  local end_row = math.min(math.max(comment.end_line, comment.line), count) - 1
  local ok, id = pcall(vim.api.nvim_buf_set_extmark, bufnr, state.ns, row, 0, {
    end_row = end_row,
    right_gravity = false,
    end_right_gravity = true,
    strict = false,
  })
  if not ok then
    notify("could not place a comment mark: " .. tostring(id), vim.log.levels.ERROR)
    return
  end
  comment.bufnr = bufnr
  comment.mark_id = id
  state.by_mark[bufnr] = state.by_mark[bufnr] or {}
  state.by_mark[bufnr][id] = comment.id
end

local function render_buf(bufnr)
  if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end
  vim.api.nvim_buf_clear_namespace(bufnr, state.ns_ui, 0, -1)

  local marks = state.by_mark[bufnr]
  if not marks then
    return
  end

  local rows = {}
  for _, id in pairs(marks) do
    local comment = state.comments[id]
    if comment then
      local line = resolve_pos(comment)
      rows[line] = rows[line] or {}
      table.insert(rows[line], comment)
    end
  end

  local count = vim.api.nvim_buf_line_count(bufnr)
  for line, group in pairs(rows) do
    table.sort(group, function(a, b)
      if rank(a) == rank(b) then
        return a.id < b.id
      end
      return rank(a) < rank(b)
    end)

    local head = group[1]
    local glyph, hl = sign_for(head)
    local sign = glyph
    if #group > 1 then
      sign = glyph .. (#group < 10 and tostring(#group) or "+")
    end

    local virt = {
      { (" %s %s: %s"):format(glyph, label_for(head), preview_text(head.body)), hl },
    }
    if #group > 1 then
      table.insert(virt, { ("  +%d more"):format(#group - 1), HL.more })
    end

    local opts = {
      sign_text = sign,
      sign_hl_group = hl,
      number_hl_group = hl,
      virt_text = virt,
      virt_text_pos = "eol",
      hl_mode = "combine",
    }
    local row = math.min(math.max(line, 1), count) - 1
    local ok = pcall(vim.api.nvim_buf_set_extmark, bufnr, state.ns_ui, row, 0, opts)
    if not ok then
      if not state.warned_signs then
        state.warned_signs = true
        notify("sign column rejected " .. vim.inspect(sign) .. ", falling back to virtual text", vim.log.levels.WARN)
      end
      opts.sign_text = nil
      opts.number_hl_group = nil
      pcall(vim.api.nvim_buf_set_extmark, bufnr, state.ns_ui, row, 0, opts)
    end
  end
end

local function render_all()
  for bufnr in pairs(state.by_mark) do
    render_buf(bufnr)
  end
end

local function attach_buf(bufnr, path)
  local ids = state.by_path[path]
  if not ids then
    return
  end
  for _, id in ipairs(ids) do
    local comment = state.comments[id]
    if comment and comment.bufnr ~= bufnr then
      place(comment, bufnr)
    end
  end
  render_buf(bufnr)
end

local function attach_all()
  for bufnr, path in pairs(state.attached) do
    if vim.api.nvim_buf_is_valid(bufnr) then
      attach_buf(bufnr, path)
    else
      state.attached[bufnr] = nil
    end
  end
end

local function register(comment)
  comment.id = state.next_id
  state.next_id = state.next_id + 1
  state.comments[comment.id] = comment
  state.by_path[comment.path] = state.by_path[comment.path] or {}
  table.insert(state.by_path[comment.path], comment.id)
  return comment
end

local function unregister(comment)
  unplace(comment)
  state.comments[comment.id] = nil
  local ids = state.by_path[comment.path]
  if ids then
    for i, id in ipairs(ids) do
      if id == comment.id then
        table.remove(ids, i)
        break
      end
    end
  end
end

local function float_size(lines, opts)
  local max_width = math.min(opts.max_width or 100, math.max(vim.o.columns - 8, 20))
  local max_height = math.min(
    opts.max_height or math.floor(vim.o.lines * 0.8),
    math.max(vim.o.lines - 6, 3)
  )

  local width = 0
  for _, line in ipairs(lines) do
    width = math.max(width, vim.fn.strdisplaywidth(line))
  end
  width = math.max(math.min(width, max_width), opts.min_width or 30)

  local height = 0
  for _, line in ipairs(lines) do
    height = height + math.max(1, math.ceil(vim.fn.strdisplaywidth(line) / width))
  end
  height = math.max(height, opts.min_height or 1)
  height = math.max(math.min(height, max_height), 1)

  return width, height
end

local function open_float(lines, opts)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  local width, height = float_size(lines, opts)
  local config = {
    relative = "editor",
    row = math.max(math.floor((vim.o.lines - height) / 2) - 1, 0),
    col = math.max(math.floor((vim.o.columns - width) / 2), 0),
    width = width,
    height = height,
    style = "minimal",
    border = "rounded",
    zindex = 150,
  }
  if opts.title then
    config.title = opts.title
    config.title_pos = "center"
  end
  if opts.footer then
    config.footer = opts.footer
    config.footer_pos = "center"
  end

  local win = vim.api.nvim_open_win(buf, opts.enter ~= false, config)
  vim.wo[win].wrap = true
  vim.wo[win].linebreak = true
  vim.bo[buf].filetype = opts.filetype or "markdown"

  return buf, win
end

local function open_composer(opts, on_accept)
  local lines = vim.split(opts.body or "", "\n", { plain = true })
  if #lines == 0 then
    lines = { "" }
  end

  local buf, win = open_float(lines, {
    title = opts.title,
    footer = " <CR> save · q cancel ",
    max_width = 78,
    min_height = 5,
  })
  vim.bo[buf].buftype = "acwrite"
  vim.bo[buf].modifiable = true
  pcall(vim.api.nvim_buf_set_name, buf, "pr-review://compose/" .. state.next_id)

  local done = false
  local function finish(accept)
    if done then
      return
    end
    done = true
    local text
    if accept then
      text = vim.trim(table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n"))
    end
    vim.bo[buf].modified = false
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
    if accept and text ~= "" then
      on_accept(text)
    elseif opts.on_cancel then
      opts.on_cancel()
    end
  end

  local function map(mode, lhs, accept)
    vim.keymap.set(mode, lhs, function()
      finish(accept)
    end, { buffer = buf, nowait = true, silent = true })
  end
  map("n", "<CR>", true)
  map({ "n", "i" }, "<C-s>", true)
  map("n", "q", false)
  map({ "n", "i" }, "<C-c>", false)

  vim.api.nvim_create_autocmd("BufWriteCmd", {
    buffer = buf,
    callback = function()
      finish(true)
    end,
  })
  vim.api.nvim_create_autocmd("WinClosed", {
    pattern = tostring(win),
    once = true,
    callback = function()
      finish(false)
    end,
  })

  if opts.insert then
    vim.cmd("startinsert")
  else
    pcall(vim.api.nvim_win_set_cursor, win, { #lines, 0 })
  end

  return buf, win
end

local function progress_text()
  local p = state.progress
  if p.done then
    return p.done
  end
  local elapsed = math.floor((vim.uv.now() - (p.started or vim.uv.now())) / 1000)
  return ("%s claude reviewing… %d:%02d"):format(SPINNER[p.frame or 1], math.floor(elapsed / 60), elapsed % 60)
end

local function progress_draw()
  local p = state.progress
  if not p.buf or not vim.api.nvim_buf_is_valid(p.buf) then
    return
  end
  local text = " " .. progress_text() .. " "
  vim.api.nvim_buf_set_lines(p.buf, 0, -1, false, { text })

  local config = {
    relative = "editor",
    anchor = "SE",
    row = math.max(vim.o.lines - vim.o.cmdheight - 1, 1),
    col = math.max(vim.o.columns - 1, 1),
    width = vim.fn.strdisplaywidth(text),
    height = 1,
    style = "minimal",
    border = "rounded",
    zindex = 200,
    focusable = false,
  }
  if p.win and vim.api.nvim_win_is_valid(p.win) then
    pcall(vim.api.nvim_win_set_config, p.win, config)
    return
  end
  config.noautocmd = true
  local ok, win = pcall(vim.api.nvim_open_win, p.buf, false, config)
  if not ok then
    return
  end
  p.win = win
  vim.wo[win].winhighlight = ("NormalFloat:%s,FloatBorder:%s"):format(HL.progress, HL.progress)
end

local function progress_close()
  local p = state.progress
  if p.timer then
    p.timer:stop()
    if not p.timer:is_closing() then
      p.timer:close()
    end
    p.timer = nil
  end
  if p.win and vim.api.nvim_win_is_valid(p.win) then
    pcall(vim.api.nvim_win_close, p.win, true)
  end
  if p.buf and vim.api.nvim_buf_is_valid(p.buf) then
    pcall(vim.api.nvim_buf_delete, p.buf, { force = true })
  end
  p.win, p.buf, p.done, p.started, p.frame = nil, nil, nil, nil, nil
end

local function progress_start()
  progress_close()
  local p = state.progress
  p.token = (p.token or 0) + 1
  p.started = vim.uv.now()
  p.frame = 1
  p.buf = vim.api.nvim_create_buf(false, true)
  progress_draw()

  p.timer = vim.uv.new_timer()
  p.timer:start(100, 100, function()
    vim.schedule(function()
      local q = state.progress
      if not q.timer or not q.buf then
        return
      end
      q.frame = q.frame % #SPINNER + 1
      progress_draw()
    end)
  end)
end

local function progress_finish(text)
  local p = state.progress
  if not p.buf then
    return
  end
  if p.timer then
    p.timer:stop()
    if not p.timer:is_closing() then
      p.timer:close()
    end
    p.timer = nil
  end
  p.done = text
  progress_draw()

  local token = p.token
  vim.defer_fn(function()
    if state.progress.token == token then
      progress_close()
    end
  end, 2500)
end

local function try_decode(s)
  if type(s) ~= "string" or s:match("^%s*$") then
    return nil
  end
  local ok, val = pcall(vim.json.decode, s, { luanil = { object = true, array = true } })
  if ok and type(val) == "table" then
    return val
  end
  return nil
end

local function scan_balanced(text, start_idx)
  local open = text:sub(start_idx, start_idx)
  local close = open == "[" and "]" or "}"
  local depth, in_str, esc = 0, false, false
  for i = start_idx, #text do
    local c = text:sub(i, i)
    if in_str then
      if esc then
        esc = false
      elseif c == "\\" then
        esc = true
      elseif c == '"' then
        in_str = false
      end
    elseif c == '"' then
      in_str = true
    elseif c == open then
      depth = depth + 1
    elseif c == close then
      depth = depth - 1
      if depth == 0 then
        return text:sub(start_idx, i)
      end
    end
  end
  return nil
end

local function extract_json(text)
  if type(text) ~= "string" then
    return nil
  end
  local direct = try_decode(text)
  if direct then
    return direct
  end
  for fenced in text:gmatch("```%w*\r?\n(.-)```") do
    local v = try_decode(fenced)
    if v then
      return v
    end
  end
  local i = 1
  while i <= #text do
    local s = text:find("[%[{]", i)
    if not s then
      break
    end
    local slice = scan_balanced(text, s)
    if slice then
      local v = try_decode(slice)
      if v then
        return v
      end
    end
    i = s + 1
  end
  return nil
end

local function to_list(decoded)
  if type(decoded) ~= "table" then
    return nil
  end
  if vim.islist(decoded) then
    return decoded
  end
  if type(decoded.comments) == "table" and vim.islist(decoded.comments) then
    return decoded.comments
  end
  return nil
end

local function has_traversal(path)
  for segment in vim.gsplit(path, "/", { plain = true }) do
    if segment == ".." then
      return true
    end
  end
  return false
end

local function normalize(items)
  local out, dropped, seen = {}, 0, {}
  for _, item in ipairs(items) do
    local valid = false
    if type(item) == "table" then
      local file = item.file or item.path
      local body = item.comment or item.body
      local line = tonumber(item.line)
      local end_line = tonumber(item.end_line)
      if type(file) == "string" and type(body) == "string" and line then
        file = (vim.trim(file):gsub("^%./", ""))
        body = vim.trim(body)
        if state.root and file:sub(1, 1) == "/" then
          local prefix = state.root .. "/"
          if file:sub(1, #prefix) == prefix then
            file = file:sub(#prefix + 1)
          end
        end
        line = math.floor(line)
        end_line = math.max(math.floor(end_line or line), line)
        if file ~= "" and body ~= "" and line >= 1 and file:sub(1, 1) ~= "/" and not has_traversal(file) then
          local key = file .. ":" .. line .. ":" .. body
          if not seen[key] then
            seen[key] = true
            table.insert(out, { file = file, line = line, end_line = end_line, comment = body })
          end
          valid = true
        end
      end
    end
    if not valid then
      dropped = dropped + 1
    end
  end
  return out, dropped
end

local function on_claude_done(res)
  state.job = nil
  local stdout = res.stdout or ""
  local stderr = vim.trim(res.stderr or "")
  state.raw = table.concat({ "--- stdout ---", stdout, "--- stderr ---", stderr }, "\n")

  local envelope = try_decode(stdout)
  local items

  if envelope then
    if envelope.is_error or (envelope.subtype and envelope.subtype ~= "success") then
      progress_finish("✗ claude error")
      notify("claude reported an error: " .. tostring(envelope.result or envelope.subtype), vim.log.levels.ERROR)
      return
    end
    items = to_list(envelope.structured_output) or to_list(extract_json(envelope.result))
  else
    if res.code ~= 0 then
      progress_finish("✗ claude exited " .. res.code)
      notify("claude exited " .. res.code .. (stderr ~= "" and (": " .. stderr) or "") .. " (:PrReviewLog)", vim.log.levels.ERROR)
      return
    end
    items = to_list(extract_json(stdout))
  end

  if not items then
    progress_finish("✗ could not parse output")
    notify("could not parse claude output (:PrReviewLog)", vim.log.levels.ERROR)
    return
  end

  local parsed, dropped = normalize(items)
  for _, item in ipairs(parsed) do
    register({
      source = "claude",
      status = "pending",
      path = item.file,
      line = item.line,
      end_line = item.end_line,
      body = item.comment,
    })
  end
  attach_all()

  local msg = ("claude returned %d comment%s"):format(#parsed, #parsed == 1 and "" or "s")
  if dropped > 0 then
    progress_finish(("⚠ %d comments, %d dropped"):format(#parsed, dropped))
    msg = msg .. (", %d dropped (:PrReviewLog)"):format(dropped)
  else
    progress_finish(("✓ %d comment%s"):format(#parsed, #parsed == 1 and "" or "s"))
  end
  notify(msg, dropped > 0 and vim.log.levels.WARN or vim.log.levels.INFO)
end

local function run_claude()
  local diff, err = run({
    "git",
    "--no-pager",
    "diff",
    "--no-ext-diff",
    "--no-color",
    "-U5",
    state.merge_base,
    "--",
  }, { timeout = 30000 })

  if not diff then
    notify("git diff failed: " .. tostring(err), vim.log.levels.ERROR)
    return
  end
  if diff == "" then
    notify("no changes against " .. state.base, vim.log.levels.WARN)
    return
  end

  state.job = vim.system({
    "claude",
    "-p",
    PROMPT,
    "--model",
    MODEL,
    "--output-format",
    "json",
    "--json-schema",
    vim.json.encode(SCHEMA),
    "--setting-sources",
    "project",
    "--strict-mcp-config",
    "--disable-slash-commands",
    "--allowedTools",
    "Read,Grep,Glob",
    "--tools",
    "Read,Grep,Glob",
  }, {
    cwd = state.root,
    text = true,
    stdin = diff,
  }, function(res)
    vim.schedule(function()
      on_claude_done(res)
    end)
  end)

  progress_start()
  notify("claude reviewing in the background…")
end

local function comments_at_cursor()
  local bufnr = vim.api.nvim_get_current_buf()
  local marks = state.by_mark[bufnr]
  if not marks then
    return {}
  end
  local row = vim.api.nvim_win_get_cursor(0)[1] - 1
  local found = vim.api.nvim_buf_get_extmarks(bufnr, state.ns, { row, 0 }, { row, -1 }, {
    details = true,
    overlap = true,
  })
  local out, seen = {}, {}
  for _, mark in ipairs(found) do
    local id = marks[mark[1]]
    local comment = id and state.comments[id]
    if comment and not seen[comment.id] then
      seen[comment.id] = true
      table.insert(out, comment)
    end
  end
  table.sort(out, function(a, b)
    if rank(a) == rank(b) then
      return a.id < b.id
    end
    return rank(a) < rank(b)
  end)
  return out
end

local function pick(list, cb)
  if #list == 0 then
    notify("no comment under cursor", vim.log.levels.WARN)
    return
  end
  if #list == 1 then
    cb(list[1])
    return
  end
  vim.ui.select(list, {
    prompt = "pr-review: which comment?",
    format_item = function(comment)
      return ("[%s] %s"):format(
        comment.source == "mine" and "you" or ("claude·" .. comment.status),
        preview_text(comment.body)
      )
    end,
  }, function(choice)
    if choice then
      cb(choice)
    end
  end)
end

local function set_viable(comment)
  if comment.source ~= "claude" then
    notify("that one is yours, it is already included", vim.log.levels.WARN)
    return
  end
  comment.status = "viable"
  render_buf(comment.bufnr)
end

local function drop(comment)
  local bufnr = comment.bufnr
  unregister(comment)
  render_buf(bufnr)
end

local function edit_body(comment, after)
  local what = comment.source == "mine" and "your comment" or "claude's comment"
  open_composer({
    title = (" reword %s · %s "):format(what, comment.path),
    body = comment.body,
    on_cancel = after,
  }, function(text)
    comment.body = text
    comment.edited = true
    if comment.source == "claude" and comment.status ~= "viable" then
      comment.status = "viable"
    end
    if comment.bufnr then
      render_buf(comment.bufnr)
    else
      render_all()
    end
    if after then
      after()
    end
  end)
end

local function open_peek(list)
  local lines, blocks = {}, {}
  for i, comment in ipairs(list) do
    if i > 1 then
      table.insert(lines, "")
    end
    local glyph = sign_for(comment)
    local head = comment.source == "mine" and (glyph .. " you")
      or ("%s claude · %s"):format(glyph, comment.status)
    if comment.edited then
      head = head .. ", reworded by you"
    end
    table.insert(lines, head)
    local first = #lines
    for _, body_line in ipairs(vim.split(comment.body, "\n", { plain = true })) do
      table.insert(lines, body_line)
    end
    table.insert(blocks, { first = first, last = #lines, id = comment.id })
  end

  local line = resolve_pos(list[1])
  local title = #list == 1 and (" %s:%d "):format(list[1].path, line)
    or (" %d comments · %s:%d "):format(#list, list[1].path, line)

  local buf, win = open_float(lines, {
    title = title,
    footer = " v viable · x discard · e reword · q close ",
  })

  local function current()
    local row = vim.api.nvim_win_get_cursor(win)[1]
    local id
    for _, block in ipairs(blocks) do
      if row >= block.first then
        id = block.id
      end
      if row >= block.first and row <= block.last then
        break
      end
    end
    return id and state.comments[id] or nil
  end

  local function close()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end

  local function reopen()
    local remaining = {}
    for _, comment in ipairs(list) do
      if state.comments[comment.id] then
        table.insert(remaining, comment)
      end
    end
    if #remaining > 0 then
      open_peek(remaining)
    end
  end

  local function act(fn)
    return function()
      local comment = current()
      if not comment then
        return
      end
      close()
      fn(comment)
    end
  end

  local function map(lhs, fn)
    vim.keymap.set("n", lhs, fn, { buffer = buf, nowait = true, silent = true })
  end
  map("q", close)
  map("<Esc>", close)
  map("v", act(function(comment)
    set_viable(comment)
    reopen()
  end))
  map("x", act(function(comment)
    drop(comment)
    reopen()
  end))
  map("e", act(function(comment)
    edit_body(comment, reopen)
  end))

  return buf, win
end

function M.add_comment()
  local bufnr = vim.api.nvim_get_current_buf()
  local path = state.attached[bufnr] or rel_path(vim.api.nvim_buf_get_name(bufnr))
  if not path then
    notify("not in a reviewable buffer", vim.log.levels.WARN)
    return
  end

  local mode = vim.fn.mode()
  local first, last
  if mode == "v" or mode == "V" or mode == "\22" then
    first = vim.fn.getpos("v")[2]
    last = vim.fn.line(".")
    vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "nx", false)
  else
    first = vim.fn.line(".")
    last = first
  end
  if last < first then
    first, last = last, first
  end

  open_composer({
    title = (" comment %s:%d "):format(path, first),
    insert = true,
  }, function(text)
    local comment = register({
      source = "mine",
      status = "pending",
      path = path,
      line = first,
      end_line = last,
      body = text,
    })
    state.attached[bufnr] = path
    place(comment, bufnr)
    render_buf(bufnr)
  end)
end

function M.mark_viable()
  pick(comments_at_cursor(), set_viable)
end

function M.discard()
  pick(comments_at_cursor(), drop)
end

function M.edit_comment()
  pick(comments_at_cursor(), function(comment)
    edit_body(comment)
  end)
end

function M.peek()
  local list = comments_at_cursor()
  if #list == 0 then
    notify("no comment under cursor", vim.log.levels.WARN)
    return
  end
  open_peek(list)
end

function M.list()
  local items = {}
  for _, comment in pairs(state.comments) do
    local line = resolve_pos(comment)
    table.insert(items, {
      filename = state.root and (state.root .. "/" .. comment.path) or comment.path,
      lnum = line,
      col = 1,
      text = ("[%s] %s"):format(
        comment.source == "mine" and "you" or comment.status,
        preview_text(comment.body)
      ),
    })
  end
  if #items == 0 then
    notify("no comments yet")
    return
  end
  table.sort(items, function(a, b)
    if a.filename == b.filename then
      return a.lnum < b.lnum
    end
    return a.filename < b.filename
  end)
  vim.fn.setqflist({}, " ", { title = "PR review comments", items = items })
  vim.cmd("copen")
end

function M.log()
  if not state.raw then
    notify("nothing logged yet")
    return
  end
  vim.cmd("new")
  local bufnr = vim.api.nvim_get_current_buf()
  vim.bo[bufnr].buftype = "nofile"
  vim.bo[bufnr].bufhidden = "wipe"
  vim.bo[bufnr].swapfile = false
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, vim.split(state.raw, "\n", { plain = true }))
  vim.bo[bufnr].modifiable = false
  vim.api.nvim_buf_set_name(bufnr, "pr-review://log")
end

function M.clear()
  local bufs = vim.tbl_keys(state.by_mark)
  for _, comment in pairs(state.comments) do
    unplace(comment)
  end
  state.comments = {}
  state.by_path = {}
  state.by_mark = {}
  for _, bufnr in ipairs(bufs) do
    if vim.api.nvim_buf_is_valid(bufnr) then
      vim.api.nvim_buf_clear_namespace(bufnr, state.ns_ui, 0, -1)
    end
  end
  notify("cleared all comments")
end

function M.cancel()
  if not state.job then
    notify("no job running")
    return
  end
  state.job:kill(15)
  state.job = nil
  progress_close()
  notify("cancelled claude job")
end

local function gh_api(args, stdin, cb)
  local cmd = vim.list_extend({ "gh", "api" }, args)
  vim.system(cmd, { cwd = state.root, text = true, stdin = stdin }, function(res)
    vim.schedule(function()
      cb(res, cmd, stdin)
    end)
  end)
end

local function log_exchange(label, cmd, stdin, res)
  state.raw = table.concat({
    "--- " .. label .. " ---",
    table.concat(cmd, " "),
    "--- request body ---",
    stdin or "(none)",
    "--- stdout ---",
    res.stdout or "",
    "--- stderr ---",
    res.stderr or "",
  }, "\n")
end

local function pr_number()
  if state.pr then
    return state.pr
  end
  local out = run({ "gh", "pr", "view", "--json", "number", "--jq", ".number" }, { timeout = 8000 })
  state.pr = out and tonumber(out) or nil
  return state.pr
end

function M.submit()
  if not resolve_repo() then
    notify("not inside a git repository", vim.log.levels.ERROR)
    return
  end

  local payload = {}
  for _, comment in pairs(state.comments) do
    if comment.source == "mine" or comment.status == "viable" then
      local line, end_line = resolve_pos(comment)
      table.insert(payload, {
        path = comment.path,
        line = end_line >= line and end_line or line,
        side = "RIGHT",
        body = comment.body,
      })
    end
  end

  if #payload == 0 then
    notify("nothing to submit: no comments of yours and none marked viable", vim.log.levels.WARN)
    return
  end

  local pr = pr_number()
  if not pr then
    notify("could not determine the PR number for this branch", vim.log.levels.ERROR)
    return
  end

  local reviews = ("repos/{owner}/{repo}/pulls/%d/reviews"):format(pr)

  gh_api({ reviews, "--method", "POST", "--input", "-" }, vim.json.encode({ comments = payload }),
    function(res, cmd, stdin)
      if res.code ~= 0 then
        log_exchange("create pending review", cmd, stdin, res)
        notify("submit failed while creating the review (:PrReviewLog)", vim.log.levels.ERROR)
        return
      end

      local created = try_decode(res.stdout or "")
      local review_id = created and tonumber(created.id)
      if not review_id then
        log_exchange("create pending review", cmd, stdin, res)
        notify("submit failed: no review id in the response (:PrReviewLog)", vim.log.levels.ERROR)
        return
      end

      gh_api({ ("%s/%d/events"):format(reviews, review_id), "--method", "POST", "--input", "-" },
        vim.json.encode({ event = "COMMENT" }),
        function(res2, cmd2, stdin2)
          if res2.code ~= 0 then
            log_exchange("submit pending review", cmd2, stdin2, res2)
            gh_api({ ("%s/%d"):format(reviews, review_id), "--method", "DELETE" }, nil, function() end)
            notify("submit failed; discarded the pending review so you can retry (:PrReviewLog)",
              vim.log.levels.ERROR)
            return
          end

          local done = try_decode(res2.stdout or "")
          notify(("submitted %d comment%s%s"):format(
            #payload,
            #payload == 1 and "" or "s",
            done and done.html_url and (" — " .. done.html_url) or ""
          ))
          M.clear()
        end)
    end)
end

function M.start(base_override)
  M.setup()
  if state.job then
    notify("a review job is already running (:PrReviewCancel to stop it)", vim.log.levels.WARN)
    return
  end
  if not resolve_repo() then
    notify("not inside a git repository", vim.log.levels.ERROR)
    return
  end

  if base_override and base_override ~= "" then
    state.base = base_override
    state.merge_base = nil
    state.pr = nil
  end

  local base = resolve_base()
  local merge_base, err = run({ "git", "merge-base", base, "HEAD" })
  if not merge_base then
    notify(("could not find a merge base with %s: %s"):format(base, tostring(err)), vim.log.levels.ERROR)
    return
  end
  state.merge_base = merge_base

  vim.cmd(("DiffviewOpen %s...HEAD --imply-local"):format(base))
  run_claude()
end

local function install_buf_keymaps(bufnr)
  if vim.b[bufnr].pr_review_maps then
    return
  end
  vim.b[bufnr].pr_review_maps = true
  local function map(mode, lhs, fn, desc)
    vim.keymap.set(mode, lhs, fn, { buffer = bufnr, silent = true, desc = desc })
  end
  map({ "n", "x" }, "<leader>dn", M.add_comment, "PR review: add comment")
  map("n", "<leader>dv", M.mark_viable, "PR review: mark claude comment viable")
  map("n", "<leader>dx", M.discard, "PR review: discard comment")
  map("n", "<leader>dp", M.peek, "PR review: peek comment")
  map("n", "<leader>de", M.edit_comment, "PR review: reword comment")
  map("n", "<leader>ds", M.submit, "PR review: submit review")
end

local function on_diff_buf(bufnr)
  local path = rel_path(vim.api.nvim_buf_get_name(bufnr))
  if not path or not is_right_side(bufnr) then
    return
  end
  state.attached[bufnr] = path
  install_buf_keymaps(bufnr)
  attach_buf(bufnr, path)
end

function M.setup()
  if state.initialized then
    return M
  end
  state.initialized = true
  state.ns = vim.api.nvim_create_namespace("pr_review")
  state.ns_ui = vim.api.nvim_create_namespace("pr_review_ui")
  state.augroup = vim.api.nvim_create_augroup("PrReview", { clear = true })

  local function set_hl()
    for group, link in pairs(HL_LINKS) do
      vim.api.nvim_set_hl(0, group, { link = link, default = true })
    end
  end
  set_hl()

  vim.api.nvim_create_autocmd("ColorScheme", { group = state.augroup, callback = set_hl })

  vim.api.nvim_create_autocmd("User", {
    group = state.augroup,
    pattern = "DiffviewDiffBufWinEnter",
    callback = function()
      on_diff_buf(vim.api.nvim_get_current_buf())
    end,
  })

  vim.api.nvim_create_autocmd("BufWinEnter", {
    group = state.augroup,
    callback = function(args)
      if state.attached[args.buf] then
        attach_buf(args.buf, state.attached[args.buf])
        return
      end
      local path = rel_path(vim.api.nvim_buf_get_name(args.buf))
      if path and state.by_path[path] and next(state.by_path[path]) then
        state.attached[args.buf] = path
        install_buf_keymaps(args.buf)
        attach_buf(args.buf, path)
      end
    end,
  })

  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "InsertLeave" }, {
    group = state.augroup,
    callback = function(args)
      if state.by_mark[args.buf] then
        render_buf(args.buf)
      end
    end,
  })

  vim.api.nvim_create_autocmd("BufWipeout", {
    group = state.augroup,
    callback = function(args)
      local marks = state.by_mark[args.buf]
      if marks then
        for _, id in pairs(marks) do
          local comment = state.comments[id]
          if comment then
            comment.line, comment.end_line = resolve_pos(comment)
            comment.bufnr = nil
            comment.mark_id = nil
          end
        end
      end
      state.by_mark[args.buf] = nil
      state.attached[args.buf] = nil
    end,
  })

  vim.api.nvim_create_autocmd("VimResized", {
    group = state.augroup,
    callback = function()
      if state.progress.buf then
        progress_draw()
      end
    end,
  })

  vim.api.nvim_create_autocmd("VimLeavePre", { group = state.augroup, callback = progress_close })

  local cmd = vim.api.nvim_create_user_command
  cmd("PrReview", function(opts)
    M.start(opts.args)
  end, { nargs = "?", desc = "Start a claude-backed PR review" })
  cmd("PrReviewSubmit", M.submit, { desc = "Submit the review to GitHub" })
  cmd("PrReviewList", M.list, { desc = "List review comments in the quickfix list" })
  cmd("PrReviewEdit", M.edit_comment, { desc = "Reword the comment under the cursor" })
  cmd("PrReviewLog", M.log, { desc = "Show the raw claude / gh output" })
  cmd("PrReviewCancel", M.cancel, { desc = "Cancel the running claude job" })
  cmd("PrReviewClear", M.clear, { desc = "Drop all review comments" })

  return M
end

return M
