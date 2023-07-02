# [ vim-lua-format.nvim ](https://github.com/pchaos/vim-lua-formatter.nvim)

Last Modified: 2023-07-03 00:29:54

vim-lua-format.nvim is forked from [vim-lua-format](https://github.com/andrejlevkovitch/vim-lua-format), and rewrited wth lua.

_Add default lua-format config file:".lua_format.default"(when not found ".lua-format" then using this default config file)._

Lua vim formatter supported by [LuaFormatter](https://github.com/Koihik/LuaFormatter).

## Install

Use lazy.nvim, add this to "plugin.lua"

```
{
    "pchaos/vim-lua-formatter.nvim",
    branch="main",
    ft={ "lua"}
},
```

And it's done!

Then press `<C-K>` or simply save some `*.lua` file to format the Lua code automatically.

**NOTE** if you need to use the `LuaFormat()` function directly from command mode, you should call it explicitly as `:lua LuaFormat()`

## Features

Reformats your Lua source code with default config file : **".lua-format.default"**.

## Extension Settings

- `.lua-format`: Specifies the style config file. [Style Options](https://github.com/Koihik/LuaFormatter/wiki/Style-Config)

The `.lua-format` file must be in the source or parent directory. If there is no configuration file the default settings are used.

## Known Issues

1. You may have an error that claims unknown `-i` or `-si` options. This is happening because some versions of `lua-formatter` uses different flags.

So if you get any error about unknown flag, just change it to the correct flag in [flags](https://github.com/jefersonf/vim-lua-format/blob/e94e10b969bf42b76e2558d079a2765dca5baa79/autoload/lua_format.vim#L40) string variable at `lua_format_format()` function.

2. No line breaks after closing block comment
   In files with block comments, something like this:

```
--[[
Bigger comment
--]]

local var
```

becomes this after format with default settings.

```
--[[
Bigger comment
--]] local var
```

This was seen with the version included in current vscode plugin: vscode-lua-format-1.3.6
(the lua-format binary does not include a version number)

A workaround for this issue is ending a multiline comment with --]] --

```
--[[
Bigger comment
--]] --

local var
```
