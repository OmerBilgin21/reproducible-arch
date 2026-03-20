-- Highlight on yank
vim.api.nvim_exec(
  [[
  augroup YankHighlight
    autocmd!
    autocmd TextYankPost * silent! lua vim.highlight.on_yank { higroup="IncSearch", timeout=200 }
  augroup END
]],
  false
)

_G.reload_module = function(name)
  for k in pairs(package.loaded) do
    if k == name or k:match("^" .. name .. "%.") then
      package.loaded[k] = nil
    end
  end

  local ok, mod = pcall(require, name)
  if not ok then
    print("Failed to reload:", name)
    return
  end

  -- Re-run setup if your module exposes it
  if mod.setup then
    mod.setup({
      keymaps = { "<C-g>" },
    })
  end

  print("Reloaded module: " .. name)
end

_G.appendTables = function(destination, source)
  for key, value in pairs(source) do
    destination[key] = value
  end
end

_G.is_home = function()
  return true
end

vim.filetype.add({
  pattern = {
    [".*/%.?bash.*$"] = "sh",
    [".*/%.?zsh.*$"] = "sh",
  },
})
