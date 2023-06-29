-- Last Modified: 2023-06-29 17:45:26
if vim.api.nvim_eval('exists("g:loaded_vim_lua_formatter")') ~= 0 then
  return
end

local api = vim.api
local cmd=vim.cmd
local o=vim.o
pp
local save_cpo = o.cpo -- save user coptions
o.cpo = vim.o.cpo .. 'vim' -- reset them to defaults

local ok, lua_formatter = pcall(require, 'vim-lua-formatter')
if not ok then
    -- not loaded
    print("function lua_format_format not found.")
    require("vim-lua-formatter")
  return
else
    print(lua_formatter, "define lua_format as lua_format_format")
  function lua_format() lua_format_format() end
end

o.cpo = save_cpo -- and restore after
_G.loaded_vim_lua_formatter= 1

-- cmd([[
--   autocmd FileType lua nnoremap <buffer> <c-l> :call lua_format()<cr>
--   autocmd BufWritePre *.lua call lua_format()
-- ]])
-- cmd([[
--   autocmd FileType lua nnoremap <buffer> <c-l> :call lua_format()<cr>
-- ]])

-- cmd([[
--   autocmd BufWritePre *.lua call lua_format()
-- ]])
api.nvim_command([[
  autocmd FileType lua nnoremap <buffer> <c-l> :call lua_format()<cr>
]])

api.nvim_command([[
  autocmd BufWritePre *.lua call lua_format()
]])

print("end of vim-lua-formatter!")
