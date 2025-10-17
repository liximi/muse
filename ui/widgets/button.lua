local Widget = require "ui.widgets.widget"
local Text = require "ui.widgets.text"
local Utils = require "ui.utils"
local Fonts = require "ui.fonts"
local BTN_STATES = Utils.BTN_STATES


local Button = Class(Widget, function (self, datas, theme)
	if not datas then
		datas = {}
	end
	if not datas.w then
		datas.w = 120
	end
	if not datas.h then
		datas.h = 50
	end
	Widget.new(self, "Button", datas, theme)

	self.outline_width = datas and datas.outline_width or self.theme.button.outline_width

	self.cur_state = BTN_STATES.NORMAL
	self.state_styles = {
		normal = {
			text = datas and datas.text or "Button",
			text_color = datas and datas.text_color or self.theme.button.text_color,
			bg_color = datas and datas.bg_color or self.theme.button.bg_color,
			outline_color = datas and datas.outline_color or self.theme.button.outline_color,
			rounding_radius = datas and datas.rounding_radius or self.theme.button.rounding_radius,
			offset = datas and datas.offset or self.theme.button.offset,
			scale = datas and datas.scale or self.theme.button.scale,
		},
	}
	for k, state in pairs(Utils.BTN_STATES) do
		if state ~= Utils.BTN_STATES.NORMAL then
			self.state_styles[state] = {
				text = datas and datas["text_"..state],
				text_color = datas and datas["text_color_"..state] or self.theme.button["text_color_"..state],
				bg_color = datas and datas["bg_color_"..state] or self.theme.button["bg_color_"..state],
				outline_color = datas and datas["outline_color_"..state] or self.theme.button["outline_color_"..state],
				rounding_radius = datas and datas["rounding_radius_"..state] or self.theme.button["rounding_radius_"..state],
				offset = datas and datas["offset_"..state] or self.theme.button["offset_"..state],
				scale = datas and datas["scale_"..state] or self.theme.button["scale_"..state],
			}
		end
	end

	self.text = self:addChild(Text({
		pivot = {0.5, 0.5},
		anchors = {0, 0, 1, 1},
		padding = {2, 2, 2, 2},
		h_align = "center",
		v_align = "center",
		text = self.state_styles.normal.text,
		text_color = self.state_styles.normal.text_color,
	}))
end)


--- 设置按钮在某个状态下的样子
---@param state "normal"|"pressed"|"disabled"|"selected"|"hover"|"seleted_hover"
---@param def Utils.newButtonStateStyle 配置信息表 
function Button:setStateStyle(state, def)
	if not BTN_STATES[string.upper(state)] then
		print("Button:setStateStyle|Invalid state:", state)
		return
	end
	self.state_styles[state] = def
	self:setState(self.cur_state)
end


function Button:setState(new_state)
	if not BTN_STATES[string.upper(new_state)] then
		print("Button:setStateStyle|Invalid state:", new_state)
		return
	end
	local old_state = self.cur_state
	self.cur_state = new_state

	local new_text = self.state_styles[new_state] and self.state_styles[new_state].text
	if new_text then
		self.text:setText(new_text)
	end
	local new_text_color = self.state_styles[new_state] and self.state_styles[new_state].text_color
	if new_text_color then
		self.text:setTextColor(new_text_color)
	end

	local old_offset = self.state_styles[old_state] and self.state_styles[old_state].offset or {0, 0}
	local offset = self.state_styles[new_state] and self.state_styles[new_state].offset or {0, 0}
	local total_offset = {offset[1] - old_offset[1], offset[2] - old_offset[2]}
	local x, y = self:getPosition()
	self:setPosition(x+total_offset[1], y+total_offset[2])

	local scale = self.state_styles[new_state] and self.state_styles[new_state].scale or {1, 1}
	self.transform:setScale(scale[1], scale[2])
end

function Button:onFocus()
	if self.cur_state == BTN_STATES.NORMAL then
		self:setState(BTN_STATES.HOVER)
	elseif self.cur_state == BTN_STATES.SELECTED then
		self:setState(BTN_STATES.SELECTED_HOVER)
	end
end

function Button:onRemoveFocus()
	if self.cur_state == BTN_STATES.SELECTED_HOVER then
		self:setState(BTN_STATES.SELECTED)
	elseif self.cur_state == BTN_STATES.HOVER then
		self:setState(BTN_STATES.NORMAL)
	end
end


function Button:onMousePressed(x, y, button)
	if button == 1 and self:regionDetection(x, y) then
		if self.cur_state == BTN_STATES.NORMAL or self.cur_state == BTN_STATES.HOVER then
			self:setState(BTN_STATES.PRESSED)
		end
	end
end

function Button:onMouseReleased(x, y, button)
	if button == 1 and self.cur_state == BTN_STATES.PRESSED then
		self:setState(BTN_STATES.NORMAL)
		if self.onClick then
			self:onClick()
		end
	end
end

function Button:onMouseMoved(x, y, dx, dy)
	if self:regionDetection(x, y) then
		if not self:isFocus() then
			self:setFocus()
		end
	elseif self:isFocus() then
		self:removeFocus()
	end
end



function Button:onDraw()
	local cur_state_def = self.state_styles[self.cur_state]
	local x, y = self:getGlobalPosition()
	local w, h = self:getGlobalScaledSize()
	local bg_color = cur_state_def.bg_color or self.state_styles.normal.bg_color
	local outline_color = cur_state_def.outline_color or self.state_styles.normal.outline_color
	local rounding_radius = cur_state_def.rounding_radius or self.state_styles.normal.rounding_radius or 0
	love.graphics.setLineWidth(self.outline_width)
	if bg_color then
		love.graphics.setColor(unpack(bg_color))
		love.graphics.rectangle("fill", x, y, w, h, rounding_radius, rounding_radius, rounding_radius * 2)
	end
	if outline_color then
		love.graphics.setColor(unpack(outline_color))
		love.graphics.rectangle("line", x, y, w, h, rounding_radius, rounding_radius, rounding_radius * 2)
	end

	if self._debug then
		love.graphics.setColor(unpack(Utils.UI_COLORS.PINK))
		love.graphics.rectangle("line", x-1, y-1, w + 2, h + 2)
		love.graphics.printf(string.format("State: %s", self.cur_state), Fonts:getFont("default", 16), x, y + h, w)
	end
	love.graphics.setLineWidth(1)
end


return Button