local Widget = require "ui.widgets.widget"
local Utils = require "ui.utils"
local Fonts = require "ui.fonts"
local utf8 = require "utf8"
local Class = require "dependencies.classic"

-- 伪常量
local ALIGN_CENTER = 0.5    -- 居中对齐的偏移系数

-- TODO: 设置文本溢出行为
-- 如果没看到创建出来的文本，请检查是否设置了该 UI 的尺寸。
--[[data: 此处不包括当前Widget继承的基类所支持的字段
	text = string|table(coloredtext)
	font_key = string
	font_size = number
	text_color = {r, g, b, a}
	h_align = string "left"|"right"|"center"|"justify"
	v_align = string "top"|"bottom"|"center"
]]
local Text = Class(Widget, function(self, datas, theme)
	Widget.new(self, "Text", datas, theme)
	self.raycast_target = true

	self.font_key = datas and datas.font_key or self.theme.text.font_key
	self.font_size = datas and datas.font_size or self.theme.text.font_size
	self.text_color = datas and datas.text_color or self.theme.text.text_color -- 当text是一个coloredtext时，该属性将会和文本的颜色组合（相乘）

	self.text = datas and datas.text or "" -- 也支持coloredtext：一个包含颜色和字符串的表格，这些颜色和字符串将添加到该对象中，格式为 {color1, string1, color2, string2, ...}。

	self.wrap_mode = Utils.TEXT_WRAP_MODE.DEFAULT
	self.overflow_mode = Utils.TEXT_OVERFLOW_MODE.NONE
	self.overflow_ellipsis_char = "…"
	self.horizontal_align = Utils.validateEnum(
		datas and datas.h_align, Utils.H_ALIGN, Utils.H_ALIGN.LEFT, "Text.h_align")
	self.vertical_align = Utils.validateEnum(
		datas and datas.v_align, Utils.V_ALIGN, Utils.V_ALIGN.TOP, "Text.v_align")

	self.__text = love.graphics.newText(Fonts:getFont(self.font_key, self.font_size))
	self:updateTextLayout()
	self:enableSizeChangedEvent(true)
end)

-- 也支持coloredtext：一个包含颜色和字符串的表格，这些颜色和字符串将添加到该对象中，格式为 {color1, string1, color2, string2, ...}。
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

---@param color table 颜色表 {r, g, b, a}，各分量 0~1
function Text:setTextColor(color)
	self.text_color = color
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
			print("Text:setFont|Unregistered fonts: " .. tostring(font_key))
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
	-- VAlign 在 onDraw() 中通过 y 偏移实现，无需重建 Text 对象
end

function Text:setWrapMode(wrap_mode)
	self.wrap_mode = wrap_mode
	self:updateTextLayout()
end

function Text:getDimensions()
	local w, h = self.__text:getDimensions()
	return w, h
end

--- 返回文本自身的最小自然尺寸（不换行时的完整尺寸）。
function Text:getMinimumSize()
	if self.text == "" or self.text == nil then
		return 0, 0
	end
	local font = self:getFont()
	local text = self:getText(true)
	local line_h = font:getHeight() * font:getLineHeight()
	-- 取不换行的完整宽度
	local w = font:getWidth(text)
	local h = line_h
	return w, h
end

function Text:getScaledDimensions()
	local w, h = self:getDimensions()
	local sx, sy = self.transform:getScale()
	return w * sx, h * sy
end

function Text:getGlobalScaledDimensions()
	local w, h = self:getDimensions()
	local sx, sy = self:getGlobalScale()
	return w * sx, h * sy
end

function Text:getSize()
	return self:getDimensions()
end

function Text:getScaledSize()
	return self:getScaledDimensions()
end

function Text:getGlobalScaledSize()
	return self:getGlobalScaledDimensions()
end

--- 覆写 Widget 的裁剪 AABB，使用文本实际尺寸而非 transform.w/h（后者默认为 0）
--- 避免 Text 在 Scroll 容器中被过早裁剪
function Text:getCullAABB()
	local x, y = self.transform:getGlobalPosition()
	local w, h = self:getGlobalScaledSize()
	local px, py = self.transform:getPivot()
	local r = self.transform:getGlobalRotation()

	if r == 0 or r == Utils.TWO_PI then
		return x - w * px, y - h * py, w, h
	end
	-- 旋转情况回退到 Transform 计算（少见场景）
	return self.transform:getGlobalAABB()
end

--- 查询文本的自然尺寸：给定宽度约束，返回换行后的 {w, h}
---@param max_w number|nil 可用宽度（nil = 不换行，取最长行宽）
---@param max_h number|nil 可用高度（当前未用于文本测量）
---@return table {w = number, h = number}
function Text:measure(max_w, max_h)
	local font = self:getFont()
	local text = self:getText(true)
	local line_h = font:getHeight() * font:getLineHeight()

	-- 无约束时取不换行的完整宽度
	local wrap_w = max_w or font:getWidth(text)
	local _, wrapped = font:getWrap(text, wrap_w)

	-- 取最长行宽
	local w = 0
	for _, line in ipairs(wrapped) do
		local lw = font:getWidth(line)
		if lw > w then w = lw end
	end
	if max_w then
		w = math.min(w, max_w)
	end

	local h = #wrapped * line_h
	return {w = w, h = h}
end

function Text:updateTextLayout()
	self.__text:clear()
	if self.wrap_mode == Utils.TEXT_WRAP_MODE.OFF then
		local width = self.__text:getFont():getWidth(self:getText(true))
		self.__text:setf(self.text, width, self.horizontal_align)
	else
		self.__text:setf(self.text, self.transform.w, self.horizontal_align)
	end
end

function Text:onSizeChanged(w, h)
	self:updateTextLayout()
end

function Text:onDraw()
	local x, y, w, h, r = self.transform:getGlobalBounds()
	local sx, sy = self:getGlobalScale()
	local textw, texth = self:getGlobalScaledDimensions()

	love.graphics.push()

	if r ~= 0 and r ~= Utils.TWO_PI then
		local px, py = self.transform:getGlobalPosition()
		love.graphics.translate(px, py)
		love.graphics.rotate(r)
		love.graphics.translate(-px, -py)
	end

	love.graphics.setColor(unpack(self.text_color))
	if self.vertical_align == "bottom" then
		y = y + h - texth
	elseif self.vertical_align == "center" then
		y = y + (h - texth) * ALIGN_CENTER
	end
	love.graphics.draw(self.__text, x, y, nil, sx, sy)

	love.graphics.pop()
end

function Text:onDebugDraw()
	local x, y, w, h, r = self.transform:getGlobalBounds()
	local textw, texth = self:getGlobalScaledDimensions()

	love.graphics.push()
	if r ~= 0 and r ~= Utils.TWO_PI then
		local px, py = self.transform:getGlobalPosition()
		love.graphics.translate(px, py)
		love.graphics.rotate(r)
		love.graphics.translate(-px, -py)
	end

	if self.horizontal_align == "right" then
		x = x + w - textw
	elseif self.horizontal_align == "center" then
		x = x + (w - textw) * ALIGN_CENTER
	end
	love.graphics.setColor(unpack(Utils.UI_COLORS.WHITE))
	if self.horizontal_align == "justify" then
		love.graphics.rectangle("line", x, y, w, texth)
	else
		love.graphics.rectangle("line", x, y, textw, texth)
	end

	love.graphics.pop()
end

return Text
