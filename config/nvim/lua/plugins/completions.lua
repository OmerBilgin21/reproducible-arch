return {
  {
    "saghen/blink.cmp",
    dependencies = {
      {
        "L3MON4D3/LuaSnip",
        version = "v2.*",
      },
    },
    version = "1.*",
    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    opts = {
      keymap = { preset = "enter" },
      appearance = {
        nerd_font_variant = "mono",
      },
      completion = {
        menu = {
          border = "rounded",
          draw = {
            padding = { 1, 1 },
          },
        },
        documentation = {
          auto_show = false,
          auto_show_delay_ms = 300,
          -- border = "rounded",
          window = {
            border = "rounded",
            direction_priority = {
              menu_north = {
                "e",
                "w",
                "n",
                "s",
              },
            },
          },
        },
      },
      snippets = { preset = "luasnip" },
      sources = {
        per_filetype = {
          sql = {
            "snippets",
            "dadbod",
            "buffer",
          },
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
          path = {
            name = "Path",
            module = "blink.cmp.sources.path",
            score_offset = 50,
          },
          snippets = {
            name = "Snippets",
            module = "blink.cmp.sources.snippets",
            score_offset = 40,
          },
          buffer = {
            name = "Buffer",
            module = "blink.cmp.sources.buffer",
            score_offset = 10,
            min_keyword_length = 3,
          },
          dadbod = {
            name = "Dadbod",
            module = "config.dadbod-fuzzy",
            score_offset = 60,
          },
        },
      },
      -- never do this again, TERRRIBBBBLE speed
      -- fuzzy = { implementation = "prefer_rust_with_warning" },
    },
    opts_extend = { "sources.default" },
  },
}
