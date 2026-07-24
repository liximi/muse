--------------------------------------------------
-- ListContainer — 线性排列子控件 + key-based diff 复用
-- 继承 BoxContainer，融入 Godot Container 体系。
--
-- 与 BoxContainer 的区别：
--   - 默认 auto_size=true, separation=8
--   - updateItems(data, keyFn, createFn, updateFn) diff 复用
--   - insert / remove / removeAtPos / setItems 便捷方法
--
-- 用法示例：
--   list:updateItems(data,
--       function(d) return d.id end,
--       function(d) return Button({ text = d.label }) end,
--       function(w, d) w:setText(d.label) end
--   )
--------------------------------------------------

local BoxContainer = require "ui.widgets.containers.box_container"
local Widget = require "ui.widgets.widget"
local Class = require "dependencies.classic"


--[[datas: 此处不包括基类所支持的字段
	items      = {Widget, ...}  初始子控件列表
	separation = number         子控件间距，默认 8
	auto_size  = boolean        自动根据子控件调整主轴尺寸，默认 true
	（其余字段同 BoxContainer：orientation, alignment 等）
]]
local ListContainer = Class(BoxContainer, function(self, datas, theme)
	datas = datas or {}

	-- ListContainer 默认值（区别于 BoxContainer 的 separation=0, auto_size=false）
	if datas.separation == nil then
		datas.separation = 8
	end
	if datas.auto_size == nil then
		datas.auto_size = true
	end

	BoxContainer.new(self, datas, theme)

	if datas.items then
		self:setItems(datas.items)
	end
end)

--------------------------------------------------
-- 内容管理
--------------------------------------------------

--- 全量替换子控件。适用于静态内容初始化。
function ListContainer:setItems(items)
	self:removeAllChildren()
	for _, item in ipairs(items) do
		self:addChild(item)
	end
end

--- 基于 key 的 diff 更新列表。
--- 复用已有控件（保留状态）、创建新控件、移除多余的旧控件。
---@param newData  table     新的数据列表
---@param keyFn    function  提取唯一键 function(data) -> key；nil 则以 data 自身为键
---@param createFn function  创建新控件 function(data) -> Widget
---@param updateFn function  更新已有控件 function(widget, data)；nil 则不更新
function ListContainer:updateItems(newData, keyFn, createFn, updateFn)
	assert(type(createFn) == "function", "updateItems: createFn is required")
	newData = newData or {}

	-- key → data 映射 + 顺序
	local data_by_key = {}
	local key_order = {}
	for _, data_item in ipairs(newData) do
		local key = keyFn and keyFn(data_item) or data_item
		if not data_by_key[key] then
			table.insert(key_order, key)
		end
		data_by_key[key] = data_item
	end

	-- 已有控件 key → widget 映射
	local existing_by_key = {}
	for _, widget in ipairs(self.children) do
		local key = widget._list_key
		if key and data_by_key[key] then
			existing_by_key[key] = widget
		end
	end

	-- 按新顺序构建控件列表
	local new_items = {}
	local reused = {}
	for _, key in ipairs(key_order) do
		local data = data_by_key[key]
		local widget = existing_by_key[key]

		if widget then
			existing_by_key[key] = nil
			reused[widget] = true
			if updateFn then
				updateFn(widget, data)
			end
		else
			widget = createFn(data)
		end
		widget._list_key = key
		table.insert(new_items, widget)
	end

	-- 移除不再需要的旧控件
	for _, widget in ipairs(self.children) do
		if not reused[widget] then
			self:removeChild(widget)
		end
	end

	-- 添加新创建的控件（Widget.addChild 处理 parent，不触发多次 queueSort）
	for _, widget in ipairs(new_items) do
		if not reused[widget] then
			Widget.addChild(self, widget)
		end
	end

	-- 就地重建 children 顺序以匹配 new_items
	for i = #self.children, 1, -1 do
		self.children[i] = nil
	end
	for _, widget in ipairs(new_items) do
		table.insert(self.children, widget)
	end

	self:queueSort()
end

--- 在指定位置插入控件。pos 为 nil 时追加到末尾。
function ListContainer:insert(item, pos)
	self:addChild(item)
	if pos then
		-- addChild 追加到末尾，移到目标位置
		for i = #self.children, 1, -1 do
			if self.children[i] == item then
				if i ~= pos then
					table.remove(self.children, i)
					table.insert(self.children, pos, item)
				end
				break
			end
		end
		self:queueSort()
	end
end

--- 移除指定控件。
function ListContainer:remove(item)
	self:removeChild(item)
end

--- 移除指定位置的控件并返回。
function ListContainer:removeAtPos(pos)
	local item = self.children[pos]
	if item then
		self:removeChild(item)
	end
	return item
end

return ListContainer
