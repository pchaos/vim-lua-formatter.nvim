-- Last Modified: 2023-07-02 18:43:35
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

function showAutoDismissMessage(message, timeout)
  -- 调用函数显示消息（使用默认的五秒超时时间）
  -- showAutoDismissMessage("这是一条自动消失的消息")
  timeout = timeout or 5000 -- 如果没有提供超时时间参数，则使用默认值（单位为毫秒）

  vim.notify(message, vim.log.levels.INFO, { timeout = timeout })
end

local function printFileContent(filePath)
  if filePath and filePath ~= "" then -- 判断文件名是否为空或者空字符串
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

function printValue(value)
  for k, v in pairs(value) do
    print(k, v)
  end
end

local function getConfigFile()
  -- 查找当前文件所在所目录以及递归上级目录下的".lua-format"文件，找不到，就找本插件目录下的".lua-format.default"作为默认lua-fomat配置文件
  -- 从当前目录开始逐级向上查找 ".lua-format.default" 文件。如果找到文件，将返回文件的路径；如果没有找到，则返回空字符串。
  -- Searches from the directory of the current file upwards until it finds the file ".lua-format".
  local config_file = fn.findfile(".lua-format", ".;")
  local flags = " -i "

  if config_file and config_file ~= "" then
    flags = flags .. " -c " .. config_file
  else
    local pluginDirectory = GetPluginDirectory()
    -- print("插件所在目录：" .. pluginDirectory)
    local currentDirectory = pluginDirectory
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

    if config_file ~= "" then
      flags = flags .. " -c " .. config_file
    end
  end

  -- print("getConfigFile return: " .. config_file)
  return config_file, flags
end

local function lua_format_CopyDiffToBuffer(input, output, bufname)
  -- 在替换buffer之前，获取当前光标位置
  local cursor_pos = vim.api.nvim_win_get_cursor(0)

  -- prevent out of range in cickle
  local min_len = math.min(#input, #output)

  showAutoDismissMessage("Before format: " .. #input .. " lines. After format " .. #output .. " lines", 3000)
  if #output > 0 then
    if #output == #input then
      local mt = {
        __eq = function(t1, t2)
          -- 比较两个table的内容是否相同
          if #t1 ~= #t2 then
            return false
          end
          for i = 1, #t1 do
            if t1[i] ~= t2[i] then
              return false
            end
          end
          return true
        end,
      }
      -- 设置table的元表
      setmetatable(input, mt)
      setmetatable(output, mt)
      -- 比较两个table的内容是否相等
      if input == output then
        -- 不需要格式化代码
        showAutoDismissMessage("No need to format.")
        return
      end
    end
    -- Clearing a Buffer
    vim.api.nvim_buf_set_lines(bufname, 0, -1, true, {})
    local extra_lines = {}
    for j = 1, #output do
      table.insert(extra_lines, output[j])
      -- showAutoDismissMessage("ex " .. output[j], 3000)
    end
    api.nvim_buf_set_lines(bufname, -2, -1, true, extra_lines)
    -- 恢复光标位置
    vim.api.nvim_win_set_cursor(0, cursor_pos)
    showAutoDismissMessage("lua-format success.", 3000)
  end
  -- redraw windows to prevent invalid data display
  cmd("redraw!")
end

function lua_format_format()
  -- local current_cmdheight= opt.cmdheight
  -- opt.cmdheight = 8
  showAutoDismissMessage("lua-format start", 3000)
  -- 获取当前活动窗口
  local current_win = api.nvim_get_current_win()

  local input = api.nvim_buf_get_lines(0, 0, -1, false)

  -- create a temporary file to capture error messages
  local error_file = fn.tempname()

  local configFile, flags = getConfigFile()
  -- print(configFile, " flags:" .. flags)
  -- print("error_file:" .. error_file)
  -- printFileContent(configFile)

  local executableExists = isExecutableExists("lua-format")
  if executableExists then
    -- print("可执行文件lua-format存在")
    --
    local command = "lua-format " .. flags .. " 2> " .. error_file
    output = fn.systemlist(command, input)
    -- local output = fn.system(command, input)
    -- print("input:" .. #input)
    -- printValue(input)
    -- print(command)
    -- print(" output:" .. #output)
    -- print(command)
    -- printValue(output)
    if #output > 0 then -- all right
      -- lua_format_CopyDiffToBuffer(input, output, fn.bufname("%"))
      lua_format_CopyDiffToBuffer(input, output, 0)

      -- clear message buffer
      cmd("messages clear")

      -- exec('lexpr',  "" )
      api.nvim_command("lexpr ''")
      api.nvim_set_current_win(current_win)
    else -- we got an error
      print("Something error!")
      local errors = fn.readfile(error_file)

      -- insert filename of current buffer in front of the list. Needed for errorformat
      local source_file = fn.bufname("%")
      -- Insert filename of current buffer at the beginning of the list
      table.insert(errors, 1, source_file)

      opt.efm = "%+P%f,line\\ %l:%c\\ %m,%-Q"
      api.nvim_command(":call setloclist(0, " .. vim.inspect(errors) .. ")")
      -- 切换到窗口 
      api.nvim_set_current_win(current_win)
      -- delete the temporary file
      fn.delete(error_file)
    end
  else
    -- print("可执行文件lua-format不存在,请先安装lua-format")
    showAutoDismissMessage("可执行文件lua-format不存在,请先安装lua-format")
  end

  -- opt.cmdheight =current_cmmdheight 
end
