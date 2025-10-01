local Widget = require "ui.widgets.widget"
local Utils = require "ui.utils"
local Fonts = require "ui.fonts"


local Text = Class(Widget, function(self, text)
	Widget.new(self, "Text")

	self.font_key = "default"
	self.font_size = 16

	self.text = text or ""
	self.text_color = Utils.RGB(255, 255, 255)
	self.horizontal_align = "left"	--"left"|"right"|"center"|"justify"
	self.vertical_align = "center"	--"top"|"bottom"|"center"
	self.max_width = love.graphics.getWidth()
end)


function Text:SetText(text)
	if type(text) == "string" then
		self.text = tostring(text)
	else
		self.text = text
	end
end


function Text:SetTextColor(r, g, b)
	if type(r) == "table" then
		self.text_color = r
	else
		self.text_color = Utils.RGB(r, g, b)
	end
end


--- 设置字体
---@param font_key string 所有字体都需要先存入ui.fonts.lua里，再通过key使用。
function Text:SetFont(font_key, size)
	if font_key and Fonts[font_key] then
		local font = Fonts:GetFont(font_key, size)
		if not font then
			print("Text:SetFont|Unregistered fonts: "..tostring(font_key))
			return
		end
		self.font_key = font_key
		self.font_size = size
	end
end

--- 设置水平方向的对齐方式
---@param align "left"|"right"|"center"|"justify"
function Text:SetHAlign(align)
	self.horizontal_align = align
end

--- 设置垂直方向的对齐方式
---@param align "top"|"bottom"|"center"
function Text:SetVAlign(align)
	self.vertical_align = align
end

function Text:SetMaxWidth(limit)
	if type(limit) ~= "number" or limit < 0 then
		return
	end
	self.max_width = limit
end

function Text:GetMaxWidth()
	return self.max_width
end


function Text:GetTextWidth()
	return Fonts:GetFont(self.font_key, self.font_size):getWidth(self.text)
end

function Text:GetSize()--覆写Widget的GetSize
	local font = Fonts:GetFont(self.font_key, self.font_size)
	if not font then
		return 0, 0
	end
	local width, wrappedtext = font:getWrap(self.text, self.max_width)
	return width, font:getHeight() * font:getLineHeight() * #wrappedtext
end

function Text:SetSize()--屏蔽该接口
end

function Text:GetTextSize()
	return self.font_size
end

function Text:SetTextSize(size)
	assert(type(size) == "number", "Text:SetTextSize|Parameter 'size' is not a number")
	if self.font_size == size then
		return
	end
	print("Text:SetTextSize", size)
	self.font_size = size
end


function Text:OnDraw()
	local x, y = self:GetGlobalPosition()
	local sx, sy = self:GetGlobalScale()
	local rot = self:GetGlobalRotation()
	local font = Fonts:GetFont(self.font_key, self.font_size)
	love.graphics.setColor(unpack(self.text_color))
	love.graphics.printf(self.text, font, x, y, self.max_width, self.horizontal_align, rot, sx, sy)

	if self._debug then
		local debug_font = Fonts:GetFont("default", 12)
		love.graphics.setColor(unpack(Utils.debug_color1))
		local w, h = self:GetGlobalScaledSize()
		love.graphics.rectangle("line", x, y, self.max_width, h)
		love.graphics.setColor(unpack(Utils.debug_color2))
		if self.horizontal_align == "left" then
			love.graphics.rectangle("line", x, y, w, h)
		elseif self.horizontal_align == "right" then
			love.graphics.rectangle("line", x+self.max_width-w, y, w, h)
		elseif self.horizontal_align == "center" then
			love.graphics.rectangle("line", x+(self.max_width-w)*0.5, y, w, h)
		elseif self.horizontal_align == "justify" then
			love.graphics.rectangle("line", x, y, self.max_width, h)
		end
		love.graphics.printf(string.format("Size: %d\nH Align: %s", self:GetTextSize(), self.horizontal_align), debug_font, x, y+h, self.max_width, "left")
	end
end


return Text