local Button = require "ui.widgets.button"
local Image = require "ui.widgets.image"
local Utils = require "ui.utils"
local Fonts = require "ui.fonts"
local BTN_STATES = Utils.BTN_STATES


--[[相对Button，state_defs支持的字段有变化：
{
	text:string,
	text_color:table,
	texture:love.Image,
	offset:table,
	scale:table
}
]]

local ImageButton = Class(Button, function (self)
	Button.new(self)
	self._name = "ImageButton"

	self.image = self:addChild(Image())
	self.image:moveToBottom()

	self.transform:setSize(120, 50)
end)


function ImageButton:setState(new_state)
	if not BTN_STATES[string.upper(new_state)] then
		print("Button:setStateStyle|Invalid state:", new_state)
		return
	end
	Button.setState(self, new_state)

	self.cur_state = new_state

	local new_texture = self.state_styles[new_state] and self.state_styles[new_state].texture or self.state_styles.normal.texture
	if new_texture then
		self.image:setTexture(new_texture)
	end
end


function ImageButton:onDraw()
	local x, y = self:getGlobalPosition()
	local w, h = self:getGlobalScaledSize()

	if self._debug then
		love.graphics.setColor(unpack(Utils.UI_COLORS.PINK))
		love.graphics.rectangle("line", x-1, y-1, w + 2, h + 2)
		love.graphics.printf(string.format("State: %s", self.cur_state), Fonts:getFont("default", 16), x, y + h, self.width)
	end
end


return ImageButton