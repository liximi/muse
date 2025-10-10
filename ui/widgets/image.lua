local Widget = require "ui.widgets.widget"
local Utils = require "ui.utils"
local Fonts = require "ui.fonts"
local AddSizeComponent = require "ui.components".AddSize


local Image = Class(Widget, function(self, texture)
	Widget.new(self, "Image")

	AddSizeComponent(self)
	self.texture = nil
	if texture then
		self:setTexture(texture, true)
	end
end)


--- 设置贴图对象
---@param texture love.Image
---@param resize boolean 是否要将图像尺寸重置为新设置的贴图的原始尺寸
function Image:setTexture(texture, resize)
	self.texture = texture
	if resize then
		self:reSize()
	end
end


--- 获取UI贴图资源的原始尺寸
function Image:getTextureRowSize()
	if self.texture then
		return self.texture:getWidth(), self.texture:getHeight()
	else
		return 0, 0
	end
end


--- 将UI的尺寸还原到贴图资源的原始尺寸
function Image:reSize()
	if self.texture then
		local w, h = self:getTextureRowSize()
		self.transform:setSize(w, h)
	else
		self.transform:setSize(0, 0)
	end
end


function Image:onDraw()
	if self.texture then
		love.graphics.setColor(1, 1, 1, 1)
		local x, y = self:getGlobalPosition()
		local w, h = self:getGlobalScaledSize()
		local rw, rh = self:getTextureRowSize()
		local sx, sy = w / rw, h / rh
		love.graphics.draw(self.texture, x, y, self.rotation, sx, sy)

		if self._debug then
			love.graphics.setColor(unpack(Utils.debug_color1))
			love.graphics.rectangle("line", x-1, y-1, w + 2, h + 2)
			love.graphics.printf(string.format("Current Size: %dpx, %dpx\nRow Size: %dpx, %dpx", w, h, rw, rh), Fonts:getFont("default", 16), x, y + h, w)
		end
	else
		if self._debug then
			local x, y = self:getGlobalPosition()
			love.graphics.setColor(unpack(Utils.debug_color1))
			love.graphics.rectangle("line", x-1, y-1, 2, 2)
			love.graphics.setFont(Fonts:getFont("default", 16))
			love.graphics.print("No Texture", x, y + 1)
		end
	end

end



return Image