return {
  {
    "fredrikaverpil/godoc.nvim",
    version = "*",
    dependencies = {
      { "nvim-telescope/telescope.nvim" }, -- optional
      {
        "nvim-treesitter/nvim-treesitter",
        branch = "main",
        build = ":TSUpdate godoc go", -- install/update parsers
        config = function()
          require("nvim-treesitter.parsers").godoc = {
            install_info = {
              url = "https://github.com/fredrikaverpil/tree-sitter-godoc",
              files = { "src/parser.c" },
              version = "*",
            },
            filetype = "godoc",
          }

          -- Map godoc filetype to use godoc parser
          vim.treesitter.language.register("godoc", "godoc")

          -- Enable :TSInstall godoc, :TSUpdate godoc
          vim.api.nvim_create_autocmd("User", {
            pattern = "TSUpdate",
            callback = function()
              require("nvim-treesitter.parsers").godoc = parser_config
            end,
          })

          -- Enable godoc filetype for .godoc files (optional)
          vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
            pattern = "*.godoc",
            callback = function()
              vim.bo.filetype = "godoc"
            end,
          })
        end,
      },
    },
    build = "go install github.com/lotusirous/gostdsym/stdsym@latest", -- optional
    cmd = { "GoDoc" }, -- optional
    ft = "godoc", -- optional
    opts = { picker = { type = "telescope" } }, -- see further down below for configuration
  },
  {
    "folke/lazydev.nvim",
    ft = "lua",
    opts = {
      library = {
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
        { path = "lazy.nvim", words = { "LazyPlugin", "LazySpec" } },
        { path = "blink.cmp" },
        { path = "conform.nvim" },
        { path = "mason.nvim" },
        { path = "nvim-lspconfig" },
        { path = "render-markdown" },
        { path = "telescope.nvim" },
        { path = "LuaSnip" },
      },
    },
  },
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
    opts = function()
      local mason_bin = vim.fn.stdpath("data") .. "/mason/bin/"
      return {
        servers = {
          bashls = {
            filetypes = { "sh", "bash", "zsh" },
            cmd = { mason_bin .. "bash-language-server", "start" },
          },
          lua_ls = {
            filetypes = { "lua" },
            cmd = { mason_bin .. "lua-language-server" },
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
            filetypes = { "go", "gomod", "gowork", "gotmpl" },
            cmd = { mason_bin .. "gopls" },
            settings = {
              gopls = {
                buildFlags = { "-tags=integration" },
              },
            },
          },
          ts_ls = {
            filetypes = { "typescript", "javascript", "typescriptreact", "javascriptreact" },
            cmd = { mason_bin .. "typescript-language-server", "--stdio" },
            init_options = {
              hostInfo = "neovim",
              maxTsServerMemory = 8192,
              preferences = {
                includePackageJsonAutoImports = "auto",
              },
            },
          },
          pyright = {
            filetypes = { "python" },
            cmd = { mason_bin .. "pyright-langserver", "--stdio" },
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
            cmd = { mason_bin .. "docker-langserver", "--stdio" },
          },
          docker_compose_language_service = {
            filetypes = { "yaml" },
            cmd = { mason_bin .. "docker-compose-langserver", "--stdio" },
          },
        },
      }
    end,
    config = function(_, opts)
      for server, config in pairs(opts.servers) do
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

      -- hover with border but it's stupidly complicated :D
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(event)
          local client = event.data and vim.lsp.get_client_by_id(event.data.client_id)
          if client and client.name == "ts_ls" then
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

      vim.keymap.set("n", "<leader>cv", function()
        local current = vim.diagnostic.config().virtual_text
        vim.diagnostic.config({ virtual_text = not current })
      end, {})
    end,
  },
}
