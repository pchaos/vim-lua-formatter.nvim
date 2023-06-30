-- Last Modified: 2023-06-30 18:44:30

local cmd = vim.cmd -- execute Vim commands
local exec = vim.api.nvim_exec -- execute Vimscript
local fn = vim.fn -- call Vim functions
local g = vim.g -- global variables
local opt = vim.opt -- global/buffer/windows-scoped options
local api = vim.api

local function GetPluginDirectory()
  local scriptPath = debug.getinfo(1, 'S').source:sub(2)
  local pluginDirectory = fn.fnamemodify(scriptPath, ':h')
  return pluginDirectory
end

local function printFileContent(filePath)
  if filePath and filePath ~= "" then  -- 判断文件名是否为空或者空字符串
    local file = io.open(filePath, "r")
    if file then
      local content = file:read("*a")
      io.close(file)
      print(content)
    else
      print("无法打开文件：" .. filePath)
    end
  else
    print("文件名不能为空")
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

function printValue(value) for k, v in pairs(value) do print(k, v) end end

local function getConfigFile()
  -- 查找当前文件所在所目录以及递归上级目录下的".lua-format"文件，找不到，就找本插件目录下的".lua-format.default"作为默认lua-fomat配置文件
  -- 从当前目录开始逐级向上查找 ".lua-format.default" 文件。如果找到文件，将返回文件的路径；如果没有找到，则返回空字符串。
  local flags = " -i "
  local config_file = fn.findfile(".lua-format", ".;")

  if config_file ~= "" then
    flags = flags .. " -c " .. config_file
  else
    local pluginDirectory = GetPluginDirectory()
    print("插件所在目录：" .. pluginDirectory)
    local currentDirectory=pluginDirectory
    while true do
            local found_file = fn.findfile(".lua-format.default", currentDirectory)
      if found_file and found_file ~= "" then
        config_file = found_file
    -- print("getConfigFile found: " .. config_file)
        break
      end
    -- print("getConfigFile: " .. config_file)

    local parentDirectory = currentDirectory:gsub('[^/]+$', '')
    if parentDirectory == currentDirectory then
      break
    end

    currentDirectory = parentDirectory
  end

    if config_file ~= "" then flags = flags .. " -c " .. config_file end
  end

    -- print("getConfigFile return: " .. config_file)
  return config_file, flags
end

local function lua_format_CopyDiffToBuffer(input, output, bufname)
  -- prevent out of range in cickle
  local min_len = math.min(#input, #output)
  -- copy all lines that were changed
  for i = 1, min_len do
    local output_line = output[i]
    local input_line = input[i]
    if input_line ~= output_line then api.nvim_buf_set_lines(0, i, i, false, { output_line }) end
  end

  -- handle all lines that were in range
  if #input ~= #output then
    if min_len == #output then
      -- remove all extra lines from input
      api.nvim_buf_set_lines(0, min_len + 1, -1, false, {})
    else
      -- append all extra lines from output
      local extra_lines = {}
      for j = min_len + 1, #output do table.insert(extra_lines, output[j]) end
      api.nvim_buf_set_lines(0, -1, -1, true, extra_lines)
    end
  end

  -- redraw windows to prevent invalid data display
  -- api.nvim_call_function("redraw!", {})
  cmd("redraw!")
end

function lua_format_format()
  -- 获取当前活动窗口
  local current_win = api.nvim_get_current_win()

  local input = api.nvim_buf_get_lines(0, 0, -1, false)

  -- create a temporary file to capture error messages
  local error_file = fn.tempname()

  -- local flags = " -i "

  -- -- use config file for formatting if available
  -- local config_file = fn.findfile(".lua-format", ".;")
  -- if config_file ~= "" then
  --   flags = flags .. " -c " .. config_file
  -- else
  --   -- todo 如果没有找到".lua-format"文件，则使用插件提供的默认配置文件：".lua-format.default"
  --   local pluginDirectory = GetPluginDirectory()
  --   print("插件所在目录：" .. pluginDirectory)
  --   config_file = fn.findfile(".lua-format.default", "pluginDirectory;pluginDirectory/**")
  --   if config_file ~= "" then flags = flags .. " -c " .. config_file end

  -- end
  local configFile, flags = getConfigFile()
  print(configFile, " flags:" .. flags)
  print("error_file:" .. error_file)
  -- printFileContent(configFile)

  local executableExists = isExecutableExists("lua-format")
  if executableExists then
    print("可执行文件lua-format存在")
    --
    local command = "lua-format " .. flags .. " 2> " .. error_file
    output = fn.systemlist(command, input)
    -- local output = fn.system(command, input)
    print("input:" .. #input)
    printValue(input)
    print(command)
    print(" output:" .. #output)
    print(command)
    -- printValue(output)
    if #output > 0 then -- all right
      lua_format_CopyDiffToBuffer(input, output, fn.bufname("%"))

      -- clear message buffer
      cmd("messages clear")

      -- api.nvim_call_function('lexpr', { "" })
      -- api.nvim_call_function('lwindow', {})
      api.nvim_set_current_win(current_win)
      -- cmd("lexpr \"\"")
      -- cmd("lwindow")
    else -- we got an error
      local errors = fn.readfile(error_file)

      -- insert filename of current buffer in front of the list. Needed for errorformat
      local source_file = fn.bufname("%")
      table.insert(errors, 1, source_file)
      opt.efm = "%+P%f,line\\ %l:%c\\ %m,%-Q"
      fn.lexpr(errors)
      -- api.nvim_set_loclist(0, errors)
      -- api.nvim_call_function('setloclist', { 0, errors, 'r' })
      -- api.nvim_call_function('lwindow', {5})
      -- 切换到窗口编号 5
      api.nvim_set_current_win(current_win)
      -- delete the temporary file
      fn.delete(error_file)
    end
  else
    print("可执行文件lua-format不存在")
    return
  end

end
