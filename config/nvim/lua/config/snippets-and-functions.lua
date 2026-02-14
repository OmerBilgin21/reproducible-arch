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

local uv = vim.loop

local function has_files_with_extensions(extensions)
  local function scan_dir(dir)
    local handle, _ = uv.fs_scandir(dir)
    if not handle then
      return false
    end

    while true do
      local name, type = uv.fs_scandir_next(handle)
      if not name then
        break
      end

      if type == "file" then
        for _, ext in ipairs(extensions) do
          if name:match("%." .. ext .. "$") then
            return true
          end
        end
      elseif type == "directory" then
        -- Skip directories that you want to ignore.
        if name == "node_modules" or name == "dist" then
          goto continue
        end

        local subdir = dir .. "/" .. name
        if scan_dir(subdir) then
          return true
        end
      end
      ::continue::
    end

    return false
  end

  return scan_dir(uv.cwd())
end

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

_G.is_react = function()
  return has_files_with_extensions({ "jsx", "tsx", "css" })
end

vim.filetype.add({
  pattern = {
    [".*/%.?bash.*$"] = "sh",
    [".*/%.?zsh.*$"] = "sh",
  },
})
