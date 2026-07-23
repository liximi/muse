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

	self.wrap_mode = Utils.TEXT_WRAP_MODE.OFF
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

--- 返回文本自身的最小自然尺寸。
--- 参照 Godot Label::get_minimum_size：
--- - 换行关闭时：返回不换行的完整文本宽度（不可压缩）。
--- - 换行开启时：宽度返回 1（"我可以缩小到几乎任意宽度"），高度返回当前整形后的实际行高。
---   容器据此知道该文本可以压缩，从而在有限空间内触发换行。
function Text:getMinimumSize()
	-- 空文本参照 Godot：返回 (0, 行高)，保证至少有一行高度
	if self.text == "" or self.text == nil then
		local font = self:getFont()
		return 0, font:getHeight() * font:getLineHeight()
	end
	local font = self:getFont()
	local line_h = font:getHeight() * font:getLineHeight()

	if self.wrap_mode == Utils.TEXT_WRAP_MODE.DEFAULT then
		-- 换行开启：参照 Godot，宽度 = 1（可压缩），高度 = 当前整形后的高度
		local _, h = self:getDimensions()
		return 1, math.max(h, line_h)
	else
		-- 不换行：完整文本宽度
		local text = self:getText(true)
		local w = font:getWidth(text)
		return w, line_h
	end
end

--- 文本的期望尺寸。
--- 参照 Godot Label::get_desired_size：
--- - 换行关闭时：等于最小尺寸（完整文本宽度）。
--- - 换行开启时：返回当前整形后的实际尺寸（由容器分配的宽度决定）。
---   容器据此在「第二趟分配」中为文本争取接近实际所需的宽度。
function Text:getDesiredSize()
	if self.wrap_mode == Utils.TEXT_WRAP_MODE.DEFAULT then
		-- 期望尺寸 = 当前整形后的实际尺寸，让容器尽量分配接近所需的宽度
		local w, h = self:getDimensions()
		local font = self:getFont()
		local line_h = font:getHeight() * font:getLineHeight()
		return math.max(w, 1), math.max(h, line_h)
	end
	return self:getMinimumSize()
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

--- 覆写 getGlobalBounds：pivot 偏移使用 transform 尺寸（与 getGlobalPosition 一致），
--- 但返回的 w/h 使用文本实际尺寸。
--- 避免当 transform.w=0（点锚点）时，文本尺寸被 pivot 错误偏移。
function Text:getGlobalBounds()
	local x, y = self.transform:getGlobalPosition()
	local sw, sh = self:getGlobalScaledSize()
	local px, py = self.transform:getPivot()
	local r = self.transform:getGlobalRotation()

	local sx, sy = self:getGlobalScale()
	local tw = self.transform.w * sx
	local th = self.transform.h * sy
	return x - tw * px, y - th * py, sw, sh, r
end

--- 覆写 Widget 的裁剪 AABB，使用文本实际尺寸而非 transform.w/h（后者默认为 0）
--- 避免 Text 在 Scroll 容器中被过早裁剪。
function Text:getCullAABB()
	local x, y, w, h, r = self:getGlobalBounds()

	if r == 0 or r == Utils.TWO_PI then
		return x, y, w, h
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
		-- 换行模式：使用当前控件宽度作为换行宽度。
		-- 若尚未分配宽度（w <= 0），使用完整文本宽度（此时文本不换行），
		-- 避免零宽度整形。容器在下一帧分配实际宽度后会触发 onSizeChanged 重排。
		local wrap_w = self.transform.w
		if wrap_w <= 0 then
			wrap_w = self.__text:getFont():getWidth(self:getText(true))
		end
		self.__text:setf(self.text, wrap_w, self.horizontal_align)
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
