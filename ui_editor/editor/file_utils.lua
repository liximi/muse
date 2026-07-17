--------------------------------------------------
-- file_utils.lua — 跨平台文件系统工具
-- 提供目录枚举、路径检查、原生系统对话框
--------------------------------------------------

local function getOS()
	return love and love.system.getOS() or "Windows"
end

--------------------------------------------------
-- 枚举目录下的所有条目（文件 + 子目录）
--------------------------------------------------
local function listDirectory(path)
	local items = {}
	if not path or path == "" then return items end

	local os_name = getOS()
	if os_name == "Windows" then
		local dir_path = path
		if dir_path:sub(-1) ~= "\\" and dir_path:sub(-1) ~= "/" then
			dir_path = dir_path .. "\\"
		end
		local cmd = 'dir /b "' .. dir_path .. '" 2>nul'
		local handle = io.popen(cmd)
		if not handle then return items end
		for line in handle:lines() do
			line = line:gsub("^%s+", ""):gsub("%s+$", "")
			if line ~= "" then table.insert(items, {name = line, is_dir = false}) end
		end
		handle:close()

		-- 用 dir /ad 获取目录列表
		local dir_set = {}
		local h = io.popen('dir /b /ad "' .. dir_path .. '" 2>nul')
		if h then
			for line in h:lines() do
				line = line:gsub("^%s+", ""):gsub("%s+$", "")
				if line ~= "" then dir_set[line] = true end
			end
			h:close()
		end
		for _, item in ipairs(items) do
			if dir_set[item.name] then item.is_dir = true end
		end
	else
		local cmd = 'ls -1p "' .. path .. '" 2>/dev/null'
		local handle = io.popen(cmd)
		if not handle then return items end
		for line in handle:lines() do
			line = line:gsub("^%s+", ""):gsub("%s+$", "")
			if line ~= "" then
				local is_dir = false
				if line:sub(-1) == "/" then
					line = line:sub(1, -2)
					is_dir = true
				end
				table.insert(items, {name = line, is_dir = is_dir})
			end
		end
		handle:close()
	end
	return items
end

--------------------------------------------------
-- 检查路径是否存在
--------------------------------------------------
local function pathExists(path)
	local f = io.open(path, "r")
	if f then f:close(); return true end
	local ok = os.rename(path, path)
	return ok ~= nil
end

--------------------------------------------------
-- 检查是否是目录
--------------------------------------------------
local function isDirectory(path)
	local os_name = getOS()
	if os_name == "Windows" then
		local cmd = 'if exist "' .. path .. '\\." (echo DIR) else (echo FILE)'
		local handle = io.popen(cmd)
		if handle then
			local result = handle:read("*a")
			handle:close()
			return result and result:find("DIR") ~= nil
		end
	else
		local cmd = 'test -d "' .. path .. '" && echo DIR || echo FILE'
		local handle = io.popen(cmd)
		if handle then
			local result = handle:read("*a")
			handle:close()
			return result and result:find("DIR") ~= nil
		end
	end
	return false
end

--------------------------------------------------
-- 创建目录（递归）
--------------------------------------------------
local function createDirectory(path)
	local os_name = getOS()
	if os_name == "Windows" then
		os.execute('mkdir "' .. path .. '" 2>nul')
	else
		os.execute('mkdir -p "' .. path .. '" 2>/dev/null')
	end
end

--------------------------------------------------
-- 路径拼接
--------------------------------------------------
local sep = (getOS() == "Windows") and "\\" or "/"
local function joinPath(...)
	local parts = {...}
	local result = ""
	for i, p in ipairs(parts) do
		if p and p ~= "" then
			if result == "" then
				result = p
			else
				local p1 = result:gsub("[/\\]+$", "")
				local p2 = p:gsub("^[/\\]+", "")
				result = p1 .. sep .. p2
			end
		end
	end
	return result
end

--------------------------------------------------
-- 获取父目录
--------------------------------------------------
local function getParentPath(path)
	path = path:gsub("[/\\]+$", "")
	local parent = path:match("^(.+)[/\\].-$")
	return parent or path
end

--------------------------------------------------
-- 获取文件名（不含路径）
--------------------------------------------------
local function getFileName(path)
	return path:match("[/\\]([^/\\]+)$") or path
end

--------------------------------------------------
-- 获取文件扩展名（小写）
--------------------------------------------------
local function getExtension(path)
	return (path:match("%.([^%.\\/]+)$") or ""):lower()
end

--------------------------------------------------
-- 原生系统对话框（通过 PowerShell / zenity）
--------------------------------------------------

--- 原生「打开文件」对话框
local function nativeOpenFile(start_dir, title)
	local os_name = getOS()
	local result = nil

	if os_name == "Windows" then
		local init_dir = start_dir or ""
		local dlg_title = title or "Open .mui File"
		local ps_cmd = [[powershell -NoProfile -Command "]]
			.. [[Add-Type -AssemblyName System.Windows.Forms; ]]
			.. [[$d = New-Object System.Windows.Forms.OpenFileDialog; ]]
			.. [[$d.Filter = 'Muse UI (*.mui)|*.mui'; ]]
			.. '$d.Title = \'' .. dlg_title .. [[\'; ]]
			.. '$d.InitialDirectory = \'' .. init_dir .. [[\'; ]]
			.. [[if ($d.ShowDialog() -eq 'OK') { Write-Output $d.FileName }"]]
		local handle = io.popen(ps_cmd)
		if handle then
			local output = handle:read("*a"):gsub("^%s+", ""):gsub("%s+$", "")
			handle:close()
			if output ~= "" then result = output end
		end
	else
		local cmd = string.format(
			'zenity --file-selection --title="%s" --file-filter="*.mui" 2>/dev/null',
			title or "Open .mui File"
		)
		local handle = io.popen(cmd)
		if handle then
			local output = handle:read("*a"):gsub("^%s+", ""):gsub("%s+$", "")
			handle:close()
			if output ~= "" then result = output end
		end
	end
	return result
end

--- 原生「保存文件」对话框
local function nativeSaveFile(start_dir, default_name, title)
	local os_name = getOS()
	local result = nil

	if os_name == "Windows" then
		local init_dir = start_dir or ""
		local fname = default_name or "untitled.mui"
		local dlg_title = title or "Save .mui File"
		local ps_cmd = [[powershell -NoProfile -Command "]]
			.. [[Add-Type -AssemblyName System.Windows.Forms; ]]
			.. [[$d = New-Object System.Windows.Forms.SaveFileDialog; ]]
			.. [[$d.Filter = 'Muse UI (*.mui)|*.mui'; ]]
			.. [[$d.DefaultExt = 'mui'; ]]
			.. '$d.Title = \'' .. dlg_title .. [[\'; ]]
			.. '$d.FileName = \'' .. fname .. [[\'; ]]
			.. '$d.InitialDirectory = \'' .. init_dir .. [[\'; ]]
			.. [[if ($d.ShowDialog() -eq 'OK') { Write-Output $d.FileName }"]]
		local handle = io.popen(ps_cmd)
		if handle then
			local output = handle:read("*a"):gsub("^%s+", ""):gsub("%s+$", "")
			handle:close()
			if output ~= "" then result = output end
		end
	else
		local cmd = string.format(
			'zenity --file-selection --save --title="%s" --filename="%s" 2>/dev/null',
			title or "Save .mui File",
			default_name or "untitled.mui"
		)
		local handle = io.popen(cmd)
		if handle then
			local output = handle:read("*a"):gsub("^%s+", ""):gsub("%s+$", "")
			handle:close()
			if output ~= "" then result = output end
		end
	end
	return result
end

--- 原生「选择文件夹」对话框
local function nativeSelectFolder(start_dir, title)
	local os_name = getOS()
	local result = nil

	if os_name == "Windows" then
		local init_dir = start_dir or ""
		local dlg_title = title or "Select Project Folder"
		local ps_cmd = [[powershell -NoProfile -Command "]]
			.. [[Add-Type -AssemblyName System.Windows.Forms; ]]
			.. [[$d = New-Object System.Windows.Forms.FolderBrowserDialog; ]]
			.. '$d.Description = \'' .. dlg_title .. [[\'; ]]
			.. '$d.SelectedPath = \'' .. init_dir .. [[\'; ]]
			.. [[if ($d.ShowDialog() -eq 'OK') { Write-Output $d.SelectedPath }"]]
		local handle = io.popen(ps_cmd)
		if handle then
			local output = handle:read("*a"):gsub("^%s+", ""):gsub("%s+$", "")
			handle:close()
			if output ~= "" then result = output end
		end
	else
		local cmd = string.format(
			'zenity --file-selection --directory --title="%s" 2>/dev/null',
			title or "Select Project Folder"
		)
		local handle = io.popen(cmd)
		if handle then
			local output = handle:read("*a"):gsub("^%s+", ""):gsub("%s+$", "")
			handle:close()
			if output ~= "" then result = output end
		end
	end
	return result
end

return {
	listDirectory = listDirectory,
	pathExists = pathExists,
	isDirectory = isDirectory,
	createDirectory = createDirectory,
	joinPath = joinPath,
	getParentPath = getParentPath,
	getFileName = getFileName,
	getExtension = getExtension,
	nativeOpenFile = nativeOpenFile,
	nativeSaveFile = nativeSaveFile,
	nativeSelectFolder = nativeSelectFolder,
}
