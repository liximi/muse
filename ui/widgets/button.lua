local ButtonBase = require "ui.widgets.button_base"
local Text = require "ui.widgets.text"
local Utils = require "ui.utils"
local Components = require "ui.components"
local Fonts = require "ui.fonts"
local Class = require "dependencies.classic"
local BTN_STATES = Utils.BTN_STATES

-- 伪常量
local BUTTON_TEXT_PADDING = 2  -- 按钮文字内边距（像素）

--[[datas: 此处不包括当前Widget继承的基类所支持的字段
	font_key = string
	normal = Utils.newButtonStateStyle
	hover = Utils.newButtonStateStyle
	pressed = Utils.newButtonStateStyle
	disabled = Utils.newButtonStateStyle
	selected = Utils.newButtonStateStyle
	selected_hover = Utils.newButtonStateStyle
]]
local Button = Class(ButtonBase, function(self, datas, theme)
	datas = datas or {}
	ButtonBase.new(self, "Button", datas, theme)

	self.state_styles = {
		normal = datas.normal,
		hover = datas.hover,
		pressed = datas.pressed,
		disabled = datas.disabled,
		selected = datas.selected,
		selected_hover = datas.selected_hover
	}

	self.text = self:addChild(Text({
		pivot = {0.5, 0.5},
		anchor = {0, 0, 1, 1},
		padding = {BUTTON_TEXT_PADDING, BUTTON_TEXT_PADDING, BUTTON_TEXT_PADDING, BUTTON_TEXT_PADDING},
		h_align = "center",
		v_align = "center",
		text = self.state_styles.normal and self.state_styles.normal.text or "Button",
		text_color = self.state_styles.normal and self.state_styles.normal.text_color or
			(self.theme.button and self.theme.button.normal.text_color),
		font_key = datas.font_key,
		font_size = self.state_styles.normal and self.state_styles.normal.font_size or
			(self.theme.button and self.theme.button.normal.font_size)
	}))
	self.text.raycast_target = false -- 按钮文字不阻断射线，让父按钮处理点击
end)

--- 按钮最小尺寸 = 内部文字最小尺寸 + 文本内边距
function Button:getMinimumSize()
	local tw, th = self.text:getMinimumSize()
	return tw + BUTTON_TEXT_PADDING * 2, th + BUTTON_TEXT_PADDING * 2
end

--- 设置按钮在某个状态下的样式
---@param state "normal"|"pressed"|"disabled"|"selected"|"hover"|"seleted_hover"
---@param style Utils.newButtonStateStyle 配置信息表 
function Button:setStateStyle(state, style)
	if not BTN_STATES[string.upper(state)] then
		print("Button:setStateStyle|Invalid state:", state)
		return
	end
	self.state_styles[state] = style
	self:setState(self.cur_state)
end

--- 获取按钮在某个状态下的样式，会自动合并自定义样式和主题样式
--- 合并优先级（先到先得）：explicit state > theme state > explicit normal > theme normal
---@param state "normal"|"pressed"|"disabled"|"selected"|"hover"|"seleted_hover"
function Button:getStateStyle(state)
	local style = {}
	if state == "normal" then
		-- normal 状态：custom normal → theme normal
		local sources = {self.state_styles.normal, self.theme.button and self.theme.button.normal}
		for _, src in ipairs(sources) do
			if src then
				for k, v in pairs(src) do
					if not style[k] then style[k] = v end
				end
			end
		end
	else
		-- 非 normal 状态：custom state → theme state → custom normal → theme normal
		local sources = {
			self.state_styles[state],
			self.theme.button and self.theme.button[state],
			self.state_styles.normal,
			self.theme.button and self.theme.button.normal,
		}
		for _, src in ipairs(sources) do
			if src then
				for k, v in pairs(src) do
					if not style[k] then style[k] = v end
				end
			end
		end
	end
	return style
end

function Button:onSetState(old_state, new_state)
	local old_style = self:getStateStyle(old_state)
	local new_style = self:getStateStyle(new_state)
	Components.applyButtonTextStyle(self, new_style)
	Components.applyButtonTransform(self, old_style, new_style)
end

function Button:onDraw()
	local x, y, w, h, r = self.transform:getGlobalBounds()
	local style = self:getStateStyle(self.cur_state)
	local outline_width = style.outline_width or 0
	local rounding_radius = style.rounding_radius or 0

	love.graphics.push()
	if r ~= 0 and r ~= Utils.TWO_PI then
		local px, py = self.transform:getGlobalPosition()
		love.graphics.translate(px, py)
		love.graphics.rotate(r)
		love.graphics.translate(-px, -py)
	end

	if style.bg_color then
		love.graphics.setColor(unpack(style.bg_color))
		love.graphics.rectangle("fill", x, y, w, h, rounding_radius)
	end
	if style.outline_color and outline_width > 0 then
		love.graphics.setLineWidth(outline_width)
		love.graphics.setColor(unpack(style.outline_color))
		love.graphics.rectangle("line", x, y, w, h, rounding_radius)
		love.graphics.setLineWidth(1)
	end

	love.graphics.pop()
end

function Button:onDebugDraw()
	local x, y, w, h = self.transform:getGlobalAABB()
	love.graphics.setColor(unpack(Utils.UI_COLORS.PINK))
	love.graphics.printf(string.format("State: %s", self.cur_state), Fonts:getFont("debug", 16), x, y + h, w)
end

return Button
