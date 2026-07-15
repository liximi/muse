local Widget = require "ui.widgets.widget"
local RadioButton = require "ui.widgets.radiobutton"
local Class = require "dependencies.classic"

-- 单选按钮组，管理一组 RadioButton 的互斥行为
--[[datas: 此处不包括基类所支持的字段
	items = {{label = string, ...}, ...}  -- 各选项的 datas 表，会被传给 RadioButton 构造
	selected_index = number  -- 初始选中项索引
	on_selection_changed = function(index)
]]
local RadioGroup = Class(Widget, function(self, datas, theme)
	Widget.new(self, "RadioGroup", datas, theme)

	self.buttons = {}
	self._selected_index = nil
	self.onSelectionChanged = datas and datas.on_selection_changed

	if datas and datas.items then
		self:setItems(datas.items, datas.selected_index)
	end
end)

--- 报告最小尺寸（容器布局需要）
function RadioGroup:getMinimumSize()
	local w, h = self.transform:getSize()
	return w, h
end

--- 设置选项列表
---@param items table 各选项的 datas 表数组
---@param selected_index number|nil 初始选中索引
function RadioGroup:setItems(items, selected_index)
	self:removeAllChildren()
	self.buttons = {}

	local item_h = 28
	local spacing = 4

	for i, item in ipairs(items) do
		local btn_datas = {}
		for k, v in pairs(item) do
			btn_datas[k] = v
		end
		-- 注入 on_checked 回调实现互斥
		btn_datas.on_checked = function(checked)
			if checked then
				self:_onButtonChecked(i)
			end
		end
		-- 自动布局：垂直排列
		btn_datas.anchor = btn_datas.anchor or {0, 0, 1, 0}
		btn_datas.padding = btn_datas.padding or {0, 0, (i - 1) * (item_h + spacing), 0}
		btn_datas.h = btn_datas.h or item_h

		local btn = self:addChild(RadioButton(btn_datas))
		self.buttons[i] = btn
	end

	if selected_index and self.buttons[selected_index] then
		self.buttons[selected_index]:setChecked(true)
		self._selected_index = selected_index
	end
end

-- 内部：当某个按钮被选中时，取消其他按钮的选中
-- 用 _handling 守卫防止取消操作触发 onChecked 回调导致的级联反选
function RadioGroup:_onButtonChecked(index)
	if self._handling then
		return
	end
	self._handling = true
	self._selected_index = index
	for i, btn in ipairs(self.buttons) do
		if i ~= index then
			btn:setChecked(false)
		end
	end
	self._handling = false
	if self.onSelectionChanged then
		self:onSelectionChanged(index)
	end
end

--- 获取当前选中项的索引
---@return number|nil
function RadioGroup:getSelected()
	return self._selected_index
end

--- 编程式设置选中项
---@param index number
function RadioGroup:setSelected(index)
	if self.buttons[index] and index ~= self._selected_index then
		self:_onButtonChecked(index)
		self.buttons[index]:setChecked(true)
	end
end

return RadioGroup
