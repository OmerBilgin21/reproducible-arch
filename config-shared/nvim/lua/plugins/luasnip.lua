return {
  "L3MON4D3/LuaSnip",
  version = "2.*",
  config = function()
    local ls = require("luasnip")
    local s = ls.snippet
    local t = ls.text_node
    local i = ls.insert_node
    local rep = require("luasnip.extras").rep
    require("luasnip").config.set_config({
      history = true,
      enable_autosnippets = true,
    })

    ls.add_snippets("sh", {
      s("shebang", {
        t("#!/bin/bash"),
      }),
    })

    ls.add_snippets("typescriptreact", {
      s("tsrafce", {
        t({ "import React from 'react';", "" }),
        t({ "type Props = {};", "" }),
        t({ "", "const " }),
        i(1, "ComponentName"),
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
    })

    ls.add_snippets("typescriptreact", {
      s("debugg", {
        t("style={{border: '4px solid red'}}"),
      }),
    })

    ls.add_snippets("go", {
      s("iferr", {
        t("if err != nil {"),
        t({ "", "\t" }),
        i(1, "/* handle error */"),
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
  end,
}

