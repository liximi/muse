--------------------------------------------------
-- TabContainer — 标签页容器
--
-- 顶部/底部 TabBar + 内容区域。继承 Container。
-- 添加的子控件自动成为标签页，始终保持在 TabContainer 内，
-- 仅通过可见性切换（对标 Godot TabContainer）。
--------------------------------------------------

local Container = require "ui.widgets.containers.container"
local BoxContainer = require "ui.widgets.containers.box_container"
local Button = require "ui.widgets.button"
local Utils = require "ui.utils"
local Class = require "dependencies.classic"

local TAB_POSITION = { TOP = "top", BOTTOM = "bottom" }

--[[datas:
	tabs_position          = "top" | "bottom"  默认 "top"
	tabs_visible           = bool  默认 true
	tab_bar_height         = number  默认 36
	selected_index         = number  初始选中索引
	use_hidden_for_min_size = bool  默认 false
]]
local TabContainer = Class(Container, function(self, datas, theme)
	Container.new(self, "TabContainer", datas, theme)
	self.raycast_target = true

	self._tabs_position = datas and datas.tabs_position or TAB_POSITION.TOP
	self._tabs_visible = (datas and datas.tabs_visible ~= false) or true
	self._selected_index = -1
	self._use_hidden_for_min = datas and datas.use_hidden_for_min_size or false
	self._tab_bar_height = datas and datas.tab_bar_height or self.theme.tabview.tab_height

	-- 内部 TabBar（HBox）
	self._tab_bar = BoxContainer({ name = "_tab_bar", orientation = "horizontal", separation = 0 })

	-- 内部装饰面板（仅绘制背景，不包含子控件）
	local Panel = require("ui.widgets.panel")
	self._bg_panel = Panel({
		bg_color = datas and datas.content_bg or self.theme.tabview.content_bg,
		rounding_radius = datas and datas.content_rounding_radius or self.theme.tabview.content_rounding_radius,
	})

	-- 通过 Widget.addChild 绕过 Container.addChild 重写
	local wac = require("ui.widgets.widget").addChild
	wac(self, self._bg_panel)
	wac(self, self._tab_bar)

	self._tab_buttons = {}

	if datas and datas.selected_index then
		self._pending_selected = datas.selected_index
	end
end)

function TabContainer:getTabCount()
	return #self._tab_buttons
end

function TabContainer:getCurrentTab()
	return self._selected_index
end

function TabContainer:setCurrentTab(idx)
	if idx == self._selected_index then return end
	if idx >= 1 and idx <= #self._tab_buttons then
		self:_selectTab(idx)
	end
end

function TabContainer:getTabControl(idx)
	if idx < 1 or idx > #self._tab_buttons then return nil end
	local count = 0
	for _, child in ipairs(self.children) do
		if child ~= self._tab_bar and child ~= self._bg_panel then
			count = count + 1
			if count == idx then return child end
		end
	end
	return nil
end

function TabContainer:setTabTitle(idx, title)
	if self._tab_buttons[idx] then
		self._tab_buttons[idx]:setText(title)
	end
end

function TabContainer:getTabTitle(idx)
	if self._tab_buttons[idx] then
		return self._tab_buttons[idx]:getText()
	end
	return nil
end

function TabContainer:setTabsPosition(pos)
	if self._tabs_position == pos then return end
	self._tabs_position = pos
	self:queueSort()
end

function TabContainer:getTabsPosition()
	return self._tabs_position
end

function TabContainer:setTabsVisible(visible)
	if self._tabs_visible == visible then return end
	self._tabs_visible = visible
	if visible then self._tab_bar:show() else self._tab_bar:hide() end
	self:queueSort()
end

function TabContainer:areTabsVisible()
	return self._tabs_visible
end

function TabContainer:_selectTab(idx)
	if idx == self._selected_index then return end
	if idx < 1 or idx > #self._tab_buttons then return end

	if self._tab_buttons[self._selected_index] then
		self._tab_buttons[self._selected_index]:setSelected(false)
	end
	self._selected_index = idx
	self._tab_buttons[idx]:setSelected(true)

	-- 显示当前子控件，隐藏其余
	for _, child in ipairs(self.children) do
		if child ~= self._tab_bar and child ~= self._bg_panel then
			local child_idx = self:getTabIdxFromControl(child)
			if child_idx == idx then child:show() else child:hide() end
		end
	end

	self:queueSort()
end

function TabContainer:getTabIdxFromControl(control)
	local count = 0
	for _, child in ipairs(self.children) do
		if child ~= self._tab_bar and child ~= self._bg_panel then
			count = count + 1
			if child == control then return count end
		end
	end
	return -1
end

function TabContainer:_rebuildTabBar()
	self._tab_bar:removeAllChildren()
	self._tab_buttons = {}

	local idx = 0
	for _, child in ipairs(self.children) do
		if child ~= self._tab_bar and child ~= self._bg_panel then
			idx = idx + 1
			child:hide()
			local title = child.name or ("Tab " .. idx)
			local tab_idx = idx  -- 闭包安全：捕获当前值
			local btn = Button({
				text = title,
				h_size_flags = Utils.SIZE_FLAGS.EXPAND + Utils.SIZE_FLAGS.FILL,
				normal = Utils.newButtonStateStyle(title,
					self.theme.tabview.tab_text_normal,
					self.theme.tabview.tab_font_size,
					self.theme.tabview.tab_bg_normal,
					1,
					self.theme.tabview.tab_outline_color or Utils.UI_COLORS.LINE),
				selected = Utils.newButtonStateStyle(nil,
					self.theme.tabview.tab_text_selected,
					nil,
					self.theme.tabview.tab_bg_selected),
				on_click = function() self:_selectTab(tab_idx) end,
			})
			btn._tab_index = tab_idx
			self._tab_buttons[tab_idx] = btn
			self._tab_bar:addChild(btn)
		end
	end

	if self._pending_selected then
		self:_selectTab(self._pending_selected)
		self._pending_selected = nil
	elseif #self._tab_buttons > 0 then
		-- 重建按钮后需要恢复选中状态（_selectTab 会跳过相同索引，先重置再选）
		local prev = self._selected_index
		self._selected_index = -1
		if prev >= 1 and prev <= #self._tab_buttons then
			self:_selectTab(prev)
		else
			self:_selectTab(1)
		end
	else
		self:queueSort()
	end
end

function TabContainer:addChild(child)
	Container.addChild(self, child)
	self:_rebuildTabBar()
	return child
end

function TabContainer:removeChild(child)
	Container.removeChild(self, child)
	self:_rebuildTabBar()
	return child
end

function TabContainer:_sortChildren()
	local cw, ch = self.transform:getSize()
	local bar_h = self._tab_bar_height
	if not self._tabs_visible then bar_h = 0 end

	local content_y, content_h
	if self._tabs_position == TAB_POSITION.BOTTOM then
		self:fitChildInRect(self._tab_bar, 0, ch - bar_h, cw, bar_h)
		content_y, content_h = 0, ch - bar_h
	else
		self:fitChildInRect(self._tab_bar, 0, 0, cw, bar_h)
		content_y, content_h = bar_h, ch - bar_h
	end

	-- 背景面板填满内容区
	self:fitChildInRect(self._bg_panel, 0, content_y, cw, content_h)

	-- 选中子控件填满内容区
	local ctrl = self:getTabControl(self._selected_index)
	if ctrl then
		self:fitChildInRect(ctrl, 0, content_y, cw, content_h)
	end
end

function TabContainer:getMinimumSize()
	local bar_w, bar_h = 0, self._tab_bar_height
	if self._tabs_visible then
		bar_w = self._tab_bar:getCombinedMinimumSize()
	end

	local max_cw, max_ch = 0, 0
	for _, child in ipairs(self.children) do
		if child ~= self._tab_bar and child ~= self._bg_panel then
			if child:isShown() or self._use_hidden_for_min then
				local cmw, cmh = child:getCombinedMinimumSize()
				max_cw = math.max(max_cw, cmw)
				max_ch = math.max(max_ch, cmh)
			end
		end
	end

	return math.max(bar_w, max_cw), bar_h + max_ch
end

function TabContainer:getDesiredSize()
	local bar_w, bar_h = 0, self._tab_bar_height
	if self._tabs_visible then
		bar_w = self._tab_bar:getDesiredSize()
	end

	local max_cw, max_ch = 0, 0
	for _, child in ipairs(self.children) do
		if child ~= self._tab_bar and child ~= self._bg_panel then
			if child:isShown() or self._use_hidden_for_min then
				local cdw, cdh = child:getDesiredSize()
				max_cw = math.max(max_cw, cdw)
				max_ch = math.max(max_ch, cdh)
			end
		end
	end

	return math.max(bar_w, max_cw), bar_h + max_ch
end

function TabContainer:getInnerCombinedMaximumSize()
	local cw, ch = Container.getInnerCombinedMaximumSize(self)
	if self._tabs_visible then
		ch = math.max(0, ch - self._tab_bar_height)
	end
	return cw, ch
end

return TabContainer
