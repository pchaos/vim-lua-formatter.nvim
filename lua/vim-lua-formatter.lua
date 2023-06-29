-- Last Modified: 2023-06-29 20:08:26

local cmd = vim.cmd -- execute Vim commands
local exec = vim.api.nvim_exec -- execute Vimscript
local fn = vim.fn -- call Vim functions
local g = vim.g -- global variables
local opt = vim.opt -- global/buffer/windows-scoped options
local api = vim.api

local function GetPluginDirectory()
    local scriptPath = debug.getinfo(1, 'S').source:sub(2)
    local pluginDirectory = vim.fn.fnamemodify(scriptPath, ':h')
    return pluginDirectory
end

local function printFileContent(filePath)
    local file = io.open(filePath, "r")
    if file then
        local content = file:read("*a")
        io.close(file)
        print(content)
    else
        print("无法打开文件：" .. filePath)
    end
end

local function isExecutableExists(executable)
    local command = "command -v " .. executable

    -- 执行命令并获取结果
    local handle = io.popen(command)
    local result = handle:read("*a")
    handle:close()

    -- 判断结果是否为空
    if result ~= "" then
        return true
    else
        return false
    end
end

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
    api.nvim_call_function("redraw!")
  -- cmd("redraw!")
end

function lua_format_format()
    local input = api.nvim_buf_get_lines(0, 0, -1, false)

    -- create a temporary file to capture error messages
    local error_file = fn.tempname()

    local flags = " -i "

    -- use config file for formatting if available
    local config_file = fn.findfile(".lua-format", ".;")
    if config_file ~= "" then 
      flags = flags .. " -c " .. config_file
    else
    -- todo 如果没有找到".lua-format"文件，则使用插件提供的默认配置文件：".lua-format.default"
    local pluginDirectory = GetPluginDirectory()
    print("插件所在目录：" .. pluginDirectory)
        config_file = fn.findfile(".lua-format.default", "pluginDirectory;pluginDirectory/**")
    if config_file ~= "" then
    flags = flags .. " -c " .. config_file
    end

  end
    print(config_file,"flag:" .. sflags)
    printFileContent(config_file. "error_file:" .. error_file)

local executableExists = isExecutableExists("lua-format")
if executableExists then
    print("lua-format 可执行文件存在")
else
    print("lua-format 可执行文件不存在")
end
    local command = "lua-format" .. flags .. " 2> " .. error_file
    local output, exit_code = fn.systemlist(command, input)

    if exit_code == 0 then -- all right
        lua_format_CopyDiffToBuffer(input, output, fn.bufname("%"))

        -- clear message buffer
        api.nvim_call_function('lexpr', {""})
        api.nvim_call_function('lwindow', {})
        -- cmd("lexpr \"\"")
        -- cmd("lwindow")
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
        api.nvim_call_function('lwindow', {5})
        -- cmd("lwindow 5")
    end

    -- delete the temporary file
    fn.delete(error_file)
end
