return {
  "kristijanhusak/vim-dadbod-ui",
  lazy = true,
  dependencies = {
    {
      "tpope/vim-dadbod",
      lazy = true,
      { "kristijanhusak/vim-dadbod-completion", ft = { "sql", "plsql" }, lazy = true },
    },
  },
  cmd = {
    "DBUI",
    "DBUIToggle",
    "DBUIAddConnection",
    "DBUIFindBuffer",
  },
  init = function()
    vim.g.db_ui_execute_on_save = 0
    vim.g.db_ui_save_location = vim.fn.expand("~/queries")
    vim.g.db_ui_use_nerd_fonts = 1
    vim.g.vim_dadbod_completion_omnifunc = 0

    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "sql", "plsql" },
      callback = function()
        vim.keymap.set("n", "<leader>gi", function()
          local input = vim.fn.input("schema.table: ")
          if not input or input == "" then
            return
          end
          local schema_name, table_name = input:match("^(.+)%.(.+)$")
          if not schema_name or not table_name then
            vim.notify("Expected format: schema.table", vim.log.levels.ERROR)
            return
          end

          local ok, rows = pcall(
            vim.fn["db_ui#query"],
            string.format(
              "SELECT column_name, data_type, column_default, is_nullable, udt_name"
                .. " FROM information_schema.columns"
                .. " WHERE table_name = '%s' AND table_schema = '%s'"
                .. " AND (column_default IS NULL OR column_default NOT LIKE 'nextval%%')"
                .. " AND is_generated = 'NEVER'"
                .. " AND identity_generation IS NULL"
                .. " ORDER BY ordinal_position",
              table_name,
              schema_name
            )
          )

          if not ok or not rows or #rows == 0 then
            vim.notify("Could not fetch columns for " .. schema_name .. "." .. table_name, vim.log.levels.ERROR)
            return
          end

          local columns = {}
          local values = {}
          for _, row in ipairs(rows) do
            local col = row[1]
            local dtype = row[2]
            local col_default = row[3] or ""
            local udt = row[5] or ""

            table.insert(columns, "  " .. col)

            local val
            if col:match("deleted_at") then
              val = "null"
            elseif col_default:match("gen_random_uuid") then
              val = "gen_random_uuid()"
            elseif dtype == "jsonb" then
              val = "'{}'::jsonb"
            elseif dtype == "json" then
              val = "'{}'::json"
            elseif dtype == "boolean" then
              val = "false"
            elseif dtype:match("int") or dtype == "numeric" or dtype:match("double") or dtype == "real" then
              val = "0"
            elseif dtype:match("timestamp") then
              val = "now()"
            elseif dtype == "date" then
              val = "current_date"
            elseif dtype == "ARRAY" then
              val = "'{}'"
            elseif dtype == "USER-DEFINED" then
              val = "'<" .. udt .. ">'"
            elseif dtype == "uuid" then
              val = "'<" .. col .. ">'"
            else
              val = "'<" .. col .. ">'"
            end
            table.insert(values, "  " .. val)
          end

          local lines = { string.format('INSERT INTO %s."%s" (', schema_name, table_name) }
          for idx, c in ipairs(columns) do
            table.insert(lines, c .. (idx < #columns and "," or ""))
          end
          table.insert(lines, ") VALUES (")
          for idx, v in ipairs(values) do
            table.insert(lines, v .. (idx < #values and "," or ""))
          end
          table.insert(lines, ");")

          vim.api.nvim_put(lines, "l", true, true)
        end, { buffer = true, desc = "Generate INSERT template from table columns" })
      end,
    })
  end,
  config = function()
    vim.api.nvim_create_autocmd("User", {
      pattern = "DBUIOpened",
      once = true,
      callback = function()
        vim.cmd([[
          function! db#adapter#postgresql#filter(url) abort
            return db#adapter#postgresql#interactive(a:url,
                  \ ['-x', '-P', 'columns=' . &columns, '-v', 'ON_ERROR_STOP=1'])
          endfunction
        ]])
      end,
    })
  end,
}
