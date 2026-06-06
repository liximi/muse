local Widget = require "ui.widgets.widget"
local Panel = require "ui.widgets.panel"
local Button = require "ui.widgets.button"
local Scroll = require "ui.widgets.containers.scroll_container"
local Utils = require "ui.utils"
local UiManager = require "ui.ui_manager":GetInstance()
local Class = require "dependencies.classic"

-- 跟踪所有活跃的 Dropdown popup，用于测试场景切换时批量清理
local active_dropdowns = {}

-- 递归设置 widget 及其所有子节点的 render_layer
local function setRenderLayerRecursive(widget, layer)
	widget.render_layer = layer
	for _, child in ipairs(widget.children) do
		setRenderLayerRecursive(child, layer)
	end
end

-- 伪常量
local ITEM_HEIGHT = 28          -- 选项按钮高度（像素）
local MAX_VISIBLE_ITEMS = 6     -- 默认同时可见最多选项数
local POPUP_OFFSET_Y = 2        -- 弹出面板距触发按钮的垂直间距（像素）
local SCROLL_BAR_W = 6          -- 滚动条宽度（像素）
local SCROLL_BAR_GAP = 0        -- 滚动条与内容间距（像素）
local SCROLL_EDGE_PAD = 2       -- 滚动条两端距面板边缘的默认边距（像素）
local SCREEN_EDGE_GAP = 8       -- 屏幕边缘最小间距（像素）

--[[datas: 此处不包括当前Widget继承的基类所支持的字段
	options = {string, ...}     选项文本列表
	selected_index = number     默认选中索引（1-based，默认 1）
	on_select = function(index, value)  选中回调
	max_visible_items = number  同时可见最多选项数（默认 6）
	placeholder = string        未选择时的占位文本
	scrollbar_edge_pad = number 滚动条两端距面板边缘的边距（像素，默认 2）
]]
local Dropdown = Class(Widget, function(self, datas, theme)
	Widget.new(self, "Dropdown", datas, theme)

	self.options = datas.options or {}
	self.selected_index = datas.selected_index or 1
	self.onSelect = datas.on_select
	self.max_visible_items = datas.max_visible_items or MAX_VISIBLE_ITEMS
	self._scrollbar_edge_pad = (datas.scrollbar_edge_pad ~= nil) and datas.scrollbar_edge_pad or SCROLL_EDGE_PAD
	self._is_open = false
	self._item_btns = {}

	-- 触发按钮
	self.trigger = self:addChild(Button({
		normal = Utils.newButtonStateStyle(self:_getDisplayText()),
		anchor = {0, 0, 1, 1},
		padding = {0, 0, 0, 0},
		on_click = function()
			self:_toggle()
		end,
	}))

	-- 弹出层：作为 UiManager 根 widget，全屏锚点 + DROPDOWN 渲染层
	self.popup = Widget({
		anchor = {0, 0, 1, 1},
		padding = {0, 0, 0, 0},
	})
	self.popup.render_layer = Utils.RENDER_LAYERS.DROPDOWN
	UiManager:addWidget(self.popup)
	table.insert(active_dropdowns, self)

	-- 弹出面板（在 popup 内部绝对定位）
	self.panel = self.popup:addChild(Panel({
		bg_color = {0.12, 0.12, 0.14, 0.98},
		rounding_radius = 4,
		outline_width = 1,
		outline_color = {0.25, 0.25, 0.3, 1},
		anchor = {0, 0, 0, 0},
		pivot = {0, 0},
	}))
	self.panel.render_layer = Utils.RENDER_LAYERS.DROPDOWN

	-- 点击 popup 空白区域关闭下拉
	function self.popup.onMousePressed(_self, x, y, button)
		if button == 1 and self.panel then
			if not self.panel:regionDetection(x, y) then
				self:_close()
				return true
			end
		end
	end

	-- 拦截 MouseMoved，防止穿透到背后的 widget 造成焦点争抢/闪烁
	function self.popup.onMouseMoved(_self, x, y, dx, dy)
		return true
	end

	self:_buildItems()
	setRenderLayerRecursive(self.popup, Utils.RENDER_LAYERS.DROPDOWN)
	self.popup:hide()
end)

--- 销毁当前 Dropdown 的 popup 并从 UiManager 移除
function Dropdown:destroyPopup()
	if not self.popup then
		return
	end
	for i, w in ipairs(UiManager.hierarchy) do
		if w == self.popup then
			table.remove(UiManager.hierarchy, i)
			break
		end
	end
	self.popup:destroy()
	self.popup = nil
end

--- 销毁所有活跃 Dropdown 的 popup（测试场景切换时调用）
function Dropdown.destroyAll()
	for _, dd in ipairs(active_dropdowns) do
		dd:destroyPopup()
	end
	-- 清空注册表（但保留表本身，下次创建还会往里加）
	for i = #active_dropdowns, 1, -1 do
		active_dropdowns[i] = nil
	end
end

function Dropdown:_getDisplayText()
	if #self.options == 0 then
		return ""
	end
	local idx = math.max(1, math.min(#self.options, self.selected_index))
	return self.options[idx]
end

function Dropdown:_toggle()
	if self._is_open then
		self:_close()
	else
		self:_open()
	end
end

function Dropdown:_open()
	if not self.trigger or not self.popup then
		return
	end
	-- 确保 popup 整棵子树都是 DROPDOWN 渲染层（_buildItems 可能新增了节点）
	setRenderLayerRecursive(self.popup, Utils.RENDER_LAYERS.DROPDOWN)
	self._is_open = true

	-- 计算面板位置（触发按钮底部）
	local tx, ty = self.trigger.transform:getGlobalPosition()
	local _, th = self.trigger.transform:getGlobalScaledSize()
	local tw = self.transform.w
	local panel_w = tw
	local panel_h = self:_calcPanelHeight()
	local sw = love.graphics.getWidth()
	local sh = love.graphics.getHeight()

	-- 下方空间不足则翻转到上方
	local pos_y = ty + th + POPUP_OFFSET_Y
	if pos_y + panel_h > sh - SCREEN_EDGE_GAP then
		pos_y = ty - panel_h - POPUP_OFFSET_Y
	end

	-- 右方空间不足则向左对齐
	local pos_x = tx
	if pos_x + panel_w > sw - SCREEN_EDGE_GAP then
		pos_x = tx + tw - panel_w
	end

	self.panel.transform:setPosition(pos_x, pos_y)
	self.popup:show()
end

function Dropdown:_close()
	self._is_open = false
	if self.popup then
		self.popup:hide()
	end
end

function Dropdown:_calcPanelHeight()
	local count = math.min(#self.options, self.max_visible_items)
	return count * ITEM_HEIGHT
end

--------------------------------------------------
-- 构造选项按钮样式（不创建 widget，纯数据）
--------------------------------------------------

function Dropdown:_makeItemStyles(index)
	local text = self.options[index]
	if index == self.selected_index then
		return {
			normal = Utils.newButtonStateStyle(text, nil, nil, {0.18, 0.3, 0.5, 1}, nil, nil, nil, nil, 0),
			hover = Utils.newButtonStateStyle(nil, nil, nil, {0.22, 0.35, 0.55, 1}, nil, nil, nil, nil, 0),
			pressed = Utils.newButtonStateStyle(nil, nil, nil, {0.22, 0.35, 0.55, 1}, nil, nil, nil, nil, 0),
		}
	else
		return {
			normal = Utils.newButtonStateStyle(text, nil, nil, {0, 0, 0, 0}, nil, nil, nil, nil, 0),
			hover = Utils.newButtonStateStyle(nil, nil, nil, {0.18, 0.18, 0.22, 1}, nil, nil, nil, nil, 0),
			pressed = Utils.newButtonStateStyle(nil, nil, nil, {0.18, 0.18, 0.22, 1}, nil, nil, nil, nil, 0),
		}
	end
end

--------------------------------------------------
-- 构建选项列表
--------------------------------------------------

function Dropdown:_buildItems()
	self.panel:removeAllChildren()
	self._item_btns = {}

	local visible_count = math.min(#self.options, self.max_visible_items)
	local panel_h = visible_count * ITEM_HEIGHT
	self.panel.transform:setSize(self.transform.w, panel_h)

	if #self.options <= self.max_visible_items then
		-- 全部可见，直接放按钮
		for i, option_text in ipairs(self.options) do
			local btn = self:_createItemBtn(i, option_text, (i - 1) * ITEM_HEIGHT)
			self.panel:addChild(btn)
			self._item_btns[i] = btn
		end
	else
		-- 超出最大可见数，包裹进滚动容器
		local list = Widget({
			anchor = {0, 0, 1, 0},
		})
		list.transform:setSize(nil, #self.options * ITEM_HEIGHT)

		for i, option_text in ipairs(self.options) do
			local btn = self:_createItemBtn(i, option_text, (i - 1) * ITEM_HEIGHT)
			list:addChild(btn)
			self._item_btns[i] = btn
		end

		local scroll = Scroll({
			item = list,
			anchor = {0, 0, 1, 1},
			padding = {0, SCROLL_BAR_W + SCROLL_BAR_GAP, 0, 0},
			scrollbar_gap = SCROLL_BAR_GAP,
			hide_slider_when_cannot_scroll = true,
			v_bar_pad_top = self._scrollbar_edge_pad,
			v_bar_pad_bottom = self._scrollbar_edge_pad,
		})
		self.panel:addChild(scroll)
	end
end

-- 仅更新按钮样式（不重建 widget），避免滚动位置丢失
function Dropdown:_updateItemStyles()
	for i, btn in ipairs(self._item_btns) do
		local styles = self:_makeItemStyles(i)
		btn:setStateStyle("normal", styles.normal)
		btn:setStateStyle("hover", styles.hover)
		btn:setStateStyle("pressed", styles.pressed)
		-- 刷新当前状态以应用新样式
		btn:setState(btn.cur_state)
	end
end

function Dropdown:_createItemBtn(index, text, y_pos)
	local styles = self:_makeItemStyles(index)

	local btn = Button({
		normal = styles.normal,
		hover = styles.hover,
		pressed = styles.pressed,
		anchor = {0, 0, 1, 0},
		padding = {0, 0, y_pos, 0},
		h = ITEM_HEIGHT,
		on_click = function()
			self:select(index)
		end,
	})
	return btn
end

--------------------------------------------------
-- 公开 API
--------------------------------------------------

function Dropdown:select(index)
	index = math.max(1, math.min(#self.options, index))
	if index == self.selected_index then
		self:_close()
		return
	end
	self.selected_index = index
	self.trigger:setStateStyle("normal", Utils.newButtonStateStyle(self:_getDisplayText()))
	-- 仅更新按钮高亮，不重建列表（保留滚动位置）
	self:_updateItemStyles()
	self:_close()
	if self.onSelect then
		self:onSelect(index, self.options[index])
	end
end

function Dropdown:getSelectedIndex()
	return self.selected_index
end

function Dropdown:getSelectedValue()
	return self.options[self.selected_index]
end

function Dropdown:setOptions(options, selected_index)
	self.options = options or {}
	self.selected_index = selected_index or 1
	self.trigger:setStateStyle("normal", Utils.newButtonStateStyle(self:_getDisplayText()))
	self:_buildItems()
	if self._is_open then
		self:_close()
		self:_open()
	end
end

return Dropdown
