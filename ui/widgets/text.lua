local Widget = require "ui.widgets.widget"
local Utils = require "ui.utils"
local Fonts = require "ui.fonts"
local utf8 = require "utf8"
local Class = require "dependencies.classic"


--尝试使用自定义的自动换行方法，但是没有成功...
local function _getWrap_char(font, str, limit)
    --该函数的效率是Font:getWrap的10% ~ 50%，字符串越长，效率越低。
    local char_width_cache = {}
    local max_width = 0
    local line_start = 1
    local linew = 0
    local line_ranges = {}
    for pos, code in utf8.codes(str) do
        if code == 10 then-- 遇到换行符，强制结束当前行（不包含换行符本身）
            max_width = math.max(max_width, linew)
            if line_start <= pos - 1 then
                table.insert(line_ranges, {line_start, pos - 1})
            else
                table.insert(line_ranges, {pos, pos - 1})-- 处理连续换行符的情况（如空行）
            end
            line_start = pos + 1
            linew = 0
            goto continue
        end

        local char = utf8.char(code)
        local cw = char_width_cache[char] or font:getWidth(char)
        if not char_width_cache[char] then
            char_width_cache[char] = cw
        end
        local neww = linew + cw
        if neww > limit then
            max_width = math.max(max_width, linew)
            table.insert(line_ranges, {line_start, pos - 1})
            line_start = pos
            linew = cw
        else
            linew = neww
        end

        ::continue::
    end
    if line_start <= #str then
        table.insert(line_ranges, {line_start, #str})
        max_width = math.max(max_width, linew)
    end

    local wrappedtext = {}
    for _, range in ipairs(line_ranges) do
        table.insert(wrappedtext, string.sub(str, range[1], range[2]))
    end
    return max_width, wrappedtext
end

--TODO: 设置文本溢出行为
--如果没看到创建出来的文本，请检查是否设置了该 UI 的尺寸。
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

	self.font_key = datas and datas.font_key or self.theme.text.font_key
	self.font_size = datas and datas.font_size or self.theme.text.font_size
	self.text_color = datas and datas.text_color or self.theme.text.text_color--当text是一个coloredtext时，该属性将会和文本的颜色组合（相乘）

	self.text = datas and datas.text or ""--也支持coloredtext：一个包含颜色和字符串的表格，这些颜色和字符串将添加到该对象中，格式为 {color1, string1, color2, string2, ...}。

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

function Text:updateTextLayout()
	self.__text:clear()
	if self.wrap_mode == Utils.TEXT_WRAP_MODE.OFF then
		local width = self.__text:getFont():getWidth(self:getText(true))
		self.__text:setf(self.text, width, self.horizontal_align)
	else
		self.__text:setf(self.text, self.transform.w, self.horizontal_align)
		-- local font = self.__text:getFont()
		-- local lineh = font:getHeight() * font:getLineHeight()
		-- if type(self.text) == "string" then
		-- 	local w, wrappedtext = _getWrap_char(font, self.text, self.transform.w)
		-- 	local newt = table.concat(wrappedtext, "\n")
		-- 	self.__text:setf(newt, self.transform.w, self.horizontal_align)
		-- else
		-- 	self.__text:setf(self.text, self.transform.w, self.horizontal_align)
		-- end
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
		y = y + (h - texth) * 0.5
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
		x = x + (w - textw) * 0.5
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