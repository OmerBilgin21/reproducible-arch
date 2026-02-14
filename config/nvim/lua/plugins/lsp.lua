return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      local ts_config = require("nvim-treesitter.configs")
      ts_config.setup({
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
    end,
  },
  {
    "stevearc/conform.nvim",
    opts = function()
      require("conform").setup({
        formatters_by_ft = {
          lua = { "stylua" },
          sh = { "shfmt" },
          zsh = { "shfmt" },
          bash = { "shfmt" },
          python = { "isort", "black" },
          javascript = {
            "prettier",
            stop_after_first = true,
          },
          javascriptreact = {
            "prettier",
            stop_after_first = true,
          },
          sql = { "sqlfmt" },
          typescript = {
            "prettier",
            stop_after_first = true,
          },
          typescriptreact = {
            "prettier",
            stop_after_first = true,
          },
          go = { "gofmt" },
          json = { "jq" },
        },
        default_format_opts = {
          lsp_format = "fallback",
        },
        notify_on_error = true,
        notify_no_formatters = true,
        log_level = vim.log.levels.ERROR,
        format_on_save = {
          timeout_ms = 5000,
          lsp_format = "fallback",
        },
      })

      vim.api.nvim_create_autocmd("BufWritePre", {
        pattern = "*",
        callback = function(args)
          require("conform").format({ bufnr = args.buf })
        end,
      })

      vim.keymap.set("n", "<leader>,", function()
        require("conform").format()
      end)
    end,
  },
  {
    "williamboman/mason.nvim",
    lazy = false,
    config = function()
      require("mason").setup()
    end,
  },
  {
    "folke/lazydev.nvim",
    ft = "lua",
    opts = {
      library = {
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
      },
    },
  },
  { "williamboman/mason-lspconfig" },
  {
    "neovim/nvim-lspconfig",
    dependencies = { "saghen/blink.cmp", "williamboman/mason-lspconfig" },
    lazy = false,
    opts = {
      servers = {
        bashls = {
          filetypes = { "sh", "bash", "zsh" },
        },
        lua_ls = {
          settings = {
            Lua = {
              completion = {
                callSnippet = "Replace",
              },
              diagnostics = {
                globals = { "vim" },
              },
            },
          },
        },
        gopls = {},
        ts_ls = {},
        pyright = {
          settings = {
            python = {
              venvPath = ".",
              venv = "venv",
              analysis = {
                autoSearchPaths = true,
                useLibraryCodeForTypes = true,
              },
            },
          },
        },
        dockerls = {
          filetypes = { "dockerfile" },
        },
        docker_compose_language_service = {
          filetypes = { "yaml" },
        },
        eslint = {
          on_attach = function(_, bufnr)
            vim.api.nvim_create_autocmd("BufWritePre", {
              buffer = bufnr,
              command = "EslintFixAll",
            })
          end,
        },
      },
    },
    config = function(_, opts)
      local lspconfig = require("lspconfig")

      if is_react() then
        opts["servers"].tailwindcss = {}
        opts["servers"].cssls = {}
      end

      require("mason-lspconfig").setup({
        automatic_installation = true,
        ensure_installed = vim.tbl_keys(opts.servers),
      })

      for server, config in pairs(opts.servers) do
        config.capabilities = require("blink.cmp").get_lsp_capabilities(config.capabilities)
        lspconfig[server].setup(config)
      end

      vim.diagnostic.config({
        virtual_text = false,
        virtual_lines = false,
        float = true,
        signs = true,
        underline = true,
        update_in_insert = false,
        severity_sort = true,
      })

      -- hover with border but it's stupidly complicated :D
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(event)
          local buf = event.buf
          vim.keymap.set("n", "K", function()
            vim.lsp.buf.hover({
              border = "rounded",
              max_width = 80,
              max_height = 20,
            })
          end, { buffer = buf, desc = "LSP hover (rounded)" })
        end,
      })

      vim.keymap.set("n", "gd", function()
        vim.lsp.buf.definition({ reuse_win = true })
      end, {})
      vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, {})
      vim.keymap.set("n", "<leader>ct", function()
        vim.diagnostic.enable(not vim.diagnostic.is_enabled())
      end, { desc = "toggle diagnostics" })
      vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, {})
      vim.keymap.set("n", "]d", vim.diagnostic.goto_next, {})
      vim.keymap.set("n", "<leader>cf", vim.diagnostic.open_float, {})
    end,
  },
}
