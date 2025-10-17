local exists, _ = pcall(require, "telescope")

return {
  "nvim-telescope/telescope.nvim",
  dependencies = {
    { "nvim-telescope/telescope-fzf-native.nvim" },
  },
  lazy = false,
  config = function()
    local telescope = require("telescope")
    local builtin = require("telescope.builtin")
    local actions = require("telescope.actions")

    telescope.setup({
      extensions = {
        fzf = {
          fuzzy = true,                   -- false will only do exact matching
          override_generic_sorter = true, -- override the generic sorter
          override_file_sorter = true,    -- override the file sorter
          case_mode = "smart_case",       -- or "ignore_case" or "respect_case"
        }
      },
      defaults = {
        layout_strategy = "vertical",
        file_ignore_patterns = {
        },
        preview = {
          filesize_limit = 1,
        },
        mappings = {
          i = {
            ["<C-c>"] = actions.close,
            ["<esc>"] = actions.close,
            ["["] = actions.close,
            ["]"] = actions.close,
            ["<C-f>"] = actions.delete_mark,
          },
          n = {
            ["<C-d>"] = actions.delete_buffer,
            ["<C-f>"] = actions.delete_mark,
            ["<C-c>"] = actions.close,
            ["q"] = actions.close,
            ["["] = actions.close,
            ["]"] = actions.close,
          },
        },
      },
      pickers = {
        live_grep = {
          theme = "ivy",
        },
        buffers = {
          initial_mode = "normal",
          theme = "dropdown",
          sort_mru = true,
        },
      },
    })
    vim.keymap.set("n", "<C-p>", function()
      builtin.find_files()
    end, {
      noremap = true,
      silent = true,
    })
    vim.keymap.set("n", "<C-m>", function()
      builtin.marks()
    end, {
      noremap = true,
      silent = true,
    })
    vim.keymap.set("n", "<leader>p", function()
      builtin.find_files({
        find_command = {
          "rg",
          "--files",
          "--hidden",
          "--no-ignore",
          "-g", "!node_modules/",
          "-g", "!.git/",
          "-g", "!*lock.json",
          "-g", "!raycast/",
          "-g", "!venv/",
          "-g", "!hf_cache/",
          "-g", "!cdk.out/",
          "-g", "!dist/",
          "-g", "!*.next/",
          "-g", "!*.gitlab/",
          "-g", "!build/",
          "-g", "!target/",
        },
      })
    end, {
      noremap = true,
      silent = true,
    })
    vim.keymap.set("n", "<leader>f", function()
      builtin.live_grep()
    end, { noremap = true, silent = true })
    vim.keymap.set("n", "<leader><leader>", function()
      builtin.buffers()
    end, {
      noremap = true,
      silent = true,
    })
    vim.keymap.set("n", "<leader>d", function()
      builtin.help_tags()
    end, {
      noremap = true,
      silent = true,
    })
    vim.keymap.set("n", "<leader>gd", function()
      builtin.lsp_definitions({ reuse_win = true })
    end, {})
    vim.keymap.set("n", "gr", function()
      builtin.lsp_references()
    end, {})

    vim.keymap.set("n", "<leader>br", "<cmd>Telescope git_branches<cr>")

    if exists then
      telescope.load_extension("fzf")
    end
  end,
}
