local opt = vim.opt
vim.g.root_spec = { "lsp", { ".git", "lua" }, "cwd" }
opt.clipboard = "unnamedplus"
vim.g.tmux_navigator_no_mappings = 1
vim.opt.backspace = { "indent", "eol", "start" }
opt.confirm = true -- Confirm to save changes before exiting modified buffer
opt.cursorline = true -- Enable highlighting of the current line
opt.expandtab = true -- Use spaces instead of tabs

opt.foldlevel = 99
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

vim.o.tabline = "%!v:lua.require'config.presets'.custom_tabline()"

local M = {}

function M.custom_tabline()
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

return M
