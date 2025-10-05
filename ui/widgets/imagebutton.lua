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

	self.image = self:AddChild(Image())
	self.image:MoveToBottom()

	self:SetSize(120, 50)
end)


function ImageButton:SetSize(w, h)
	Button.SetSize(self, w, h)
	if self.image then
		self.image:SetSize(w, h)
	end
end

function ImageButton:GetSize()
	return self.image:GetSize()
end


function ImageButton:SetState(new_state)
	if not BTN_STATES[new_state] then
		print("Button:SetStateDef|Invalid state:", new_state)
		return
	end
	Button.SetState(self, new_state)

	self.cur_state = new_state

	local new_texture = self.state_defs[new_state] and self.state_defs[new_state].texture or self.state_defs.normal.texture
	if new_texture then
		self.image:SetTexture(new_texture)
	end
end


function ImageButton:OnDraw()
	local x, y = self:GetGlobalPosition()
	local w, h = self:GetGlobalScaledSize()

	if self._debug then
		love.graphics.setColor(unpack(Utils.debug_color1))
		love.graphics.rectangle("line", x-1, y-1, w + 2, h + 2)
		love.graphics.printf(string.format("State: %s", self.cur_state), Fonts:GetFont("default", 16), x, y + h, self.width)
	end
end


return ImageButton