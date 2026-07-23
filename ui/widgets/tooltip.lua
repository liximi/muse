local Widget = require "ui.widgets.widget"
local Panel = require "ui.widgets.panel"
local Text = require "ui.widgets.text"
local Utils = require "ui.utils"
local UiManager = require "ui.ui_manager":GetInstance()
local Class = require "dependencies.classic"

-- 伪常量
local DEFAULT_DELAY = 0.5        -- 默认悬停延迟（秒）
local DEFAULT_MAX_WIDTH = 250    -- 默认文本最大宽度（像素）
local DEFAULT_OFFSET_X = 12      -- 默认鼠标 X 偏移（像素）
local DEFAULT_OFFSET_Y = 18      -- 默认鼠标 Y 偏移（像素）
local DEFAULT_FONT_SIZE = 13     -- 默认字号
local PADDING_X = 8              -- 水平内边距（像素）
local PADDING_Y = 5              -- 垂直内边距（像素）
local SCREEN_EDGE_GAP = 8        -- 屏幕边缘最小间距（像素）

-- Tooltip 主题色
local TOOLTIP_BG_COLOR = {0.08, 0.08, 0.08, 0.92}
local TOOLTIP_TEXT_COLOR = {0.95, 0.95, 0.95, 1}

--[[datas: 此处不包括当前Widget继承的基类所支持的字段
	target = Widget      目标 widget（必填）
	text = string        提示文本
	delay = number       悬停延迟秒数（默认 0.5）
	max_width = number   文本最大宽度像素（默认 250）
	offset = {x, y}      相对鼠标的偏移像素（默认 {12, 18}）
]]
local Tooltip = Class(Widget, function(self, datas, theme)
	Widget.new(self, "Tooltip", datas, theme)
	self.raycast_target = true

	self.target = datas.target
	self._hover_timer = 0
	self._active = false
	self._delay = datas.delay or DEFAULT_DELAY
	self._max_width = datas.max_width or DEFAULT_MAX_WIDTH
	self._offset = datas.offset or {DEFAULT_OFFSET_X, DEFAULT_OFFSET_Y}
	self._last_mx = -1
	self._last_my = -1

	-- 渲染在最顶层
	self.render_layer = Utils.RENDER_LAYERS.TOOLTIP

	-- 背景面板
	self.bg = self:addChild(Panel({
		bg_color = TOOLTIP_BG_COLOR,
		rounding_radius = 4,
		outline_width = 0,
		anchor = {0, 0, 0, 0},
		pivot = {0, 0},
	}))
	self.bg.render_layer = Utils.RENDER_LAYERS.TOOLTIP

	-- 文本标签（拉伸锚点填满 bg，padding 提供文字内边距）
	self.label = self.bg:addChild(Text({
		text = datas.text or "",
		text_color = TOOLTIP_TEXT_COLOR,
		font_size = DEFAULT_FONT_SIZE,
		wrap_mode = Utils.TEXT_WRAP_MODE.DEFAULT,
		anchor = {0, 0, 1, 1},
		pivot = {0, 0},
		padding = {PADDING_X, PADDING_X, PADDING_Y, PADDING_Y},
	}))
	self.label.render_layer = Utils.RENDER_LAYERS.TOOLTIP

	-- 初始隐藏；Tooltip 是无父节点的独立 UiManager 根 widget，构造时直接注册
	self:hide()
	UiManager:addWidget(self)
end)

function Tooltip:setText(text)
	self.label:setText(text)
end

function Tooltip:setTarget(target)
	self.target = target
end

--------------------------------------------------
-- Lifecycle：加入/离开 UiManager 活动树时自动注册/注销
--------------------------------------------------

function Tooltip:onAttached()
	-- Tooltip 在构造函数中自注册，不需要在此重复注册
end

function Tooltip:onDetached()
	-- 从 UiManager 注销（由 Widget:destroy → _setAttached(false) 触发）
end

--- 销毁所有活跃的 Tooltip（测试场景切换用）
function Tooltip.destroyAll()
	-- 收集所有 UiManager 根节点中的 Tooltip 实例
	local to_destroy = {}
	for _, w in ipairs(UiManager.hierarchy) do
		if w._name == "Tooltip" then
			table.insert(to_destroy, w)
		end
	end
	for _, t in ipairs(to_destroy) do
		t:destroy()
	end
end

--------------------------------------------------
-- Update & Draw
--------------------------------------------------

function Tooltip:onUpdate(dt)
	-- 只检查 target 是否存活+可见，不检查 enabled
	-- 禁用的按钮仍然应该在 hover 时显示 Tooltip
	if not self.target or not self.target._valid or not self.target.shown then
		if self._active then
			self._active = false
			self:hide()
		end
		return
	end

	local mx, my = love.mouse.getPosition()
	local is_over = self.target:regionDetection(mx, my)

	if is_over then
		self._hover_timer = self._hover_timer + dt
		if not self._active and self._hover_timer >= self._delay then
			self._active = true
			self:show()
		end
		if self._active and (mx ~= self._last_mx or my ~= self._last_my) then
			self:_updatePosition(mx, my)
			self._last_mx = mx
			self._last_my = my
		end
	else
		self._hover_timer = 0
		if self._active then
			self._active = false
			self:hide()
		end
	end
end

function Tooltip:_updatePosition(mx, my)
	local font = self.label:getFont()
	local text = self.label:getText(true)
	local text_w = font:getWidth(text)
	local max_w = math.min(text_w, self._max_width)
	local _, wrapped_lines = font:getWrap(text, max_w)
	local line_h = font:getHeight() * font:getLineHeight()
	local text_h = line_h * #wrapped_lines

	-- 实际文本宽度（不超过 max_w），单行用实际宽度
	local actual_w = max_w
	if #wrapped_lines == 1 then
		actual_w = text_w
	end

	-- 面板尺寸 = 文本尺寸 + padding
	local pw = actual_w + PADDING_X * 2
	local ph = text_h + PADDING_Y * 2

	-- 默认位置：鼠标右下
	local pos_x = mx + self._offset[1]
	local pos_y = my + self._offset[2]

	-- 屏幕边界约束
	local sw = love.graphics.getWidth()
	local sh = love.graphics.getHeight()
	if pos_x + pw > sw - SCREEN_EDGE_GAP then
		pos_x = mx - pw - self._offset[1]
	end
	if pos_y + ph > sh - SCREEN_EDGE_GAP then
		pos_y = my - ph - self._offset[2]
	end

	self.transform:setPosition(pos_x, pos_y)
	self.bg.transform:setSize(pw, ph)
end

return Tooltip
