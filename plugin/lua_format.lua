-- Last Modified: 2023-06-29 15:44:55
local ok, lua_formatter = pcall(require, 'vim-lua-formatter')
if not ok then
    -- not loaded
    print("function lua_format_format not found.")
    require("vim-lua-formatter")
  function lua_format() lua_format_format() end
else
    return
end


vim.cmd([[
  autocmd FileType lua nnoremap <buffer> <c-k> :call LuaFormat()<cr>
  autocmd BufWritePre *.lua call LuaFormat()
]])
