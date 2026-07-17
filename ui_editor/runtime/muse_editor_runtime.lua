--------------------------------------------------
-- MuseEditorRuntime — 单例，解析 .mui → 构建 widget 树 → id 查找
--
-- 用法：
--   local Runtime = require("ui_editor.runtime.muse_editor_runtime"):getInstance()
--   Runtime:build(self, "ui/my_dialog.mui")
--   self.title = Runtime:find(self, "title")
--
-- 开发者不直接调用 Widget 构造器来创建 .mui 中的节点；
-- 而是通过 Runtime:build(parent, path) 一键构建整棵树。
--------------------------------------------------

local Json = require "ui_editor.runtime.json"

--------------------------------------------------
-- 类型注册表：.mui type 串 → Widget 构造器
--------------------------------------------------
local TYPE_REGISTRY = {
	Panel           = "ui.widgets.panel",
	Text            = "ui.widgets.text",
	Button          = "ui.widgets.button",
	Image           = "ui.widgets.image",
	Checkbox        = "ui.widgets.checkbox",
	RadioButton     = "ui.widgets.radiobutton",
	TextInput       = "ui.widgets.textinput",
	ProgressBar     = "ui.widgets.progressbar",
	SliderBar       = "ui.widgets.sliderbar",
	Dropdown        = "ui.widgets.dropdown",
	Modal           = "ui.widgets.modal",
	TabView         = "ui.widgets.tabview",
	NineSlice       = "ui.widgets.nineslice",
	Spacer          = "ui.widgets.spacer",
	BoxContainer    = "ui.widgets.containers.box_container",
	MarginContainer = "ui.widgets.containers.margin_container",
	CenterContainer = "ui.widgets.containers.center_container",
	Scroll          = "ui.widgets.containers.scroll_container",
}

-- HBox / VBox 别名 → BoxContainer + 隐式 orientation
local TYPE_ALIASES = {
	HBoxContainer = { module = "ui.widgets.containers.box_container", implicit = { orientation = "horizontal" } },
	VBoxContainer = { module = "ui.widgets.containers.box_container", implicit = { orientation = "vertical"  } },
}

--------------------------------------------------
-- 缓存：已 require 的 Widget 构造器（懒加载）
--------------------------------------------------
local _ctorCache = {}

local function getCtor(muiType)
	if _ctorCache[muiType] then
		return _ctorCache[muiType]
	end

	-- 先查别名
	local alias = TYPE_ALIASES[muiType]
	if alias then
		_ctorCache[muiType] = {
			ctor = require(alias.module),
			implicit = alias.implicit,
		}
		return _ctorCache[muiType]
	end

	-- 查主注册表
	local modPath = TYPE_REGISTRY[muiType]
	if modPath then
		_ctorCache[muiType] = {
			ctor = require(modPath),
		}
		return _ctorCache[muiType]
	end

	print("MuseEditorRuntime: unknown type '" .. tostring(muiType) .. "'")
	return nil
end

--------------------------------------------------
-- Runtime 单例
--------------------------------------------------
local MuseEditorRuntime = Class(function(self)
	self._cache = {}        -- path → widget tree (Lua table, 已解析的 .mui)
	self._id_index = {}     -- id → widget 快速查找（构建时填充）
end)

local _instance

--- 获取单例
function MuseEditorRuntime.getInstance()
	if not _instance then
		_instance = MuseEditorRuntime()
	end
	return _instance
end

--------------------------------------------------
-- .mui 加载与缓存
--------------------------------------------------

--- 加载并解析 .mui 文件 → Lua table（带缓存）
---@param path string .mui 文件路径
---@return table|nil { version, root: { type, id?, props?, children? } }
function MuseEditorRuntime:loadMui(path)
	if self._cache[path] then
		return self._cache[path]
	end

	local tree = Json.load(path)
	if not tree then
		print("MuseEditorRuntime: failed to load " .. path)
		return nil
	end

	if type(tree.version) ~= "number" then
		print("MuseEditorRuntime: " .. path .. " missing version field")
		return nil
	end

	self._cache[path] = tree
	return tree
end

--- 清除 .mui 缓存（开发期热重载用）
function MuseEditorRuntime:clearCache(path)
	if path then
		self._cache[path] = nil
	else
		self._cache = {}
	end
end

--------------------------------------------------
-- 构建 widget 树
--------------------------------------------------

-- 合并 props：显式 props 优先，隐式 props 兜底
local function mergeProps(props, implicit)
	if not implicit then return props or {} end
	local merged = {}
	if implicit then
		for k, v in pairs(implicit) do
			merged[k] = v
		end
	end
	if props then
		for k, v in pairs(props) do
			merged[k] = v
		end
	end
	return merged
end

-- 递归构建单个节点
local function buildNode(nodeDef, entry)
	if not nodeDef or not nodeDef.type then return nil end

	local info = getCtor(nodeDef.type)
	if not info then return nil end

	local datas = mergeProps(nodeDef.props, info.implicit)

	local widget = info.ctor(datas)
	if not widget then return nil end

	-- 标记 mui id
	if nodeDef.id and nodeDef.id ~= "" then
		widget._mui_id = nodeDef.id
		-- 注册到父 Runtime 的 id 索引
		if entry._rt then
			entry._rt._id_index[nodeDef.id] = widget
		end
	end

	-- 标记来源路径
	widget._mui_source = entry._path

	-- 递归构建子节点
	if nodeDef.children then
		for _, childDef in ipairs(nodeDef.children) do
			local child = buildNode(childDef, entry)
			if child then
				widget:addChild(child)
			end
		end
	end

	return widget
end

--- 构建并返回 .mui 的根 Widget（不依附父容器）
--- 供编辑器等需要拿到根节点引用的场景使用
---@param path string .mui 文件路径
---@return Widget|nil
function MuseEditorRuntime:buildRoot(path)
	local tree = self:loadMui(path)
	if not tree or not tree.root then return nil end

	local entry = {
		_path = path,
		_rt = self,
	}

	return buildNode(tree.root, entry)
end

--- 在 parent 下递归构建整棵 .mui 树
---@param parent Widget 父容器（通常是 self，即开发者自定义的 Widget 子类实例）
---@param path string .mui 文件路径
function MuseEditorRuntime:build(parent, path)
	local tree = self:loadMui(path)
	if not tree or not tree.root then return end

	local entry = {
		_path = path,
		_rt = self,
	}

	local rootWidget = buildNode(tree.root, entry)
	if rootWidget then
		parent:addChild(rootWidget)
	else
		print("MuseEditorRuntime: build failed " .. path)
	end
end

--------------------------------------------------
-- id 查找
--------------------------------------------------

--- 深度优先搜索，按 _mui_id 返回 widget 引用
--- 搜索范围限定在 root 子树内（保证作用域隔离）。
---@param root Widget 搜索起点
---@param id string 目标 _mui_id
---@return Widget|nil
function MuseEditorRuntime:find(root, id)
	if not root or not id then return nil end

	-- 深度优先搜索（限定在 root 子树）
	local function dfs(w)
		if w._mui_id == id then return w end
		for _, child in ipairs(w.children) do
			local found = dfs(child)
			if found then return found end
		end
		return nil
	end

	return dfs(root)
end

--- 按 id 查找并返回 widget，附带类型检查
---@param root Widget
---@param id string
---@param expectedType string 可选，期望的 Widget 类型名
---@return Widget|nil
function MuseEditorRuntime:findOf(root, id, expectedType)
	local w = self:find(root, id)
	if not w then return nil end
	if expectedType and w._name ~= expectedType then
		print(string.format("MuseEditorRuntime: id '%s' type is '%s', expected '%s'",
			id, tostring(w._name), expectedType))
	end
	return w
end

return MuseEditorRuntime
