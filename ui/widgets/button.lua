local Widget = require "ui.widgets.widget"
local ButtonBase = require "ui.widgets.button_base"
local Text = require "ui.widgets.text"
local Utils = require "ui.utils"
local Fonts = require "ui.fonts"
local BTN_STATES = Utils.BTN_STATES


local Button = Class(ButtonBase, function (self, datas, theme)
	if not datas then
		datas = {}
	end
	if not datas.w then
		datas.w = 120
	end
	if not datas.h then
		datas.h = 50
	end
	ButtonBase.new(self, "Button", datas, theme)

	self.outline_width = datas and datas.outline_width or self.theme.button.outline_width

	self.state_styles = {
		normal = {
			text = datas and datas.text or "Button",
			text_color = datas and datas.text_color or self.theme.button.text_color,
			bg_color = datas and datas.bg_color or self.theme.button.bg_color,
			outline_color = datas and datas.outline_color or self.theme.button.outline_color,
			rounding_radius = datas and datas.rounding_radius or self.theme.button.rounding_radius,
			offset = datas and datas.offset or self.theme.button.offset,
			scale = datas and datas.scale or self.theme.button.scale,
			enable_shadow = datas and datas.enable_shadow or self.theme.button.enable_shadow,
		},
	}
	if self.state_styles.normal.enable_shadow then
		self.state_styles.normal.shadow_offset = datas and datas.shadow_offset or self.theme.button.shadow_offset or Utils.SHADOW_DEFAULT_PROPS.OFFSET
		self.state_styles.normal.shadow_color = datas and datas.shadow_color or self.theme.button.shadow_color or Utils.SHADOW_DEFAULT_PROPS.COLOR
		self.state_styles.normal.shadow_blur = datas and datas.shadow_blur or self.theme.button.shadow_blur or Utils.SHADOW_DEFAULT_PROPS.BLUR
	end
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
				enable_shadow = datas and datas["enable_shadow_"..state] or self.theme.button["enable_shadow_"..state],
			}
			if self.state_styles[state].enable_shadow then
				self.state_styles[state].shadow_offset = datas and datas["shadow_offset_"..state] or self.theme.button["shadow_offset_"..state] or Utils.SHADOW_DEFAULT_PROPS.OFFSET
				self.state_styles[state].shadow_color = datas and datas["shadow_color_"..state] or self.theme.button["shadow_color_"..state] or Utils.SHADOW_DEFAULT_PROPS.COLOR
				self.state_styles[state].shadow_blur = datas and datas["shadow_blur_"..state] or self.theme.button["shadow_blur_"..state] or Utils.SHADOW_DEFAULT_PROPS.BLUR
			end
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


function Button:onSetState(old_state, new_state)
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


function Button:onDraw()
	local x, y, w, h, r = self.transform:getGlobalBounds()
	local cur_state_def = self.state_styles[self.cur_state]
	local bg_color = cur_state_def.bg_color or self.state_styles.normal.bg_color
	local outline_color = cur_state_def.outline_color or self.state_styles.normal.outline_color
	local rounding_radius = cur_state_def.rounding_radius or self.state_styles.normal.rounding_radius or 0

	if cur_state_def.enable_shadow then
		Utils.drawRectangleShadow(
			{x+w/2, y+h/2},
			{w/2, h/2},
			cur_state_def.shadow_blur / 2,
			rounding_radius,
			cur_state_def.shadow_offset,
			cur_state_def.shadow_color,
			r
		)
	end

	love.graphics.push()
	if r ~= 0 and r ~= Utils.TWO_PI then
		local px, py = self.transform:getGlobalPosition()
		love.graphics.translate(px, py)
		love.graphics.rotate(r)
		love.graphics.translate(-px, -py)
	end
	love.graphics.setLineWidth(self.outline_width)
	if bg_color then
		love.graphics.setColor(unpack(bg_color))
		love.graphics.rectangle("fill", x, y, w, h, rounding_radius)
	end
	if outline_color then
		love.graphics.setColor(unpack(outline_color))
		love.graphics.rectangle("line", x, y, w, h, rounding_radius)
	end

	love.graphics.setLineWidth(1)
	love.graphics.pop()

	if self._debug then
		local x, y, w, h = self.transform:getGlobalAABB()
		love.graphics.setColor(unpack(Utils.UI_COLORS.PINK))
		love.graphics.printf(string.format("State: %s", self.cur_state), Fonts:getFont("default", 16), x, y + h, w)
	end
end


return Button