-- Last Modified: 2023-06-29 11:07:39
local ok, _ = pcall(require, 'lua_format_format')
if not ok then
    -- not loaded
    print("function lua_format_format not found.")
    require("vim-lua-formatter")
else
    return
end

function lua_format() lua_format_format() end

vim.cmd([[
  autocmd FileType lua nnoremap <buffer> <c-k> :call LuaFormat()<cr>
  autocmd BufWritePre *.lua call LuaFormat()
]])
