local Widget = require "ui.widgets.widget"
local Utils = require "ui.utils"
local Fonts = require "ui.fonts"


--覆盖了 Texture 对象的 WrapMode 为 clamp 时的行为，将通过拉伸来填满UI矩形范围。
local Image = Class(Widget, function(self, datas, theme)
	Widget.new(self, "Image", datas, theme)

	self.__quad = love.graphics.newQuad(0, 0, 0, 0, 1, 1)

	-- self.texture = nil
	if datas and datas.texture then
		--注意：use_texture_size和锚点【范围定位】机制是冲突的
		--也会覆盖datas.w 和 datas.h
		self:setTexture(datas.texture, datas.use_texture_size)
	end

	self.tint = datas and datas.tint or self.theme.image.tint
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


function Image:getTexture()
	return self.texture
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
	local x, y, w, h, r = self.transform:getGlobalBounds()

	love.graphics.push()

	if r ~= 0 and r ~= Utils.TWO_PI then
		local px, py = self.transform:getGlobalPosition()
		love.graphics.translate(px, py)
		love.graphics.rotate(r)
		love.graphics.translate(-px, -py)
	end

	if self.texture then
		love.graphics.setColor(unpack(self.tint))
		local rw, rh = self:getTextureRowSize()
		local sx, sy = self:getGlobalScale()
		local wrapw, wraph = self.texture:getWrap()
		local quadw, quadh = self.transform.w, self.transform.h
		if wrapw == "clamp" then
			quadw = rw
			sx = w / rw
		end
		if wraph == "clamp" then
			quadh = rh
			sy = h / rh
		end
		self.__quad:setViewport(0, 0, quadw, quadh, rw, rh)
		love.graphics.draw(self.texture, self.__quad, x, y, self.rotation, sx, sy)

		if self._debug then
			love.graphics.setColor(unpack(Utils.UI_COLORS.PINK))
			love.graphics.printf(string.format("Current Size: %dpx, %dpx\nRow Size: %dpx, %dpx", w, h, rw, rh), Fonts:getFont("debug", 14), x, y + h, w)
		end
	else
		if self._debug then
			love.graphics.setColor(unpack(Utils.UI_COLORS.PINK))
			love.graphics.printf("No Texture", Fonts:getFont("debug", 14), x, y + 1, math.max(100, w))
		end
	end

	love.graphics.pop()
end


return Image