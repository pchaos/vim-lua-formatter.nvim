-- Last Modified: 2023-06-29 18:59:49

local cmd = vim.cmd -- execute Vim commands
local exec = vim.api.nvim_exec -- execute Vimscript
local fn = vim.fn -- call Vim functions
local g = vim.g -- global variables
local opt = vim.opt -- global/buffer/windows-scoped options
local api = vim.api

local function lua_format_CopyDiffToBuffer(input, output, bufname)
    -- prevent out of range in cickle
    local min_len = math.min(#input, #output)

    -- copy all lines that were changed
    for i = 1, min_len do
        local output_line = output[i]
        local input_line = input[i]
        if input_line ~= output_line then
            api.nvim_buf_set_lines(0, i, i, false, {output_line})
        end
    end

    -- handle all lines that were in range
    if #input ~= #output then
        if min_len == #output then
            -- remove all extra lines from input
            api.nvim_buf_set_lines(0, min_len + 1, -1, false, {})
        else
            -- append all extra lines from output
            local extra_lines = {}
            for j = min_len + 1, #output do
                table.insert(extra_lines, output[j])
            end
            api.nvim_buf_set_lines(0, -1, -1, true, extra_lines)
        end
    end

    -- redraw windows to prevent invalid data display
    cmd("redraw!")
end

function lua_format_format()
    local input = api.nvim_buf_get_lines(0, 0, -1, false)

    -- create a temporary file to capture error messages
    local error_file = fn.tempname()

    local flags = " -i "

    -- use config file for formatting if available
    local config_file = fn.findfile(".lua-format", ".;")
    if config_file ~= "" then flags = flags .. " -c " .. config_file end
  -- todo 如果没有找到".lua-format"文件，则使用插件提供的默认配置文件：".lua-format.default"

    local command = "lua-format" .. flags .. " 2> " .. error_file
    local output, exit_code = fn.systemlist(command, input)

    if exit_code == 0 then -- all right
        lua_format_CopyDiffToBuffer(input, output, fn.bufname("%"))

        -- clear message buffer
        cmd("lexpr \"\"")
        cmd("lwindow")
    else -- we got an error
        local errors = fn.readfile(error_file)

        -- insert filename of current buffer in front of the list. Needed for errorformat
        local source_file = fn.bufname("%")
        table.insert(errors, 1, source_file)

        opt.efm = "%+P%f,line\\ %l:%c\\ %m,%-Q"
        -- for k, v in pairs(errors) do
        --     print(k, v)
        -- end
        api.nvim_call_function('setloclist', {0, errors, 'r'})
        cmd("lwindow 5")
    end

    -- delete the temporary file
    fn.delete(error_file)
end
