local ButtonBase = require "ui.widgets.button_base"
local Text = require "ui.widgets.text"
local Utils = require "ui.utils"
local Fonts = require "ui.fonts"
local BTN_STATES = Utils.BTN_STATES


--[[datas: 此处不包括当前Widget继承的基类所支持的字段
	font_key = string
	normal = Utils.newButtonStateStyle
	hover = Utils.newButtonStateStyle
	pressed = Utils.newButtonStateStyle
	disabled = Utils.newButtonStateStyle
	selected = Utils.newButtonStateStyle
	selected_hover = Utils.newButtonStateStyle
]]
local Button = Class(ButtonBase, function (self, datas, theme)
	datas = datas or {}
	ButtonBase.new(self, "Button", datas, theme)

	self.state_styles = {
		normal = datas.normal,
		hover = datas.hover,
		pressed = datas.pressed,
		disabled = datas.disabled,
		selected = datas.selected,
		selected_hover = datas.selected_hover,
	}

	self.text = self:addChild(Text({
		pivot = {0.5, 0.5},
		anchors = {0, 0, 1, 1},
		padding = {2, 2, 2, 2},
		h_align = "center",
		v_align = "center",
		text = self.state_styles.normal and self.state_styles.normal.text or "Button",
		text_color = self.state_styles.normal and self.state_styles.normal.text_color or (self.theme.button and self.theme.button.normal.text_color),
		font_key = datas.font_key,
		font_size = self.state_styles.normal and self.state_styles.normal.font_size or (self.theme.button and self.theme.button.normal.font_size),
	}))
end)


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


--- 获取按钮在某个状态下的样式，会自动合并自定义样式、normal状态样式和主题样式
--- state_styles里对应状态的数据 > state_styles里normal状态的数据 > 主题里对应状态的数据 > 主题里normal状态的数据
---@param state "normal"|"pressed"|"disabled"|"selected"|"hover"|"seleted_hover"
function Button:getStateStyle(state)
	local style = {}
	local t1 = { self.state_styles, self.theme.button }
	local t2 = state == "normal" and { "normal" } or { state, "normal" }
	for _, t in ipairs(t1) do
		for _, s in ipairs(t2) do
			if t[s] then
				for k, v in pairs(t[s]) do
					if not style[k] then
						style[k] = v
					end
				end
			end
		end
	end
	return style
end


function Button:onSetState(old_state, new_state)
	local old_style = self:getStateStyle(old_state)
	local new_style = self:getStateStyle(new_state)
	if self.text then
		local new_text = new_style.text
		if new_text then
			self.text:setText(new_text)
		end
		local new_text_color = new_style.text_color
		if new_text_color then
			self.text:setTextColor(new_text_color)
		end
		local new_font_szie = new_style.font_size
		if new_font_szie and self.text:getFontSize() ~= new_font_szie then
			self.text:setFontSize(new_font_szie)
		end
	end

	local old_offset = old_style.offset or {0, 0}
	local offset = new_style.offset or {0, 0}
	local total_offset = {offset[1] - old_offset[1], offset[2] - old_offset[2]}
	local x, y = self:getPosition()
	self:setPosition(x+total_offset[1], y+total_offset[2])

	local scale = new_style and new_style.scale or {1, 1}
	self.transform:setScale(scale[1], scale[2])
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

	if self._debug then
		local x, y, w, h = self.transform:getGlobalAABB()
		love.graphics.setColor(unpack(Utils.UI_COLORS.PINK))
		love.graphics.printf(string.format("State: %s", self.cur_state), Fonts:getFont("debug", 16), x, y + h, w)
	end
end


return Button