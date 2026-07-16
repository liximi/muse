--------------------------------------------------
-- lua_scaffold.lua — .mui → .lua 行为脚本骨架生成
--
-- 用法：
--   local Scaffold = require "ui_editor.editor.lua_scaffold"
--   local code = Scaffold.generate(widget_root, "MyDialog", "ui/my_dialog.mui")
--   Scaffold.save(widget_root, "MyDialog", "ui/my_dialog.mui", "out.lua")
--------------------------------------------------

--------------------------------------------------
-- 辅助：收集树中所有带 _mui_id 的 widget（深度优先）
--------------------------------------------------
local function collectIds(widget)
	local ids = {}
	if not widget then return ids end

	local function walk(w)
		if w._mui_id and w._mui_id ~= "" then
			ids[#ids + 1] = w._mui_id
		end
		for _, child in ipairs(w.children) do
			walk(child)
		end
	end
	walk(widget)
	return ids
end

--------------------------------------------------
-- 辅助：snake_case → PascalCase
--------------------------------------------------
local function snakeToPascal(s)
	local result = s:gsub("_(%w)", function(c) return c:upper() end)
	result = result:gsub("^%l", string.upper)
	return result
end

--------------------------------------------------
-- 辅助：类名 → .mui 路径猜测
--------------------------------------------------
local function classToMuiPath(className)
	local snake = className:gsub("(%u)", function(c) return "_" .. c:lower() end)
	snake = snake:gsub("^_", "")
	return "ui/" .. snake .. ".mui"
end

--------------------------------------------------
-- 生成 .lua 脚本骨架
--------------------------------------------------
local Scaffold = {}

--- 从 widget 树生成 .lua 行为脚本代码
---@param root widget 根 widget（用于提取 _mui_id 列表）
---@param className string PascalCase 类名
---@param muiPath string .mui 文件相对路径（可选，自动从类名推导）
---@param options? table {author?, description?}
---@return string Lua 代码
function Scaffold.generate(root, className, muiPath, options)
	options = options or {}
	muiPath = muiPath or classToMuiPath(className)

	local ids = collectIds(root)

	-- 去掉 root 自身的 id（它通过 Runtime:build 自动处理）
	local child_ids = {}
	for _, id in ipairs(ids) do
		if id ~= (root._mui_id or "") then
			child_ids[#child_ids + 1] = id
		end
	end

	local lines = {}

	-- 头部注释
	if options.description then
		lines[#lines + 1] = "-- " .. className .. " — " .. options.description
	else
		lines[#lines + 1] = "-- " .. className
	end
	if options.author then
		lines[#lines + 1] = "-- @author " .. options.author
	end
	lines[#lines + 1] = "-- @mui  " .. muiPath
	lines[#lines + 1] = ""

	-- require 块
	lines[#lines + 1] = "local Widget = require \"ui.widgets.widget\""
	lines[#lines + 1] = "local Runtime = require(\"ui_editor.runtime.muse_editor_runtime\"):getInstance()"
	lines[#lines + 1] = ""

	-- 类定义头部
	lines[#lines + 1] = "local " .. className .. " = Class(Widget, function(self, datas)"
	lines[#lines + 1] = "\tWidget.new(self, \"" .. className .. "\", datas)"
	lines[#lines + 1] = ""

	-- Runtime:build
	lines[#lines + 1] = "\t-- 加载 .mui 布局，构建子 widget 树"
	lines[#lines + 1] = "\tRuntime:build(self, \"" .. muiPath .. "\")"
	lines[#lines + 1] = ""

	-- Runtime:find 绑定
	if #child_ids > 0 then
		lines[#lines + 1] = "\t-- 按 id 绑定子 widget"
		for _, id in ipairs(child_ids) do
			local var_name = id
			lines[#lines + 1] = "\tself." .. var_name .. " = Runtime:find(self, \"" .. id .. "\")"
		end
		lines[#lines + 1] = ""
	else
		lines[#lines + 1] = "\t-- （此 UI 没有命名子控件）"
		lines[#lines + 1] = ""
	end

	-- onReady 钩子
	lines[#lines + 1] = "\tself:onReady()"
	lines[#lines + 1] = "end)"
	lines[#lines + 1] = ""

	-- onReady 方法
	lines[#lines + 1] = "function " .. className .. ":onReady()"
	lines[#lines + 1] = "\t-- TODO: 初始化逻辑、事件绑定"
	if #child_ids > 0 then
		lines[#lines + 1] = "\t-- 示例："
		lines[#lines + 1] = "\t-- self." .. child_ids[1] .. ".onClick = function()"
		lines[#lines + 1] = "\t-- \tprint(\"" .. child_ids[1] .. " clicked!\")"
		lines[#lines + 1] = "\t-- end"
	end
	lines[#lines + 1] = "end"
	lines[#lines + 1] = ""

	-- 返回
	lines[#lines + 1] = "return " .. className

	return table.concat(lines, "\n")
end

--- 生成并写入文件
---@param root widget
---@param className string PascalCase 类名
---@param muiPath string .mui 文件路径
---@param luaPath string 输出 .lua 路径
---@param options? table
---@return boolean
function Scaffold.save(root, className, muiPath, luaPath, options)
	local code = Scaffold.generate(root, className, muiPath, options)

	local file, err = io.open(luaPath, "w")
	if not file then
		print("lua_scaffold: write failed: " .. tostring(err))
		return false
	end
	file:write(code)
	file:close()
	return true
end

return Scaffold
