--------------------------------------------------
-- TabContainer — 标签页容器
--
-- 顶部/底部 TabBar + 内容区域。继承 Container，
-- 添加的子控件自动成为标签页（类似 Godot TabContainer）。
--
-- 每个子控件作为一页内容，tab 标题取自子控件 name。
-- 可通过 setTabTitle(idx, title) 覆盖标题。
--------------------------------------------------

local Container = require "ui.widgets.containers.container"
local BoxContainer = require "ui.widgets.containers.box_container"
local Button = require "ui.widgets.button"
local PanelContainer = require "ui.widgets.containers.panel_container"
local Utils = require "ui.utils"
local Class = require "dependencies.classic"

local TAB_POSITION = {
	TOP = "top",
	BOTTOM = "bottom",
}

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
	self._tabs_visible = datas and (datas.tabs_visible ~= false) or true
	self._selected_index = -1
	self._use_hidden_for_min = datas and datas.use_hidden_for_min_size or false

	local tab_bar_h = datas and datas.tab_bar_height or self.theme.tabview.tab_height
	self._tab_bar_height = tab_bar_h

	-- 内部 TabBar（HBox）
	self._tab_bar = BoxContainer({
		name = "_tab_bar",
		orientation = "horizontal",
		separation = 0,
	})

	-- 内部内容区域面板
	self._content_panel = PanelContainer({
		name = "_content_panel",
		bg_color = datas and datas.content_bg or self.theme.tabview.content_bg,
		rounding_radius = datas and datas.content_rounding_radius or self.theme.tabview.content_rounding_radius,
	})

	-- 通过基类 Widget.addChild 绕过 Container 的 addChild 重写（内部控件不触发重排）
	local _widgetAddChild = require("ui.widgets.widget").addChild
	_widgetAddChild(self, self._tab_bar)
	_widgetAddChild(self, self._content_panel)

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
	-- 找到第 idx 个非内部子控件
	local count = 0
	for _, child in ipairs(self.children) do
		if child ~= self._tab_bar and child ~= self._content_panel then
			count = count + 1
			if count == idx then return child end
		end
	end
	return nil
end

function TabContainer:setTabTitle(idx, title)
	if idx < 1 or idx > #self._tab_buttons then return end
	self._tab_buttons[idx]:setText(title)
end

function TabContainer:getTabTitle(idx)
	if idx < 1 or idx > #self._tab_buttons then return nil end
	return self._tab_buttons[idx]:getText()
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

	-- 更新按钮状态
	if self._selected_index >= 1 and self._tab_buttons[self._selected_index] then
		self._tab_buttons[self._selected_index]:setSelected(false)
	end
	self._selected_index = idx
	self._tab_buttons[idx]:setSelected(true)

	-- 切换内容
	self:_refreshContent()
end

function TabContainer:_refreshContent()
	self._content_panel:removeAllChildren()
	local ctrl = self:getTabControl(self._selected_index)
	if ctrl then
		self._content_panel:addChild(ctrl)
	end
end

function TabContainer:_rebuildTabBar()
	self._tab_bar:removeAllChildren()
	self._tab_buttons = {}

	local count = 0
	for _, child in ipairs(self.children) do
		if child ~= self._tab_bar and child ~= self._content_panel then
			count = count + 1
		end
	end
	if count == 0 then return end

	local idx = 0
	for _, child in ipairs(self.children) do
		if child ~= self._tab_bar and child ~= self._content_panel then
			idx = idx + 1
			local title = child.name or ("Tab " .. idx)
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
				on_click = function() self:_selectTab(idx) end,
			})
			btn._tab_index = idx
			self._tab_buttons[idx] = btn
			self._tab_bar:addChild(btn)
		end
	end

	-- 设置初始选中
	if self._pending_selected then
		self:_selectTab(self._pending_selected)
		self._pending_selected = nil
	elseif self._selected_index < 1 and #self._tab_buttons > 0 then
		self:_selectTab(1)
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

	-- TabBar 位置
	if self._tabs_position == TAB_POSITION.BOTTOM then
		self:fitChildInRect(self._tab_bar, 0, ch - bar_h, cw, bar_h)
		self:fitChildInRect(self._content_panel, 0, 0, cw, ch - bar_h)
	else
		self:fitChildInRect(self._tab_bar, 0, 0, cw, bar_h)
		self:fitChildInRect(self._content_panel, 0, bar_h, cw, ch - bar_h)
	end
end

function TabContainer:getMinimumSize()
	local bar_w, bar_h = 0, self._tab_bar_height
	if self._tabs_visible then
		bar_w, _ = self._tab_bar:getCombinedMinimumSize()
	end

	local max_cw, max_ch = 0, 0
	for _, child in ipairs(self.children) do
		if child ~= self._tab_bar and child ~= self._content_panel then
			if not child:isShown() and not self._use_hidden_for_min then
				goto continue
			end
			local cmw, cmh = child:getCombinedMinimumSize()
			max_cw = math.max(max_cw, cmw)
			max_ch = math.max(max_ch, cmh)
		end
		::continue::
	end

	return math.max(bar_w, max_cw), bar_h + max_ch
end

function TabContainer:getDesiredSize()
	local bar_w, bar_h = 0, self._tab_bar_height
	if self._tabs_visible then
		local bw, _ = self._tab_bar:getDesiredSize()
		bar_w = bw
	end

	local max_cw, max_ch = 0, 0
	for _, child in ipairs(self.children) do
		if child ~= self._tab_bar and child ~= self._content_panel then
			if not child:isShown() and not self._use_hidden_for_min then
				goto continue
			end
			local cdw, cdh = child:getDesiredSize()
			max_cw = math.max(max_cw, cdw)
			max_ch = math.max(max_ch, cdh)
		end
		::continue::
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
