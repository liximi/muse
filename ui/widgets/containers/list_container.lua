local Widget = require "ui.widgets.widget"
local Utils = require "ui.utils"
local Class = require "dependencies.classic"

local AXIS = {
	vertical = {
		pos = "y",
		size = "h",
		alter = "x"
	},
	horizontal = {
		pos = "x",
		size = "w",
		alter = "y"
	}
}

--[[datas: 此处不包括当前Widget继承的基类所支持的字段
	orientation = "vertical" | "horizontal"
	items = {Widget, ...}
	space = number 元素之间的间隔

	方法：
	  setItems(items)               -- 全量替换（不保留旧控件状态）
	  updateItems(data,key,create,update) -- diff 复用（推荐，保留旧控件状态）
	  insert(item, pos)
	  remove(item) / removeAtPos(pos)
]]
local List = Class(Widget, function(self, datas, theme)
	datas = datas or {}
	local orientation = Utils.validateEnum(
		datas.orientation, Utils.ORIENTATION, Utils.ORIENTATION.VERTICAL, "List.orientation")
	self._axis = AXIS[orientation]

	Widget.new(self, orientation == "vertical" and "ListVContainer" or "ListHContainer", datas, theme)

	self.items = {}
	self.space = datas.space or 8
	self._layout_dirty = true
	self._in_layout = false

	if datas.items then
		self:setItems(datas.items)
	end
end)

function List:setItems(items)
	self:removeAllChildren()
	self.items = {}
	for i, v in ipairs(items) do
		table.insert(self.items, v)
		self:addChild(v)
	end
	self:layout()
end

--- 更新列表内容，自动 diff 新旧数据、复用已有控件、原地更新属性
--- 与 setItems 不同，此方法不会销毁未被移除的控件，避免按钮状态、输入焦点等丢失
---@param newData table 新的数据列表
---@param keyFn function|nil 从数据项提取唯一键的函数 function(data) -> key
---                         为 nil 时以数据项自身作为键（引用相等）
---@param createFn function 从数据项创建新控件的函数 function(data) -> Widget
---@param updateFn function|nil 用新数据更新已有控件的函数 function(widget, data)
---                               为 nil 时不更新（仅复用控件对象）
---
--- 用法示例：
---   list:updateItems(buttons_data,
---       function(d) return d.id end,
---       function(d) return Button({ text = d.label }) end,
---       function(w, d) w:setText(d.label) end
---   )
function List:updateItems(newData, keyFn, createFn, updateFn)
	assert(type(createFn) == "function", "updateItems: createFn is required")

	newData = newData or {}

	-- 构建新数据的 key → data 映射，同时保存 key 的顺序
	local data_by_key = {}
	local key_order = {}
	for i, data_item in ipairs(newData) do
		local key = keyFn and keyFn(data_item) or data_item
		-- 重复 key 只在首次出现时记录顺序，后续出现只更新 data（创建新控件以保持一一对应）
		if not data_by_key[key] then
			table.insert(key_order, key)
		end
		data_by_key[key] = data_item
	end

	-- 构建已有控件的 key → widget 映射
	local existing_by_key = {}
	for _, widget in ipairs(self.items) do
		local key = widget._list_key
		if key and data_by_key[key] then
			existing_by_key[key] = widget
		end
	end

	-- 按新顺序构建控件列表，复用已有控件
	local new_items = {}
	local reused = {}
	for _, key in ipairs(key_order) do
		local data = data_by_key[key]
		local widget = existing_by_key[key]

		if widget then
			-- 复用已有控件：从 existing 中移除防止重复 key 多次复用同一控件
			existing_by_key[key] = nil
			reused[widget] = true
			if updateFn then
				updateFn(widget, data)
			end
		else
			-- 创建新控件
			widget = createFn(data)
		end
		widget._list_key = key
		table.insert(new_items, widget)
	end

	-- 移除不再需要的旧控件
	for _, widget in ipairs(self.items) do
		if not reused[widget] then
			self:removeChild(widget)
		end
	end

	-- 添加新创建的控件（addChild 设置 parent + transform.parent）
	for _, widget in ipairs(new_items) do
		if not reused[widget] then
			self:addChild(widget)
		end
	end

	-- 重建 children 顺序以匹配 items（children 倒序决定事件传播的 z-order）
	self.children = {}
	for _, widget in ipairs(new_items) do
		table.insert(self.children, widget)
	end

	self.items = new_items
	self._layout_dirty = true
	self:layout()
end

function List:insert(item, pos)
	if pos then
		table.insert(self.items, pos, item)
	else
		table.insert(self.items, item)
	end
	self:addChild(item)
	self:layout()
end

function List:remove(item)
	for i, _item in ipairs(self.items) do
		if _item == item then
			table.remove(self.items, i)
			self:removeChild(item)
			self:layout()
			return
		end
	end
end

function List:removeAtPos(pos)
	local item = table.remove(self.items, pos)
	self:removeChild(item)
	self:layout()
	return item
end

function List:layout()
	if self._in_layout then
		return
	end
	self._in_layout = true
	local a = self._axis
	local offset = 0
	for i, v in ipairs(self.items) do
		local x_arg, y_arg
		if a.pos == "x" then
			x_arg, y_arg = offset, 0
		else
			x_arg, y_arg = nil, offset
		end
		v:setPosition(x_arg, y_arg)
		-- 用 measure() 替代 getScaledSize()：子元素根据内容返回自然尺寸
		local m = v:measure(nil, nil)
		local item_size = a.pos == "x" and m.w or m.h
		offset = offset + item_size + self.space
	end
	local list_total = math.max(0, offset - self.space)
	self.transform:setSize(a.pos == "x" and list_total or nil, a.pos == "y" and list_total or nil)
	self._layout_dirty = false
	self._in_layout = false
end

function List:onUpdate(dt)
	-- 收集子元素当前尺寸并检测变化，同时缓存测量结果避免重复 measure()
	local new_sizes = {}
	if not self._layout_dirty then
		for _, v in ipairs(self.items) do
			local m = v:measure(nil, nil)
			new_sizes[v] = {m.w, m.h}
			local last = self._child_sizes and self._child_sizes[v]
			if not last or last[1] ~= m.w or last[2] ~= m.h then
				self._layout_dirty = true
				-- 不 break，继续收集以便 layout() 中复用
			end
		end
	end
	self._child_sizes = new_sizes

	if self._layout_dirty then
		self:layout()
		self._layout_dirty = false
	end
end

return List
