local opt = vim.opt

vim.g.root_spec = { "lsp", { ".git", "lua" }, "cwd" }
opt.clipboard = "unnamedplus"
vim.opt.backspace = { "indent", "eol", "start" }
opt.confirm = true -- Confirm to save changes before exiting modified buffer
opt.cursorline = true -- Enable highlighting of the current line
opt.expandtab = true -- Use spaces instead of tabs

opt.foldenable = true
opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
opt.foldlevel = 99
opt.foldlevelstart = 99
opt.foldmethod = "expr"
opt.foldtext = "v:lua.override_defaults.foldtext()"
opt.grepprg = "rg --vimgrep"
opt.ignorecase = true -- Ignore case

opt.list = true -- Show some invisible characters (tabs...
opt.mouse = "a" -- Enable mouse mode
opt.number = true -- Print line number
opt.pumblend = 10 -- Popup blend
opt.pumheight = 10 -- Maximum number of entries in a popup
opt.relativenumber = true -- Relative line numbers
opt.scrolloff = 4 -- Lines of context

opt.shiftround = true -- Round indent
opt.shiftwidth = 2 -- Size of an indent

opt.signcolumn = "yes" -- Always show the signcolumn, otherwise it would shift the text each time
opt.smartcase = true -- Don't ignore case with capitals
opt.smartindent = true -- Insert indents automatically
opt.spelllang = { "en" }

opt.tabstop = 2 -- Number of spaces tabs count for
opt.termguicolors = true -- True color support

opt.undofile = true
opt.undolevels = 10000
opt.updatetime = 100 -- Save swap file and trigger CursorHold
opt.virtualedit = "block" -- Allow cursor to move where there is no text in visual block mode
opt.wildmode = "longest:full,full" -- Command-line completion mode
opt.winminwidth = 5 -- Minimum window width

opt.wrap = true
opt.smoothscroll = false
opt.autoread = true
opt.swapfile = false

vim.api.nvim_create_autocmd("BufAdd", {
  pattern = "/tmp/nvim.*/*",
  callback = function(args)
    vim.bo[args.buf].buflisted = false
  end,
})

local file_sync_group = vim.api.nvim_create_augroup("FileSync", { clear = true })

vim.api.nvim_create_autocmd({ "FocusGained", "TermClose", "TermLeave", "VimResume" }, {
  group = file_sync_group,
  callback = function()
    vim.cmd("silent! checktime")
  end,
})

vim.fn.timer_start(2000, function()
  vim.cmd("silent! checktime")
end, { ["repeat"] = -1 })

vim.api.nvim_create_autocmd("BufEnter", {
  group = file_sync_group,
  callback = function(args)
    if vim.bo[args.buf].buftype ~= "" then
      return
    end
    vim.cmd(("silent! checktime %d"):format(args.buf))
  end,
})

vim.api.nvim_create_autocmd("FileChangedShellPost", {
  group = file_sync_group,
  callback = function(args)
    local name = vim.api.nvim_buf_get_name(args.buf)
    if name == "" then
      return
    end
    vim.notify(("Reloaded from disk: %s"):format(vim.fn.fnamemodify(name, ":~:.")), vim.log.levels.INFO)
  end,
})

vim.api.nvim_create_user_command("WorkspaceSync", function(opts)
  if opts.bang then
    vim.cmd("silent! wall")
  end

  vim.cmd("silent! checktime")
end, {
  bang = true,
  desc = "Sync buffers with disk changes; use ! to write all modified buffers first",
})

vim.o.tabline = "%!v:lua.override_defaults.tabline()"
