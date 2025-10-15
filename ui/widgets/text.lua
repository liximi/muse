local Widget = require "ui.widgets.widget"
local Utils = require "ui.utils"
local Fonts = require "ui.fonts"
local utf8 = require "utf8"


local Text = Class(Widget, function(self, datas)
	Widget.new(self, "Text", datas)

	self.font_key = datas and datas.font or "default"
	self.font_size = datas and datas.font_size or 16

	self.text = datas and datas.text or ""--也支持coloredtext：一个包含颜色和字符串的表格，这些颜色和字符串将添加到该对象中，格式为 {color1, string1, color2, string2, ...}。
	self.text_color = datas and datas.text_color or Utils.UI_COLORS.WHITE--当text是一个coloredtext时，该属性将会和文本的颜色组合（相乘）

	self.wrap_mode = Utils.TEXT_WRAP_MODE.DEFAULT
	self.overflow_mode = Utils.TEXT_OVERFLOW_MODE.NONE
	self.overflow_ellipsis_char = "…"
	self.horizontal_align = datas and datas.h_align or "left"	--"left"|"right"|"center"|"justify"
	self.vertical_align = datas and datas.v_align or "top"	--"top"|"bottom"|"center"

	self.__text = love.graphics.newText(Fonts:getFont(self.font_key, self.font_size))
	self:updateTextLayout()
	self:enableSizeChangedEvent(true)
end)


--也支持coloredtext：一个包含颜色和字符串的表格，这些颜色和字符串将添加到该对象中，格式为 {color1, string1, color2, string2, ...}。
function Text:setText(text)
	self.text = text
	self:updateTextLayout()
end


local function _getText(coloredtext)
	local text = ""
	for _, v in ipairs(coloredtext) do
		if type(v) == "string" then
			text = text .. v
		end
	end
	return text
end
function Text:getText(only_string)
	local text = self.text
	if type(self.text) == "table" and only_string then
		text = _getText(self.text)
	end
	return text
end

function Text:setTextColor(r, g, b, a)
	if type(r) == "table" then
		self.text_color = r
	else
		self.text_color = Utils.RGB(r, g, b, a)
	end
end

function Text:getTextColor()
	return self.text_color
end




--- 设置字体
---@param font_key string 所有字体都需要先存入ui.fonts.lua里，再通过key使用。
function Text:setFont(font_key, size)
	if font_key and Fonts[font_key] then
		local font = Fonts:getFont(font_key, size)
		if not font then
			print("Text:setFont|Unregistered fonts: "..tostring(font_key))
			return
		end
		self.font_key = font_key
		if size then
			self.font_size = size
		end
		self.__text:setFont(Fonts:getFont(self.font_key, size))
		self:updateTextLayout()
	end
end

function Text:getFont(return_key)
	if return_key then
		return self.font_key
	end
	return Fonts:getFont(self.font_key, self.font_size)
end

function Text:setFontSize(size)
	self.font_size = size
	self.__text:setFont(Fonts:getFont(self.font_key, size))
	self:updateTextLayout()
end

function Text:getFontSize()
	return self.font_size
end




--- 设置水平方向的对齐方式
---@param align "left"|"right"|"center"|"justify"
function Text:setHAlign(align)
	self.horizontal_align = align
	self:updateTextLayout()
end

--- 设置垂直方向的对齐方式
---@param align "top"|"bottom"|"center"
function Text:setVAlign(align)
	self.vertical_align = align
	self:updateTextLayout()
end




function Text:setWrapMode(wrap_mode)
	self.wrap_mode = wrap_mode
	self:updateTextLayout()
end

function Text:getDimensions()
	local w, h = self.__text:getDimensions()
	return w, h
end

function Text:getScaledDimensions()
	local w, h = self:getDimensions()
	return w * self._sx, h * self._sy
end

function Text:getGlobalScaledDimensions()
	local w, h = self:getDimensions()
	local sx, sy = self:getGlobalScale()
	return w * sx, h * sy
end

function Text:updateTextLayout()
	self.__text:clear()
	if self.wrap_mode == Utils.TEXT_WRAP_MODE.OFF then
		local text = self:getText(true)
		local width = self.__text:getFont():getWidth(text)
		self.__text:setf(text, width, self.horizontal_align, 0, 0)
	else
		local text = self:getText(false)
		self.__text:setf(text, self.transform.w, self.horizontal_align, 0, 0)
	end
end

function Text:onSizeChanged(w, h)
	self:updateTextLayout()
end




function Text:onDraw()
	local px, py = self.transform:getGlobalPosition()
	local x, y, w, h, r = self.transform:getGlobalBounds()
	local sx, sy = self:getGlobalScale()
	local textw, texth = self:getGlobalScaledDimensions()
	love.graphics.push()
	love.graphics.setColor(unpack(self.text_color))
	if r ~= 0 and r ~= Utils.TWO_PI then
		love.graphics.translate(px, py)
		love.graphics.rotate(r)
		love.graphics.translate(-px, -py)
	end
	if self.horizontal_align == "right" then
		x = x + w - textw
	elseif self.horizontal_align == "center" then
		x = x + (w - textw) * 0.5
	end
	if self.vertical_align == "bottom" then
		y = y + h - texth
	elseif self.vertical_align == "center" then
		y = y + (h - texth) * 0.5
	end
	love.graphics.draw(self.__text, x, y, nil, sx, sy)

	if self._debug then
		love.graphics.setColor(unpack(Utils.UI_COLORS.DEBUG_WHITE))
		if self.horizontal_align == "justify" then
			love.graphics.rectangle("line", x, y, w, texth)
		else
			love.graphics.rectangle("line", x, y, textw, texth)
		end
	end
	love.graphics.pop()
end


return Text