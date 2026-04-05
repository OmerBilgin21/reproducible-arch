return {
  {
    "williamboman/mason.nvim",
    lazy = false,
    config = function()
      require("mason").setup()

      local packages = {
        -- LSP servers
        "bash-language-server",
        "lua-language-server",
        "gopls",
        "typescript-language-server",
        "pyright",
        "dockerfile-language-server",
        "docker-compose-language-service",
        "vtsls",
        -- linter
        "shellcheck",
        "eslint_d",
        -- DAP adapters
        "delve",
        -- Formatters
        "stylua",
        "shfmt",
        "isort",
        "black",
        "sqlfmt",
        "prettier",
        "gofmt",
        "jq",
      }

      local registry = require("mason-registry")
      registry.refresh(function()
        for _, pkg_name in ipairs(packages) do
          local ok, pkg = pcall(registry.get_package, pkg_name)
          if ok and not pkg:is_installed() then
            pkg:install()
          end
        end
      end)
    end,
  },
}
