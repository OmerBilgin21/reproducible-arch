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
    "williamboman/mason.nvim",
    lazy = false,
    config = function()
      require("mason").setup()
    end,
  },
  {
    "neovim/nvim-lspconfig",
    dependencies = { "saghen/blink.cmp" },
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
        gopls = {
          settings = {
            gopls = {
              buildFlags = { "-tags=integration" },
            },
          },
        },
        vtsls = {},
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
          settings = {
            run = "onSave",
            format = false,
          },
          on_attach = function(_, bufnr)
            local eslint_client = vim.lsp.get_clients({ bufnr = bufnr, name = "eslint" })[1]
            if not eslint_client then
              return
            end

            vim.api.nvim_create_autocmd("BufWritePre", {
              buffer = bufnr,
              callback = function()
                eslint_client:request_sync("workspace/executeCommand", {
                  command = "eslint.applyAllFixes",
                  arguments = {
                    {
                      uri = vim.uri_from_bufnr(bufnr),
                      version = vim.lsp.util.buf_versions[bufnr],
                    },
                  },
                }, nil, bufnr)
              end,
            })
          end,
        },
      },
    },
    config = function(_, opts)
      for server, config in pairs(opts.servers) do
        config.capabilities = require("blink.cmp").get_lsp_capabilities(config.capabilities)
        vim.lsp.config(server, config)
        vim.lsp.enable(server)
      end

      vim.diagnostic.config({
        virtual_text = true,
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
          local client = event.data and vim.lsp.get_client_by_id(event.data.client_id)
          if client and (client.name == "ts_ls" or client.name == "vtsls") then
            -- This trims per-keystroke TS token traffic to keep editing responsive.
            client.server_capabilities.semanticTokensProvider = nil
          end

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
