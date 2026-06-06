local Widget = require "ui.widgets.widget"
local Utils = require "ui.utils"
local Fonts = require "ui.fonts"
local Class = require "dependencies.classic"

-- 伪常量
local DEBUG_INFO_FONT_SIZE = 14  -- 调试信息字号
local DEBUG_INFO_MIN_WIDTH = 100 -- 调试信息最小显示宽度

-- 覆盖了 Texture 对象的 WrapMode 为 clamp 时的行为，将通过拉伸来填满UI矩形范围。
--[[datas: 此处不包括当前Widget继承的基类所支持的字段
	texture = Texture
	use_texture_size = bool
	tint = {r, g, b, a}
]]
local Image = Class(Widget, function(self, datas, theme)
	Widget.new(self, "Image", datas, theme)

	self.__quad = love.graphics.newQuad(0, 0, 0, 0, 1, 1)

	-- self.texture = nil
	if datas and datas.texture then
		-- 注意：use_texture_size和锚点【范围定位】机制是冲突的
		-- 也会覆盖datas.w 和 datas.h
		self:setTexture(datas.texture, datas.use_texture_size)
	end

	self.tint = datas and datas.tint or self.theme.image.tint
end)

--- 设置贴图对象
---@param texture love.Texture
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

function Image:setTint(r, g, b, a)
	if type(r) == "table" then
		self.tint = r
	else
		self.tint = {r, g, b, a}
	end
end

function Image:getTint()
	return self.tint
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
	end

	love.graphics.pop()
end

function Image:onDebugDraw()
	local x, y, w, h, r = self.transform:getGlobalBounds()

	love.graphics.push()

	if r ~= 0 and r ~= Utils.TWO_PI then
		local px, py = self.transform:getGlobalPosition()
		love.graphics.translate(px, py)
		love.graphics.rotate(r)
		love.graphics.translate(-px, -py)
	end

	if self.texture then
		local rw, rh = self:getTextureRowSize()
		love.graphics.setColor(unpack(Utils.UI_COLORS.PINK))
		love.graphics.printf(string.format("Current Size: %dpx, %dpx\nRow Size: %dpx, %dpx", w, h, rw, rh),
			Fonts:getFont("debug", DEBUG_INFO_FONT_SIZE), x, y + h, w)
	else
		love.graphics.setColor(unpack(Utils.UI_COLORS.PINK))
		love.graphics.printf("No Texture", Fonts:getFont("debug", DEBUG_INFO_FONT_SIZE), x, y + 1, math.max(DEBUG_INFO_MIN_WIDTH, w))
	end

	love.graphics.pop()
end

return Image
