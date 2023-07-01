-- Last Modified: 2023-07-01 19:15:15

local api = vim.api
if api.nvim_eval('exists("g:loaded_vim_lua_formatter")') ~= 0 then
  return
end

local cmd=vim.cmd
local o=vim.o

local save_cpo = o.cpo -- save user coptions
o.cpo = vim.o.cpo .. 'vim' -- reset them to defaults

local ok, result = pcall(require, 'vim-lua-formatter')
if not ok then
    -- not loaded
  print(result)
    require("vim-lua-formatter")
end
    -- print(lua_formatter, "define lua_format as lua_format_format")
  function lua_format() lua_format_format() end

o.cpo = save_cpo -- and restore after
_G.loaded_vim_lua_formatter= 1

cmd([[
  autocmd FileType lua nnoremap <buffer> <c-l> :lua lua_format()<cr>
]])

cmd([[
  autocmd BufWritePre *.lua lua lua_format()
]])

