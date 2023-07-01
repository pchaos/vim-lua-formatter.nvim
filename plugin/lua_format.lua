-- Last Modified: 2023-07-01 19:20:15

local api = vim.api
if api.nvim_eval('exists("g:loaded_vim_lua_formatter")') ~= 1 then
  print("lua-format loaded", 3000) 
  return
end

local cmd = vim.cmd
local o = vim.o
local api = vim.api
local save_cpo = o.cpo -- save user coptions
o.cpo = vim.o.cpo .. 'vim' -- reset them to defaults
if api.nvim_eval('exists("g:loaded_vim_lua_formatter")') ~= 0 then
local ok, result = pcall(require, 'vim-lua-formatter')
if not ok then
  -- not loaded
  print(result)
  require("vim-lua-formatter")
  showAutoDismissMessage("require lua-formatdefined", 3000) 
end
-- print(lua_formatter, "define lua_format as lua_format_format")
function lua_format() lua_format_format() end
  showAutoDismissMessage("lua-format defined", 3000) 
end

o.cpo = save_cpo -- and restore after
_G.loaded_vim_lua_formatter = 1
_G.vim_lua_formatter_enabled = 0

if _G.vim_lua_formatter_enabled == 1 then
  cmd([[
    autocmd FileType lua nnoremap <buffer> <c-l> :lua lua_format()<cr>
  ]])

  cmd([[
    autocmd BufWritePre *.lua lua lua_format()
  ]])
end
