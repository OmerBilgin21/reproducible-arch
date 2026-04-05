require("keymaps")
require("presets")

local gh = function(str)
  return "https://github.com/" .. str
end

local pack = function(specs, opts)
  vim.pack.add(specs, vim.tbl_extend("force", { load = true }, opts or {}))
end

-- ── Theme ─────────────────────────────────────────────────────────────────────
pack({ gh("olimorris/onedarkpro.nvim") })

vim.cmd.colorscheme("onedark")

for _, hl in ipairs({
  "Normal",
  "NormalFloat",
  "NormalVertical",
  "FloatBorder",
  "Pmenu",
  "Terminal",
  "EndOfBuffer",
  "FoldColumn",
  "Folded",
  "SignColumn",
  "NormalNC",
  "LineNr",
  "StatusLine",
  "StatusLineNC",
  "WhichKeyFloat",
  "TelescopeBorder",
  "TelescopeNormal",
  "TelescopePromptBorder",
  "TelescopePromptTitle",
  "NeoTreeNormal",
  "NeoTreeNormalNC",
  "NeoTreeVertSplit",
  "NeoTreeWinSeparator",
  "NeoTreeEndOfBuffer",
  "NotifyINFOBody",
  "NotifyERRORBody",
  "NotifyWARNBody",
  "NotifyTRACEBody",
  "NotifyDEBUGBody",
  "NotifyINFOTitle",
  "NotifyERRORTitle",
  "NotifyWARNTitle",
  "NotifyTRACETitle",
  "NotifyDEBUGTitle",
  "NotifyINFOBorder",
  "NotifyERRORBorder",
  "NotifyWARNBorder",
  "NotifyTRACEBorder",
  "NotifyDEBUGBorder",
  "ToggleTerm",
  "ToggleTermNormal",
  "ToggleTermBorder",
  "TabLine",
  "TabLineFill",
}) do
  vim.api.nvim_set_hl(0, hl, { bg = "none" })
end
vim.api.nvim_set_hl(0, "TabLineSel", { bg = "#0f1116", bold = true })

vim.api.nvim_create_autocmd("TermOpen", {
  pattern = "*",
  callback = function()
    vim.api.nvim_set_option_value("winhighlight", "", { scope = "local" })
    vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
    vim.api.nvim_set_hl(0, "NormalNC", { bg = "none" })
  end,
})

-- ── Treesitter ────────────────────────────────────────────────────────────────
pack({ gh("nvim-treesitter/nvim-treesitter") })

require("nvim-treesitter").setup({
  sync_install = false,
  ignore_install = {},
  auto_install = true,
  modules = {},
  highlight = { enable = true },
  indent = { enable = true },
  ensure_installed = {
    "lua",
    "javascript",
    "typescript",
    "python",
    "jsonc",
    "go",
    "yaml",
    "vim",
    "tsx",
  },
})

-- ── Mason + LSP ───────────────────────────────────────────────────────────────
pack({ gh("williamboman/mason.nvim") })
pack({ gh("neovim/nvim-lspconfig") })

require("mason").setup()

local mason_bin = vim.fn.stdpath("data") .. "/mason/bin/"

local lsp_servers = {
  bashls = {
    filetypes = { "sh", "bash", "zsh" },
    cmd = { mason_bin .. "bash-language-server", "start" },
  },
  lua_ls = {
    filetypes = { "lua" },
    cmd = { mason_bin .. "lua-language-server" },
    settings = {
      Lua = {
        completion = { callSnippet = "Replace" },
        diagnostics = { globals = { "vim" } },
      },
    },
  },
  gopls = {
    filetypes = { "go", "gomod", "gowork", "gotmpl" },
    cmd = { mason_bin .. "gopls" },
    settings = { gopls = { buildFlags = { "-tags=integration" } } },
  },
  ts_ls = {
    filetypes = { "typescript", "javascript", "typescriptreact", "javascriptreact" },
    cmd = { mason_bin .. "typescript-language-server", "--stdio" },
    init_options = {
      hostInfo = "neovim",
      maxTsServerMemory = 8192,
      preferences = { includePackageJsonAutoImports = "auto" },
    },
  },
  pyright = {
    filetypes = { "python" },
    cmd = { mason_bin .. "pyright-langserver", "--stdio" },
    settings = {
      python = {
        venvPath = ".",
        venv = "venv",
        analysis = { autoSearchPaths = true, useLibraryCodeForTypes = true },
      },
    },
  },
  dockerls = {
    filetypes = { "dockerfile" },
    cmd = { mason_bin .. "docker-langserver", "--stdio" },
  },
  docker_compose_language_service = {
    filetypes = { "yaml" },
    cmd = { mason_bin .. "docker-compose-langserver", "--stdio" },
  },
}

-- LSP servers registered after blink is set up below (capabilities needed)

-- ── Snippets ──────────────────────────────────────────────────────────────────
pack({ { src = gh("L3MON4D3/LuaSnip"), version = "v2.4.1" } })

local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local ins = ls.insert_node
local rep = require("luasnip.extras").rep

ls.config.set_config({ history = true, enable_autosnippets = true })

ls.add_snippets("sh", {
  s("shebang", { t("#!/bin/bash") }),
})

ls.add_snippets("typescriptreact", {
  s("tsrafce", {
    t({ "import React from 'react';", "" }),
    t({ "type Props = {};", "" }),
    t({ "", "const " }),
    ins(1, "ComponentName"),
    t({
      ": React.FC<Props> = ({}: Props) => {",
      "  return (",
      "    <div>",
      "      {/* Your component JSX */}",
      "    </div>",
      "  );",
      "};",
      "",
      "export default ",
    }),
    rep(1),
    t(";"),
  }),
  s("debugg", { t("style={{border: '4px solid red'}}") }),
})

ls.add_snippets("go", {
  s("iferr", {
    t("if err != nil {"),
    t({ "", "\t" }),
    ins(1, "/* handle error */"),
    t({ "", "}" }),
  }),
})

vim.keymap.set("i", "<C-b>", function()
  if ls.expand_or_jumpable() then
    ls.expand_or_jump()
  else
    print("nothing jumpable")
  end
end)

-- ── Completions ───────────────────────────────────────────────────────────────
pack({ { src = gh("saghen/blink.cmp"), version = "v1.10.1" } })

require("blink.cmp").setup({
  keymap = { preset = "enter" },
  appearance = { nerd_font_variant = "mono" },
  completion = {
    menu = {
      border = "rounded",
      draw = { padding = { 1, 1 } },
    },
    documentation = {
      auto_show = false,
      auto_show_delay_ms = 300,
      window = {
        border = "rounded",
        direction_priority = {
          menu_north = { "e", "w", "n", "s" },
        },
      },
    },
  },
  signature = {
    enabled = true,
    trigger = {
      enabled = true,
      show_on_keyword = false,
      show_on_trigger_character = true,
      show_on_insert = false,
      show_on_insert_on_trigger_character = true,
    },
    window = { show_documentation = true },
  },
  snippets = { preset = "luasnip" },
  sources = {
    per_filetype = {
      sql = { "snippets", "dadbod", "buffer" },
    },
    default = { "lsp", "path", "snippets", "buffer" },
    providers = {
      lsp = {
        name = "LSP",
        module = "blink.cmp.sources.lsp",
        async = true,
        timeout_ms = 1200,
        score_offset = 30,
      },
      path = { name = "Path", module = "blink.cmp.sources.path", score_offset = 50 },
      snippets = { name = "Snippets", module = "blink.cmp.sources.snippets", score_offset = 40 },
      buffer = {
        name = "Buffer",
        module = "blink.cmp.sources.buffer",
        score_offset = 10,
        min_keyword_length = 3,
      },
      dadbod = { name = "Dadbod", module = "dadbod_source", score_offset = 60 },
    },
  },
})

-- Register LSP servers now that blink capabilities are available
for server, config in pairs(lsp_servers) do
  config.capabilities = require("blink.cmp").get_lsp_capabilities(config.capabilities)
  vim.lsp.config(server, config)
  vim.lsp.enable(server)
end

vim.diagnostic.config({
  virtual_text = true,
  virtual_lines = false,
  float = false,
  signs = false,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
})

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(event)
    local client = event.data and vim.lsp.get_client_by_id(event.data.client_id)
    if client and client.name == "ts_ls" then
      client.server_capabilities.semanticTokensProvider = nil
    end
    vim.keymap.set("n", "K", function()
      vim.lsp.buf.hover({ border = "rounded", max_width = 80, max_height = 20 })
    end, { buffer = event.buf, desc = "LSP hover" })
  end,
})
-- require("nvim-lspconfig").setup()

vim.keymap.set("n", "gd", function()
  vim.lsp.buf.definition({ reuse_win = true })
end, {})
vim.keymap.set("n", "<leader>cv", function()
  vim.diagnostic.config({ virtual_text = not vim.diagnostic.config().virtual_text })
end, {})

-- ── Formatting ────────────────────────────────────────────────────────────────
pack({ gh("stevearc/conform.nvim") })

require("conform").setup({
  formatters_by_ft = {
    lua = { "stylua" },
    sh = { "shfmt" },
    zsh = { "shfmt" },
    bash = { "shfmt" },
    python = { "isort", "black" },
    javascript = { "eslint_d" },
    javascriptreact = { "eslint_d" },
    sql = { "sqlfmt" },
    typescript = { "eslint_d" },
    typescriptreact = { "eslint_d" },
    go = { "gofmt" },
    json = { "jq" },
  },
  default_format_opts = { lsp_format = "fallback" },
  notify_on_error = true,
  notify_no_formatters = true,
  log_level = vim.log.levels.ERROR,
  format_on_save = { timeout_ms = 2000, lsp_format = "fallback" },
})

vim.keymap.set("n", "<leader>,", function()
  require("conform").format()
end, { desc = "Format buffer" })

-- ── Linting ───────────────────────────────────────────────────────────────────
pack({ gh("mfussenegger/nvim-lint") })

local lint = require("lint")
lint.linters_by_ft = {
  javascript = { "eslint_d" },
  javascriptreact = { "eslint_d" },
  typescript = { "eslint_d" },
  typescriptreact = { "eslint_d" },
}

vim.diagnostic.config({
  virtual_text = false,
  signs = false,
  underline = false,
}, lint.get_namespace("eslint_d"))

vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost", "InsertLeave" }, {
  callback = function()
    lint.try_lint()
  end,
})

-- ── Debugging ─────────────────────────────────────────────────────────────────
pack({ gh("mfussenegger/nvim-dap") })
pack({ gh("leoluz/nvim-dap-go") })
pack({ gh("nvim-neotest/nvim-nio") })
pack({ gh("rcarriga/nvim-dap-ui") })

require("dap-go").setup({
  delve = { path = vim.fn.stdpath("data") .. "/mason/bin/dlv" },
})

local dap, dapui = require("dap"), require("dapui")
dapui.setup()

dap.listeners.before.launch.dapui_config = function()
  dapui.open()
end
dap.listeners.before.event_terminated.dapui_config = function()
  dapui.close()
end
dap.listeners.before.event_exited.dapui_config = function()
  dapui.close()
end

vim.keymap.set("n", "<leader>dt", function()
  require("dap-go").debug_test()
end, { desc = "Debug test" })
vim.keymap.set("n", "<leader>db", function()
  dap.toggle_breakpoint()
end, { desc = "Toggle breakpoint" })
vim.keymap.set("n", "<F5>", function()
  dap.continue()
end, { desc = "Continue" })
vim.keymap.set("n", "<F10>", function()
  dap.step_over()
end, { desc = "Step over" })
vim.keymap.set("n", "<F11>", function()
  dap.step_into()
end, { desc = "Step into" })
vim.keymap.set("n", "<F12>", function()
  dap.step_out()
end, { desc = "Step out" })

-- ── Print Debugger ────────────────────────────────────────────────────────────
pack({ gh("OmerBilgin21/print-debugger.nvim") })

require("print-debugger").setup({
  typescript = { prefix = "logger.info" },
  go = { prefix = "internal.Logger", spread_mode = true },
  keymaps = { "<C-g>" },
})

-- ── File Tree ─────────────────────────────────────────────────────────────────
pack({ gh("nvim-lua/plenary.nvim") })
pack({ gh("nvim-tree/nvim-web-devicons") })
pack({ gh("MunifTanjim/nui.nvim") })
pack({ { src = gh("nvim-neo-tree/neo-tree.nvim"), version = "v3.x" } })

require("neo-tree").setup({
  file_size = { enabled = false },
  type = { enabled = false },
  last_modified = { enabled = false },
  created = { enabled = false },
  filesystem = {
    bind_to_cwd = false,
    follow_current_file = { enabled = true },
    use_libuv_file_watcher = true,
    filtered_items = {
      hide_gitignored = false,
      hide_hidden = false,
      hide_dotfiles = false,
    },
  },
  indent_size = 2,
  padding = 1,
  window = { position = "right" },
})

vim.keymap.set("n", "<leader>e", ":Neotree toggle<CR>", { noremap = true, silent = true })

-- ── Telescope ─────────────────────────────────────────────────────────────────
pack({ { src = gh("nvim-telescope/telescope-fzf-native.nvim"), build = "make" } })
pack({ gh("nvim-telescope/telescope.nvim") })

local telescope = require("telescope")
local builtin = require("telescope.builtin")
local actions = require("telescope.actions")

telescope.setup({
  extensions = {
    fzf = {
      fuzzy = true,
      case_mode = "smart_case",
      override_generic_sorter = true,
      override_file_sorter = true,
    },
  },
  defaults = {
    layout_strategy = "vertical",
    file_ignore_patterns = {},
    preview = { filesize_limit = 1 },
    mappings = {
      i = {
        ["<C-c>"] = actions.close,
        ["<esc>"] = actions.close,
        ["["] = actions.close,
        ["]"] = actions.close,
      },
      n = {
        ["<C-c>"] = actions.close,
        ["q"] = actions.close,
        ["["] = actions.close,
        ["]"] = actions.close,
      },
    },
  },
  pickers = {
    live_grep = { theme = "ivy" },
    buffers = {
      initial_mode = "normal",
      theme = "dropdown",
      sort_mru = true,
      mappings = { n = { ["<C-d>"] = actions.delete_buffer } },
    },
    marks = {
      initial_mode = "normal",
      theme = "dropdown",
      sort_mru = true,
      mappings = { n = { ["<C-i>"] = actions.delete_mark } },
    },
  },
})

-- telescope.load_extension("fzf")

vim.keymap.set("n", "<C-p>", function()
  builtin.find_files({
    find_command = {
      "rg",
      "--files",
      "--hidden",
      "--no-ignore",
      "-g",
      "!node_modules/",
      "-g",
      "!.git/",
      "-g",
      "!*lock.json",
      "-g",
      "!raycast/",
      "-g",
      "!venv/",
      "-g",
      "!hf_cache/",
      "-g",
      "!cdk.out/",
      "-g",
      "!dist/",
      "-g",
      "!*.next/",
      "-g",
      "!*.gitlab/",
      "-g",
      "!build/",
      "-g",
      "!target/",
    },
  })
end, { noremap = true, silent = true })

vim.keymap.set("n", "<C-n>", function()
  builtin.marks()
end, { noremap = true, silent = true })
vim.keymap.set("n", "<leader>f", function()
  builtin.live_grep({ glob_pattern = { "!package-lock.json" } })
end, { noremap = true, silent = true })
vim.keymap.set("n", "<leader><leader>", function()
  builtin.buffers()
end, { noremap = true, silent = true })
vim.keymap.set("n", "<leader>d", function()
  builtin.help_tags()
end, { noremap = true, silent = true })
vim.keymap.set("n", "<leader>gd", function()
  builtin.lsp_definitions({ reuse_win = true })
end, {})
vim.keymap.set("n", "gr", function()
  builtin.lsp_references()
end, {})
vim.keymap.set("n", "<leader>br", "<cmd>Telescope git_branches<cr>")

-- ── Harpoon ───────────────────────────────────────────────────────────────────
pack({ { src = gh("ThePrimeagen/harpoon"), version = "harpoon2" } })

local harpoon = require("harpoon")
harpoon:setup()

vim.keymap.set("n", "<leader>H", function()
  harpoon:list():add()
end)
vim.keymap.set("n", "<leader>h", function()
  harpoon.ui:toggle_quick_menu(harpoon:list())
end)

for idx = 1, 5 do
  local index = idx
  vim.keymap.set("n", "<leader>" .. index, function()
    harpoon:list():select(index)
  end)
end

-- ── Trouble ───────────────────────────────────────────────────────────────────
pack({ gh("folke/trouble.nvim") })

require("trouble").setup({})

vim.keymap.set("n", "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", { desc = "Diagnostics (Trouble)" })
vim.keymap.set(
  "n",
  "<leader>xX",
  "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
  { desc = "Buffer Diagnostics (Trouble)" }
)
vim.keymap.set(
  "n",
  "<leader>cl",
  "<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
  { desc = "LSP Definitions / references (Trouble)" }
)

-- ── Terminal ──────────────────────────────────────────────────────────────────
pack({ gh("akinsho/toggleterm.nvim") })

local tt = require("toggleterm")
local term = require("toggleterm.terminal")
local Terminal = require("toggleterm.terminal").Terminal

local base_setup = {
  size = function(term_opts)
    if term_opts.direction == "horizontal" then
      return 15
    elseif term_opts.direction == "vertical" then
      return vim.o.columns * 0.3
    else
      return 20
    end
  end,
  direction = "float",
  float_opts = { border = "single", title_pos = "center" },
  title_pos = "center",
  scroll_on_output = false,
  shade_terminals = false,
  auto_scroll = false,
}

local right_side_offcanvas = {
  direction = "vertical",
  hidden = true,
  scroll_on_output = false,
  shade_terminals = false,
}

local claude_setup = vim.tbl_extend("force", {}, right_side_offcanvas, { cmd = "claude", title = "Claude", id = 999 })
local codex_setup = vim.tbl_extend("force", {}, right_side_offcanvas, { cmd = "codex", title = "Codex", id = 996 })
local free_offcanvas_setup = vim.tbl_extend("force", {}, right_side_offcanvas, { title = "Free brother", id = 994 })

local offcanvas_setups = { claude_setup, codex_setup, free_offcanvas_setup }

local function is_offcanvas_focused()
  local focused_id = term.get_focused_id()
  for _, cfg in ipairs(offcanvas_setups) do
    if focused_id == cfg.id then
      return true
    end
  end
  return false
end

local lazygit_setup =
  vim.tbl_deep_extend("force", { id = 998, cmd = "lazygit", hidden = true, title = "LazyGit" }, base_setup)
local default_setup = vim.tbl_deep_extend("force", { id = 997, hidden = true, title = "Terminal" }, base_setup)

local function get_test_setup()
  return vim.tbl_deep_extend("force", {
    cmd = "npx jest -- " .. vim.fn.expand("%:t"),
    close_on_exit = false,
    title = "Test",
  }, base_setup)
end

tt.setup(vim.tbl_extend("force", base_setup, { shade_filetypes = {}, shading_factor = 0 }))

local lazygit = Terminal:new(lazygit_setup)
local default = Terminal:new(default_setup)
local claude = Terminal:new(claude_setup)
local codex = Terminal:new(codex_setup)
local free_offcanvas = Terminal:new(free_offcanvas_setup)

vim.keymap.set("n", "<leader>tt", function()
  Terminal:new(get_test_setup()):toggle()
end)

vim.keymap.set("t", "<C-g>", function()
  if is_offcanvas_focused() then
    return
  end
end)

vim.keymap.set("t", "<C-p>", function()
  local current_win = vim.api.nvim_get_current_win()
  vim.cmd("wincmd p")
  local filename = vim.fn.expand("%:t")
  vim.api.nvim_set_current_win(current_win)
  if filename ~= "" then
    vim.api.nvim_paste(filename, true, -1)
  end
end, { noremap = true, silent = true })

vim.keymap.set("t", "<C-n>", [[<C-\><C-n>]])

vim.keymap.set({ "i", "n", "t" }, "<S-tab>", function()
  if is_offcanvas_focused() then
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<S-tab>", true, false, true), "n", false)
    return
  end
  default:toggle()
end, { desc = "toggle floating term" })

vim.keymap.set("n", "<leader>gg", function()
  lazygit:toggle()
end)
vim.keymap.set({ "n", "t" }, "<C-Space>", function()
  claude:toggle()
end)
vim.keymap.set({ "n", "t" }, "<M-Space>", function()
  codex:toggle()
end)
vim.keymap.set({ "n", "t" }, "<C-a>", function()
  free_offcanvas:toggle()
end)

vim.keymap.set("t", "<C-x>", function()
  local function trim(str)
    return str:match("^%s*(.-)%s*$")
  end

  if term.get_focused_id() ~= 997 then
    return
  end

  vim.cmd("stopinsert")

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_option_value("buftype", "nofile", { buf = buf })
  vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = buf })
  vim.api.nvim_set_option_value("filetype", "sh", { buf = buf })
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "" })

  local width = math.min(80, vim.o.columns - 4)
  local height = 1
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.floor((vim.o.lines - height) / 2),
    style = "minimal",
    border = "rounded",
    title = " Command ",
    title_pos = "center",
  })

  local close = function()
    vim.api.nvim_win_close(win, true)
    vim.schedule(function()
      default:open()
      vim.cmd("startinsert")
    end)
  end

  vim.keymap.set({ "i", "n" }, "<CR>", function()
    local command = trim(vim.api.nvim_buf_get_lines(buf, 0, -1, false)[1] or "")
    vim.api.nvim_win_close(win, true)
    default:send(command, false)
    vim.schedule(function()
      default:open()
      vim.cmd("startinsert")
    end)
  end, { buffer = buf })

  vim.keymap.set("i", "<C-n>", "<Esc>", { buffer = buf })
  vim.keymap.set("n", "<Esc>", close, { buffer = buf })
  vim.keymap.set("n", "q", close, { buffer = buf })

  vim.cmd("startinsert")
end, { noremap = true })

-- ── Git ───────────────────────────────────────────────────────────────────────
pack({ gh("tpope/vim-fugitive") })

vim.keymap.set("n", "<leader>gm", "<cmd>:Gvdiffsplit!<cr>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>gb", "<cmd>:G blame<cr>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>gr", function()
  local back = vim.fn.input("Enter how many times to take back:")
  vim.cmd(string.format("G reset --soft HEAD~%s", back))
end, { noremap = true, silent = true })
vim.keymap.set("n", "<leader>go", "<cmd>:diffget //2<cr>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>gt", "<cmd>:diffget //3<cr>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>gs", "<cmd>G<cr>", { desc = "Git status" })
vim.keymap.set("n", "<leader>gc", "<cmd>G checkout<cr>", { desc = "Git checkout branch" })
vim.keymap.set("n", "<leader>gC", function()
  local branch = vim.fn.input("Create and checkout branch: ")
  if branch ~= "" then
    vim.cmd("G checkout -b " .. branch)
  end
end, { desc = "Create and checkout new branch" })
vim.keymap.set("n", "<leader>gB", "<cmd>G branch<cr>", { desc = "List branches" })
vim.keymap.set("n", "<leader>gci", "<cmd>G commit<cr>", { desc = "Git commit" })
vim.keymap.set("n", "<leader>gca", "<cmd>G commit --amend<cr>", { desc = "Git commit amend" })
vim.keymap.set("n", "<leader>gcm", function()
  local msg = vim.fn.input("Commit message: ")
  if msg ~= "" then
    vim.cmd("G commit -m '" .. msg .. "'")
  end
end, { desc = "Quick commit with message" })
vim.keymap.set("n", "<leader>gp", "<cmd>G push<cr>", { desc = "Git push" })
vim.keymap.set("n", "<leader>gP", "<cmd>G pull<cr>", { desc = "Git pull" })
vim.keymap.set("n", "<leader>gf", "<cmd>G fetch<cr>", { desc = "Git fetch" })
vim.keymap.set("n", "<leader>gst", "<cmd>G stash<cr>", { desc = "Git stash" })
vim.keymap.set("n", "<leader>gsp", "<cmd>G stash pop<cr>", { desc = "Git stash pop" })
vim.keymap.set("n", "<leader>gsl", "<cmd>G stash list<cr>", { desc = "Git stash list" })
vim.keymap.set("n", "<leader>gl", "<cmd>G log<cr>", { desc = "Git log detailed" })
vim.keymap.set("n", "<leader>gL", "<cmd>G log --oneline --graph --all<cr>", { desc = "Git log graph all branches" })
vim.keymap.set("n", "<leader>glc", "<cmd>G log --oneline<cr>", { desc = "Git log compact" })
vim.keymap.set("n", "<leader>gbs", function()
  vim.cmd("G branch -a")
end, { desc = "Show all branches" })
vim.keymap.set("n", "<leader>gpu", function()
  local branch = vim.fn.system("git branch --show-current"):gsub("\n", "")
  vim.cmd("G log origin/" .. branch .. "..HEAD --oneline")
end, { desc = "Show unpushed commits" })
vim.keymap.set("n", "<leader>gpd", function()
  local branch = vim.fn.system("git branch --show-current"):gsub("\n", "")
  vim.cmd("G log HEAD..origin/" .. branch .. " --oneline")
end, { desc = "Show commits to pull" })
vim.keymap.set("n", "<leader>glb", function()
  local branch = vim.fn.system("git branch --show-current"):gsub("\n", "")
  local main_branch = nil
  for _, mb in ipairs({ "main", "master", "develop" }) do
    vim.fn.system("git show-ref --verify --quiet refs/heads/" .. mb)
    if vim.v.shell_error == 0 then
      main_branch = mb
      break
    end
  end
  if main_branch and branch ~= main_branch then
    vim.cmd("G log " .. main_branch .. ".." .. branch .. " --oneline")
  else
    vim.cmd("G log --oneline -10")
  end
end, { desc = "Show commits in current branch" })
vim.keymap.set("n", "<leader>gd", "<cmd>Gvdiffsplit<cr>", { desc = "Git diff split" })

vim.api.nvim_create_autocmd("FileType", {
  pattern = "fugitive",
  callback = function()
    local bufnr = vim.api.nvim_get_current_buf()
    local opts = { buffer = bufnr, silent = true }
    vim.keymap.set("n", "cc", "<cmd>G commit<cr>", opts)
    vim.keymap.set("n", "P", "<cmd>G push<cr>", opts)
    vim.keymap.set("n", "p", "<cmd>G pull<cr>", opts)
    vim.keymap.set("n", "X", "X", opts)
    vim.keymap.set("n", "<leader>gX", "<cmd>G reset --hard HEAD<cr>", opts)
  end,
})

vim.keymap.set("n", "]q", "<cmd>cnext<cr>", { desc = "Next quickfix" })
vim.keymap.set("n", "[q", "<cmd>cprev<cr>", { desc = "Previous quickfix" })
vim.keymap.set("n", "<leader>qc", "<cmd>cclose<cr>", { desc = "Close quickfix" })

-- ── Flatten ───────────────────────────────────────────────────────────────────
pack({ gh("willothy/flatten.nvim") })

require("flatten").setup({
  window = { open = "alternate" },
  hooks = {
    should_block = function(argv)
      if not argv or type(argv) ~= "table" then
        return false
      end
      return vim.tbl_contains(argv, "-b")
        or vim.tbl_contains(argv, "--remote-wait")
        or vim.tbl_contains(argv, "--remote-wait-sleep")
    end,
  },
})

-- ── Database ──────────────────────────────────────────────────────────────────
pack({ gh("tpope/vim-dadbod") })
pack({ gh("kristijanhusak/vim-dadbod-completion") })
pack({ gh("kristijanhusak/vim-dadbod-ui") })

vim.g.db_ui_execute_on_save = 0
vim.g.db_ui_save_location = vim.fn.expand("~/queries")
vim.g.db_ui_use_nerd_fonts = 1
vim.g.vim_dadbod_completion_omnifunc = 0

-- ── Markdown ──────────────────────────────────────────────────────────────────
pack({ gh("MeanderingProgrammer/render-markdown.nvim") })

require("render-markdown").setup({ latex = { enabled = false } })

-- ── Go Docs ───────────────────────────────────────────────────────────────────
pack({ { src = gh("fredrikaverpil/godoc.nvim"), build = "go install github.com/lotusirous/gostdsym/stdsym@latest" } })

require("godoc").setup({ picker = { type = "telescope" } })

-- ── Lua Dev ───────────────────────────────────────────────────────────────────
pack({ gh("folke/lazydev.nvim") })

require("lazydev").setup({
  library = {
    { path = "${3rd}/luv/library", words = { "vim%.uv" } },
    { path = "blink.cmp" },
    { path = "conform.nvim" },
    { path = "mason.nvim" },
    { path = "nvim-lspconfig" },
    { path = "render-markdown" },
    { path = "telescope.nvim" },
    { path = "LuaSnip" },
  },
})

-- ── Surround ──────────────────────────────────────────────────────────────────
pack({ gh("kylechui/nvim-surround") })

vim.g.nvim_surround_no_insert_mappings = true
require("nvim-surround").setup({})

-- ── Auto Pairs ────────────────────────────────────────────────────────────────
pack({ gh("echasnovski/mini.pairs") })

require("mini.pairs").setup({
  modes = { insert = true, command = true, terminal = false },
  skip_next = [=[[%w%%%'%[%"%.%`%$]]=],
  skip_ts = { "string" },
  skip_unbalanced = true,
  markdown = true,
})

-- ── Search & Replace ─────────────────────────────────────────────────────────
pack({ gh("MagicDuck/grug-far.nvim") })

require("grug-far").setup({ headerMaxWidth = 80 })

vim.keymap.set({ "n", "v" }, "<leader>sr", function()
  local grug = require("grug-far")
  local ext = vim.bo.buftype == "" and vim.fn.expand("%:e")
  grug.toggle_instance({
    transient = true,
    prefills = { filesFilter = ext and ext ~= "" and "*." .. ext or nil },
  })
end, { desc = "Search and Replace" })

-- ── Flash Navigation ─────────────────────────────────────────────────────────
pack({ gh("folke/flash.nvim") })

require("flash").setup({})

vim.keymap.set({ "n", "x", "o" }, "s", function()
  require("flash").jump()
end, { desc = "Flash" })
vim.keymap.set("o", "r", function()
  require("flash").remote()
end, { desc = "Remote Flash" })
