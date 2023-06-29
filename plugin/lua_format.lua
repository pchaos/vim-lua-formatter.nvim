-- Last Modified: 2023-06-29 18:12:38
if vim.api.nvim_eval('exists("g:loaded_vim_lua_formatter")') ~= 0 then
  return
end

local cmd=vim.cmd
local o=vim.o

local save_cpo = o.cpo -- save user coptions
o.cpo = vim.o.cpo .. 'vim' -- reset them to defaults

local ok, lua_formatter = pcall(require, 'vim-lua-formatter')
if not ok then
    -- not loaded
    -- print("function lua_format_format not found.")
    require("vim-lua-formatter")
  return
else
    -- print(lua_formatter, "define lua_format as lua_format_format")
  function lua_format() lua_format.format() end
end

o.cpo = save_cpo -- and restore after
_G.loaded_vim_lua_formatter= 1

-- cmd([[
--   autocmd FileType lua nnoremap <buffer> <c-l> :call lua_format()<cr>
--   autocmd BufWritePre *.lua call lua_format()
-- ]])

cmd([[
  autocmd FileType lua nnoremap <buffer> <c-l> :lua lua_format()<cr>
]])

cmd([[
  autocmd BufWritePre *.lua lua lua_format()
]])

-- print("end of vim-lua-formatter!")
