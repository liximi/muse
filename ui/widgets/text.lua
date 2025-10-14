local Widget = require "ui.widgets.widget"
local Utils = require "ui.utils"
local Fonts = require "ui.fonts"
local utf8 = require "utf8"


local Text = Class(Widget, function(self, datas)
	Widget.new(self, "Text", datas)

	self.font_key = datas and datas.font or "default"
	self.font_size = datas and datas.font_size or 16

	self.text = datas and datas.text or ""--也支持coloredtext：一个包含颜色和字符串的表格，这些颜色和字符串将添加到该对象中，格式为 {color1, string1, color2, string2, ...}。
	self.text_color = datas and datas.text_color or Utils.UI_COLORS.WHITE

	self.horizontal_align = datas and datas.h_align or "left"	--"left"|"right"|"center"|"justify"
	self.vertical_align = datas and datas.v_align or "center"	--"top"|"bottom"|"center"

	self.__text = love.graphics.newText(Fonts:getFont(self.font_key, self.font_size))
	self:updateTextLayout()
	self:enableSizeChangedEvent(true)
end)


function Text:setText(text)
	self.text = text
	self:updateTextLayout()
end

function Text:getText()
	return self.text
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




--- 和love的Font:getWrap函数的功能一样，但是提供的是另一种对中文更好的换行策略。
--- @return number width
--- @return table wrapped_text
function Text:getWrap()
	local font = Fonts:getFont(self.font_key, self.font_size)
	local max_w = self.transform.w
	local wrap_w, wrapped_text = font:getWrap(self.text, self.transform.w)
	wrap_w = 0
	for i, str in ipairs(wrapped_text) do
		local next_str = wrapped_text[i+1]
		if not next_str then
			local w = font:getWidth(str)
			if w > wrap_w then
				wrap_w = w
			end
			break
		end
		while utf8.len(next_str) > 0 do
			local byteoffset = utf8.offset(next_str, 2)
			local char = string.sub(next_str, 1, byteoffset - 1)
			local tempstr = str .. char
			local tempw = font:getWidth(tempstr)
			if tempw > max_w then
				break
			end
			str = tempstr
			if tempw > wrap_w then
				wrap_w = tempw
			end
			next_str = string.sub(next_str, byteoffset)
		end
		wrapped_text[i] = str
		wrapped_text[i+1] = next_str ~= "" and next_str or nil
	end
	return wrap_w, wrapped_text
end

function Text:getDimensions()
	local font = Fonts:getFont(self.font_key, self.font_size)
	if not font then
		return 0, 0
	end
	local width, wrapped_text = self:getWrap()
	return width, font:getHeight() * font:getLineHeight() * #wrapped_text
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
	local font = self:getFont()
	local width, wrapped_text = self:getWrap()
	local line_h = font:getHeight() * font:getLineHeight()
	for i, str in pairs(wrapped_text) do
		self.__text:addf(str, self.transform.w, self.horizontal_align, 0, line_h * (i - 1))
	end
end

function Text:onSizeChanged(w, h)
	self:updateTextLayout()
end




function Text:onDraw()
	local px, py = self.transform:getGlobalPosition()
	local x, y, w, h, r = self.transform:getGlobalBounds()
	local sx, sy = self:getGlobalScale()
	love.graphics.push()
	love.graphics.setColor(unpack(self.text_color))
	if r ~= 0 and r ~= Utils.TWO_PI then
		love.graphics.translate(px, py)
		love.graphics.rotate(r)
		love.graphics.translate(-px, -py)
	end
	love.graphics.draw(self.__text, x, y, nil, sx, sy)

	if self._debug then
		local textw, texth = self:getGlobalScaledDimensions()
		love.graphics.setColor(unpack(Utils.UI_COLORS.DEBUG_WHITE))
		if self.horizontal_align == "left" then
			love.graphics.rectangle("line", x, y, textw, texth)
		elseif self.horizontal_align == "right" then
			love.graphics.rectangle("line", x + w - textw, y, textw, texth)
		elseif self.horizontal_align == "center" then
			love.graphics.rectangle("line", x + (w - textw)*0.5, y, textw, texth)
		elseif self.horizontal_align == "justify" then
			love.graphics.rectangle("line", x, y, w, texth)
		end
	end
	love.graphics.pop()
end


return Text