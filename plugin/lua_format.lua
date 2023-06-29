require("vim-lua-formatter")

function lua_format() lua_format_format() end

vim.cmd([[
  autocmd FileType lua nnoremap <buffer> <c-k> :call LuaFormat()<cr>
  autocmd BufWritePre *.lua call LuaFormat()
]])
