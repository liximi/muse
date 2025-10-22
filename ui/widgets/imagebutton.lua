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

local ImageButton = Class(Button, function (self, datas, theme)
	Button.new(self, datas, theme)
	self._name = "ImageButton"

	self.state_styles.normal.texture = datas and datas.texture
	for k, state in pairs(Utils.BTN_STATES) do
		if state ~= Utils.BTN_STATES.NORMAL then
			self.state_styles[state].texture = datas and datas["texture_"..state]
		end
	end

	local img_datas = {
		texture = datas and datas.texture,
		anchors = {0, 0, 1, 1},
		padding = {0, 0, 0, 0},
		tint = datas and datas.tint,
	}
	self.image = self:addChild(Image(img_datas, theme))
	self.image:moveToBottom()
end)


function ImageButton:onSetState(old_state, new_state)
	Button.onSetState(self, old_state, new_state)
	local new_texture = self.state_styles[new_state] and self.state_styles[new_state].texture or self.state_styles.normal.texture
	if new_texture then
		self.image:setTexture(new_texture)
	end
	local new_img_tint = self.state_styles[new_state] and self.state_styles[new_state].tint or Utils.UI_COLORS.WHITE
	self.image:setTint(new_img_tint)
end


function ImageButton:onDraw()
	if self._debug then
		local x, y, w, h = self.transform:getGlobalAABB()
		love.graphics.setColor(unpack(Utils.UI_COLORS.PINK))
		love.graphics.printf(string.format("State: %s", self.cur_state), Fonts:getFont("debug", 16), x, y + h, w)
	end
end


return ImageButton