--------------------------------------------------
-- mui_serializer.lua — Widget 树 → .mui JSON 导出
--
-- 递归遍历 widget 树，提取布局属性，输出符合 .mui 规范的 Lua table，
-- 再编码为 JSON 字符串写入文件。
--
-- 用法：
--   local Ser = require "ui_editor.editor.mui_serializer"
--   local tree = Ser.serialize(root_widget)
--   Ser.save(root_widget, "path/to/file.mui")
--------------------------------------------------

local Utils = require "ui.utils"
local Json = require "ui_editor.runtime.json"
local LEAF_TYPES = require "ui_editor.editor.widget_meta"

local SZ = Utils.SIZE_FLAGS

--------------------------------------------------
-- 类型映射：将 _name → .mui type + 隐式 props
--------------------------------------------------
local TYPE_MAP = {
	HBoxContainer = { type = "BoxContainer", implicit = { orientation = "horizontal" } },
	VBoxContainer = { type = "BoxContainer", implicit = { orientation = "vertical"  } },
}

--------------------------------------------------
-- 默认值：当 prop 等于此值时省略（减小 .mui 体积）
--------------------------------------------------
local DEFAULTS = {
	anchor         = { 0, 0, 0, 0 },
	pivot          = { 0, 0 },
	w              = 0,
	h              = 0,
	x              = 0,
	y              = 0,
	padding        = { 0, 0, 0, 0 },
	h_size_flags   = SZ.FILL,
	v_size_flags   = SZ.FILL,
	stretch_ratio  = 1.0,
	separation     = 0,
	alignment      = "begin",
	orientation    = "vertical",
	rounding_radius = 0,
	outline_width  = 0,
	auto_size      = false,
	checked        = false,
	interactive    = false,
	h_align        = "left",
	v_align        = "top",
	margin_left    = 0,
	margin_right   = 0,
	margin_top     = 0,
	margin_bottom  = 0,
	use_top_left   = false,
	value          = 0,
	single_line    = false,
	enable_scroll_h = false,
	enable_scroll_v = true,
}

--------------------------------------------------
-- 辅助：判断两个值是否相等（支持 table 浅比较）
--------------------------------------------------
local function eq(a, b)
	if a == b then return true end
	if type(a) ~= "table" or type(b) ~= "table" then return false end
	for k, v in pairs(a) do
		if b[k] ~= v then return false end
	end
	for k, v in pairs(b) do
		if a[k] ~= v then return false end
	end
	return true
end

--------------------------------------------------
-- 辅助：判断 prop 是否为默认值
--------------------------------------------------
local function isDefault(key, value)
	local d = DEFAULTS[key]
	if d == nil then return false end
	return eq(value, d)
end

--------------------------------------------------
-- 辅助：将 prop 加入 props 表（非默认值时）
--------------------------------------------------
local function setProp(props, key, value)
	if value == nil then return end
	if isDefault(key, value) then return end

	-- 复制数组表，避免外部引用污染
	if type(value) == "table" then
		local copy = {}
		for i = 1, #value do
			copy[i] = value[i]
		end
		props[key] = copy
	else
		props[key] = value
	end
end

--------------------------------------------------
-- 获取 widget 的 .mui 类型名
--------------------------------------------------
local function getMuiType(widget)
	-- 优先使用显式标注
	if widget._mui_type then
		return widget._mui_type
	end

	-- 从 _name 推导（构造函数设置的类名）
	local name = widget._name
	if not name or name == "widget" then
		return nil
	end

	-- 查映射表
	local mapped = TYPE_MAP[name]
	if mapped then
		return mapped.type
	end

	return name
end

--------------------------------------------------
-- 获取隐式 props（如 HBoxContainer → orientation="horizontal"）
--------------------------------------------------
local function getImplicitProps(widget)
	local name = widget._name
	if not name then return nil end
	local mapped = TYPE_MAP[name]
	if mapped then
		return mapped.implicit
	end
	return nil
end

--------------------------------------------------
-- 提取一个 widget 的 props
--------------------------------------------------
local function extractProps(widget)
	local props = {}
	local t = widget.transform

	-- === 布局属性 ===
	setProp(props, "anchor", { t.anchor_min[1], t.anchor_min[2], t.anchor_max[1], t.anchor_max[2] })
	setProp(props, "pivot", { t.pivot[1], t.pivot[2] })
	setProp(props, "w", t.w)
	setProp(props, "h", t.h)

	-- 位置（仅非锚点定位时有效）
	if t.left ~= 0 or t.right ~= 0 or t.top ~= 0 or t.bottom ~= 0 then
		local padding = { t.left, t.right, t.top, t.bottom }
		if not isDefault("padding", padding) then
			props.padding = padding
		end
	end

	-- === 容器标志 ===
	setProp(props, "h_size_flags", widget.h_size_flags)
	setProp(props, "v_size_flags", widget.v_size_flags)
	setProp(props, "stretch_ratio", widget.stretch_ratio)

	-- === 隐式 props（从类型映射） ===
	local implicit = getImplicitProps(widget)
	if implicit then
		for k, v in pairs(implicit) do
			if not isDefault(k, v) then
				props[k] = v
			end
		end
	end

	-- === 类型特定属性 ===
	_extractTextProps(widget, props)
	_extractPanelProps(widget, props)
	_extractContainerProps(widget, props)
	_extractCheckboxProps(widget, props)
	_extractImageProps(widget, props)
	_extractProgressBarProps(widget, props)
	_extractSliderBarProps(widget, props)
	_extractTextInputProps(widget, props)
	_extractScrollProps(widget, props)

	return props
end

--------------------------------------------------
-- 各类型特定属性提取
--------------------------------------------------

function _extractTextProps(widget, props)
	if not widget.font_size then return end
	if widget.getText then setProp(props, "text", widget:getText(true)) end
	setProp(props, "font_size", widget.font_size)
	setProp(props, "font_key", widget.font_key)

	if widget.text_color then
		setProp(props, "text_color", { widget.text_color[1], widget.text_color[2], widget.text_color[3], widget.text_color[4] })
	end
	if widget.horizontal_align then
		setProp(props, "h_align", widget.horizontal_align)
	end
	if widget.vertical_align then
		setProp(props, "v_align", widget.vertical_align)
	end
end

function _extractPanelProps(widget, props)
	if not widget.bg_color then return end
	setProp(props, "bg_color", { widget.bg_color[1], widget.bg_color[2], widget.bg_color[3], widget.bg_color[4] })
	setProp(props, "outline_width", widget.outline_width)
	if widget.outline_color then
		setProp(props, "outline_color", { widget.outline_color[1], widget.outline_color[2], widget.outline_color[3], widget.outline_color[4] })
	end
	setProp(props, "rounding_radius", widget.rounding_radius)
end

function _extractContainerProps(widget, props)
	-- BoxContainer: orientation / separation / alignment
	if widget.separation then
		setProp(props, "separation", widget.separation)
	end
	if widget.alignment then
		setProp(props, "alignment", widget.alignment)
	end
	-- Container base: auto_size
	if widget.auto_size ~= nil then
		setProp(props, "auto_size", widget.auto_size)
	end

	-- MarginContainer margins
	if widget.margin_left ~= nil then
		setProp(props, "margin_left", widget.margin_left)
		setProp(props, "margin_right", widget.margin_right)
		setProp(props, "margin_top", widget.margin_top)
		setProp(props, "margin_bottom", widget.margin_bottom)
	end

	-- CenterContainer
	if widget.use_top_left ~= nil then
		setProp(props, "use_top_left", widget.use_top_left)
	end
end

function _extractCheckboxProps(widget, props)
	if widget.style == nil then return end
	setProp(props, "checked", widget._checked)
	setProp(props, "style", widget.style)
	setProp(props, "box_size", widget.box_size)
end

function _extractImageProps(widget, props)
	if widget.tint == nil then return end
	setProp(props, "tint", { widget.tint[1], widget.tint[2], widget.tint[3], widget.tint[4] })
end

function _extractProgressBarProps(widget, props)
	if widget.value == nil then return end
	setProp(props, "value", widget.value)
	setProp(props, "interactive", widget.interactive)
	if widget.orientation then
		setProp(props, "orientation", widget.orientation)
	end
end

function _extractSliderBarProps(widget, props)
	if widget._value == nil then return end
	setProp(props, "value", widget._value)
	if widget.orientation then
		setProp(props, "orientation", widget.orientation)
	end
end

function _extractTextInputProps(widget, props)
	if not widget.single_line then return end
	setProp(props, "single_line", widget.single_line)
	setProp(props, "text", widget:getText())
	if widget._placeholder then
		setProp(props, "placeholder", widget._placeholder)
	end
end

function _extractScrollProps(widget, props)
	if widget._sensitivity == nil then return end
	setProp(props, "enable_scroll_h", widget.enable_scroll_h)
	-- enable_scroll_v defaults to true, only emit if false
	if widget.enable_scroll_v == false then
		props.enable_scroll_v = false
	end
	if widget._sensitivity then
		setProp(props, "sensitivity", widget._sensitivity)
	end
end

--------------------------------------------------
-- 判断 widget 的子节点是否应递归序列化
--------------------------------------------------
local function shouldRecurseChildren(widget)
	local mui_type = getMuiType(widget)
	if not mui_type then return false end
	-- 叶子类型不序列化子节点
	if LEAF_TYPES[mui_type] then return false end
	-- Scroll 的 item 作为唯一子节点序列化
	-- (暂不处理，Scroll 标记为 LEAF)
	return true
end

--------------------------------------------------
-- 获取应序列化的子节点列表
--------------------------------------------------
local function getSerializableChildren(widget)
	if not shouldRecurseChildren(widget) then
		return {}
	end
	local result = {}
	for _, child in ipairs(widget.children) do
		if child:isShown() then
			table.insert(result, child)
		end
	end
	return result
end

--------------------------------------------------
-- 核心：递归序列化单个 widget 节点
--------------------------------------------------
local function serializeNode(widget)
	local mui_type = getMuiType(widget)
	if not mui_type then
		return nil
	end

	local node = {
		type = mui_type,
	}

	-- id
	if widget._mui_id and widget._mui_id ~= "" then
		node.id = widget._mui_id
	end

	-- props
	local props = extractProps(widget)
	if next(props) ~= nil then
		node.props = props
	end

	-- children
	local children = getSerializableChildren(widget)
	if #children > 0 then
		local child_nodes = {}
		for _, child in ipairs(children) do
			local child_node = serializeNode(child)
			if child_node then
				table.insert(child_nodes, child_node)
			end
		end
		if #child_nodes > 0 then
			node.children = child_nodes
		end
	end

	return node
end

--------------------------------------------------
-- 公共 API
--------------------------------------------------

local Serializer = {}

--- 将 widget 树序列化为符合 .mui 规范的 Lua table
---@param root widget 根 widget
---@return table|nil {version, root={type, id?, props?, children?}}
function Serializer.serialize(root)
	if not root then return nil end

	local root_node = serializeNode(root)
	if not root_node then return nil end

	return {
		version = 1,
		root = root_node,
	}
end

--- 将 .mui table 编码为 JSON 字符串
---@param tree table serialize() 的返回值
---@param pretty boolean 是否美化输出（默认 true）
---@return string
function Serializer.toJSON(tree, pretty)
	if pretty == nil then pretty = true end
	return Json.encode(tree, pretty)
end

--- 序列化并写入 .mui 文件
---@param root widget 根 widget
---@param path string 输出路径
---@param pretty boolean 是否美化输出
---@return boolean 是否成功
function Serializer.save(root, path, pretty)
	local tree = Serializer.serialize(root)
	if not tree then
		return false
	end

	local json_str = Serializer.toJSON(tree, pretty)

	local file, err = io.open(path, "w")
	if not file then
		print("mui_serializer: write failed: " .. tostring(err))
		return false
	end
	file:write(json_str)
	file:close()
	return true
end

return Serializer
