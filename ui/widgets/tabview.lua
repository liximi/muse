local Widget = require "ui.widgets.widget"
local Panel = require "ui.widgets.panel"
local Button = require "ui.widgets.button"
local Utils = require "ui.utils"
local Class = require "dependencies.classic"


-- 标签页视图，顶部 Tab 栏 + 下方内容面板
--[[datas: 此处不包括基类所支持的字段
	tabs = {{label = string, content = Widget}, ...}
	tab_bar_height = number  -- Tab 栏高度，默认 36
	selected_index = number  -- 初始选中索引
	on_tab_changed = function(index)
]]
local TabView = Class(Widget, function(self, datas, theme)
	Widget.new(self, "TabView", datas, theme)

	self.tabs = {}
	self._tab_buttons = {}
	self._selected_index = nil
	self.onTabChanged = datas and datas.on_tab_changed

	local tab_bar_h = datas and datas.tab_bar_height or self.theme.tabview.tab_height

	-- Tab 按钮栏
	self.tab_bar = self:addChild(Widget({
		anchor = {0, 0, 1, 0},
		h = tab_bar_h,
		padding = {0, 0, 0, 0},
	}))

	-- 内容区域
	self.content_area = self:addChild(Panel({
		anchor = {0, 0, 1, 1},
		padding = {0, 0, tab_bar_h, 0},
		bg_color = datas and datas.content_bg or self.theme.tabview.content_bg,
		rounding_radius = datas and datas.content_rounding_radius or self.theme.tabview.content_rounding_radius,
	}))

	if datas and datas.tabs then
		self:setTabs(datas.tabs, datas.selected_index)
	end
end)


--- 设置标签页列表
---@param tab_list table {{label = string, content = Widget}, ...}
---@param selected_index number|nil
function TabView:setTabs(tab_list, selected_index)
	self.tab_bar:removeAllChildren()
	self.content_area:removeAllChildren()
	self.tabs = {}
	self._tab_buttons = {}

	local n = #tab_list
	if n == 0 then return end

	for i, tab in ipairs(tab_list) do
		tab.index = i
		table.insert(self.tabs, tab)

		local btn = Button({
			anchor = {(i - 1) / n, 0, i / n, 1},
			padding = {2, 2, 2, 2},
			normal = Utils.newButtonStateStyle(
				tab.label,
				self.theme.tabview.tab_text_normal,
				self.theme.tabview.tab_font_size,
				self.theme.tabview.tab_bg_normal,
				1,
				self.theme.tabview.tab_outline_color or Utils.UI_COLORS.LINE
			),
			selected = Utils.newButtonStateStyle(
				nil,
				self.theme.tabview.tab_text_selected,
				nil,
				self.theme.tabview.tab_bg_selected
			),
			on_click = function()
				self:selectTab(i)
			end
		})
		self._tab_buttons[i] = self.tab_bar:addChild(btn)
	end

	local init_index = selected_index or 1
	if self._tab_buttons[init_index] then
		self:selectTab(init_index)
	end
end


--- 切换到指定索引的标签页
---@param index number
function TabView:selectTab(index)
	if index == self._selected_index then return end
	if not self.tabs[index] then return end

	-- 更新按钮状态
	if self._selected_index and self._tab_buttons[self._selected_index] then
		self._tab_buttons[self._selected_index]:setSelected(false)
	end
	self._selected_index = index
	self._tab_buttons[index]:setSelected(true)

	-- 切换内容
	self.content_area:removeAllChildren()
	if self.tabs[index].content then
		self.content_area:addChild(self.tabs[index].content)
	end

	if self.onTabChanged then
		self:onTabChanged(index)
	end
end


--- 获取当前选中索引
---@return number|nil
function TabView:getSelected()
	return self._selected_index
end


return TabView
