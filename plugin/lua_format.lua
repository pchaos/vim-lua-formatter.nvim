-- Last Modified: 2023-06-29 16:40:32
--
local ok, lua_formatter = pcall(require, 'vim-lua-formatter')
if not ok then
    -- not loaded
    print("function lua_format_format not found.")
    require("vim-lua-formatter")
  return
else
    print("define lua_format")
  function lua_format() lua_format_format() end
end

vim.cmd([[
  autocmd FileType lua nnoremap <buffer> <c-l> :call LuaFormat()<cr>
  autocmd BufWritePre *.lua call LuaFormat()
]])
