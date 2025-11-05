local Widget = require "ui.widgets.widget"
local Text = require "ui.widgets.text"
local Fonts = require "ui.fonts"
local utf8 = require "utf8"
local Utils = require "ui.utils"
local addHoverState = require "ui.components".addHoverState


local cursor_blinking, cursor_blinking_timer = true, 0
local cursor_blinking_duration, cursor_blinking_duration_half = 1, 0.5


--[[data: 此处不包括当前Widget继承的基类所支持的字段
	height_adaptive = boolean 是否自动调节高度以适应文本高度
	min_height = number
	bg = Widget 背景Widget，将自动保持其尺寸与文本输入框的尺寸一致
	hint = string
	hint_color = {r, g, b, a}

	font_key = string
	font_size = number
	text_color = {r, g, b, a}
	h_align = string "left"|"right"|"center"|"justify"
	v_align = string "top"|"bottom"|"center"

	text_padding = {left, right, top, bottom}
]]
local TextInput = Class(Widget, function(self, datas, theme)
	datas = datas or {}
	Widget.new(self, "TextInput", datas, theme)

	self.height_adaptive = datas.height_adaptive == true
	self.min_height = datas.min_height or datas.h or 75

	if datas.bg then
		self.bg = self:addChild(datas.bg)
		self.bg.transform:setAnchors(0, 0, 1, 1)
		self.bg.transform:setPadding(0, 0, 0, 0)
	end

	self.sections = {""}--array<string> 由用户主动换行产生的段落，该信息主要用于计算光标位置
	self.cursor = {
		show = false,
		section = 1,--正在编辑的段落
		index = 1,--在当前的段落中的索引位置
		_local_pos_cache = {0, 0}--相对本地坐标系的坐标（左上角为文本的原点，考虑padding）
	}

	self.text = self:addChild(Text({
		anchors = {0, 0, 1, 1},
		padding = datas.text_padding or self.theme.textinput.text_padding or {0, 0, 0, 0},
		font_key = datas.font_key or self.theme.textinput.font_key,
		font_size = datas.font_size or self.theme.textinput.font_size,
		text_color = datas.text_color or self.theme.textinput.text_color,
		h_align = datas.h_align,
		v_align = datas.v_align,
	}))
	if datas.hint then
		self.hint = self:addChild(Text({
			text = datas.hint,
			text_color = datas.hint_color or self.theme.textinput.hint_color,
			anchors = {0, 0, 1, 1},
			padding = datas.text_padding or {0, 0, 0, 0},
		}))
	end

	addHoverState(self)
end)


--------------------------------------------------
---@region Text
--------------------------------------------------

function TextInput:getText()
	return self.text:getText(true)
end

function TextInput:setTextColor(r, g, b, a)
	self.text:setTextColor(r, g, b, a)
end

function TextInput:getTextColor()
	return self.text:getTextColor()
end

---@param font_key string 所有字体都需要先存入ui.fonts.lua里，再通过key使用。
function TextInput:setFont(font_key, size)
	self.text:setFont(font_key, size)
end

function TextInput:getFont(return_key)
	return self.text:getFont(return_key)
end

function TextInput:setFontSize(size)
	return self.text:setFontSize(size)
end

function TextInput:getFontSize()
	return self.text:getFontSize()
end

--- 设置水平方向的对齐方式
---@param align "left"|"right"|"center"|"justify"
function TextInput:setHAlign(align)
	return self.text:setHAlign(align)
end

--- 设置垂直方向的对齐方式
---@param align "top"|"bottom"|"center"
function TextInput:setVAlign(align)
	return self.text:setVAlign(align)
end

--- 将当前sections里的文本同步到字体组件里
function TextInput:flushText()
	self.text:setText(table.concat(self.sections, "\n"))
end


--------------------------------------------------
---@region Hint
--------------------------------------------------

function TextInput:refreashHint()
	if not self.hint then
		return
	end
	local text = self.text:getText()
	if not text or text == "" then
		self.hint:show()
	else
		self.hint:hide()
	end
end


--------------------------------------------------
---@region Height
--------------------------------------------------

function TextInput:refreashHeight()
	local _, text_h = self.text:getScaledSize()
	text_h = math.max(self.min_height, text_h)
	local w, h = self.transform:getSize()
	if h ~= text_h then
		self.transform:setSize(w, text_h)
	end
end


--------------------------------------------------
---@region Cursor
--------------------------------------------------

function TextInput:showCursor(show)
	if show then
		self.cursor.show = true
	else
		self.cursor.show = false
	end
end

--- 调用之前需要确保已经调用过flushText()
function TextInput:setCursorIndex(index)
	if not index then
		return
	end

	local text = self.sections[self.cursor.section]
	self.cursor.index = math.max(0, math.min(#text + 1, index))--clamp
	--TODO
	text = table.concat(self.sections, "\n")
	if not text or text == "" then
		self.cursor._local_pos_cache[1] = 0
		self.cursor._local_pos_cache[2] = 0
	else
		for i, section in ipairs(self.sections) do
			if i >= self.cursor.section then
				break
			end
			index = index + #section + 1
		end
		local font = self.text:getFont()
		local maxw, wrappedtext = font:getWrap(text, self.text.transform.w)
		local line = 1
		for l, s in ipairs(wrappedtext) do
			local len = #s
			print("line:", l, len, index)
			line = l
			if len+1 > index then
				break
			elseif len+1 == index then
				index = index + 1
				break
			end
			index = index - len
		end
		local line_height = font:getHeight() * font:getLineHeight()
		self.cursor._local_pos_cache[2] = line_height * (line - 1)
		print(line, index, #wrappedtext[line])
		self.cursor._local_pos_cache[1] = font:getWidth(string.sub(wrappedtext[line], 1, index-1))
	end

	cursor_blinking_timer = 0
end

function TextInput:setCursorPosByScreenPos(screen_x, screen_y)
	local local_x, local_y = self.text.transform:screenToLocal(screen_x, screen_y)
	local font = self.text:getFont()
	local text = self.text:getText(true)
	local maxw, wrappedtext = font:getWrap(text, self.text.transform.w)
	local line_height = font:getHeight() * font:getLineHeight()
	local line = math.max(math.min(math.ceil(local_y/line_height), #wrappedtext), 1)
	local line_text = wrappedtext[line]
	local final_x = 0
	local final_line_idx = 1
	if line_text then
		for pos, code in utf8.codes(line_text) do
			local len = font:getWidth(string.sub(line_text, 1, pos - 1))
			if len >= local_x then
				if len - final_x > (len - local_x) * 2 then
					final_x = len
					final_line_idx = pos
				end
				break
			end
			final_x = len
			final_line_idx = pos
		end
		local len = font:getWidth(line_text)
		if len >= local_x then
			if len - final_x > (len - local_x) * 2 then
				final_x = len
				final_line_idx = #line_text+1
			end
		else
			final_x = len
			final_line_idx = #line_text+1
		end
	end
	for l, s in ipairs(wrappedtext) do
		if l >= line then
			break
		end
		final_line_idx = final_line_idx + #s
	end
	self.cursor.index = final_line_idx
	self.cursor._local_pos_cache[1] = final_x
	self.cursor._local_pos_cache[2] = line_height * (line - 1)

	cursor_blinking_timer = 0
end

function TextInput:moveCursorLeft()
	local cur_section = self.cursor.section
	local new_idx = self.cursor.index - 1
	if new_idx > 0 then
		local text = self.sections[cur_section]
		local first_text = string.sub(text, 1, new_idx)
		local byteoffset = utf8.offset(first_text, -1)
		self:setCursorIndex(byteoffset)
	else
		local new_section = self:ToLastSection()
		if new_section ~= cur_section then
			self:setCursorIndex(#self.sections[new_section])
		end
	end
end

function TextInput:moveCursorRight()
	local cur_section = self.cursor.section
	local new_idx = self.cursor.index + 1
	local text = self.sections[cur_section]
	if new_idx < #text then
		local second_text = string.sub(text, new_idx)
		local byteoffset = utf8.offset(second_text, 2)
		self:setCursorIndex(new_idx + byteoffset)
	else
		local new_section = self:ToNextSection()
		if new_section ~= cur_section then
			self:setCursorIndex(1)
		end
	end
end


--------------------------------------------------
---@region Section
--------------------------------------------------

function TextInput:AppendNewSection()
	table.insert(self.sections, "")
	return #self.sections
end

function TextInput:ToNextSection()
	self.cursor.section = math.min(#self.sections, self.cursor.section + 1)
	return self.cursor.section
end

function TextInput:ToLastSection()
	self.cursor.section = math.max(1, self.cursor.section - 1)
	return self.cursor.section
end


--------------------------------------------------
---@region Event Handlers
--------------------------------------------------


function TextInput:onKeyPressed(key, isrepeat)
	if key == "backspace" then
		local old_text = self.text:getText(true)
		local old_idx = self.cursor.index
		local first_text = string.sub(old_text, 1, old_idx - 1)
        local byteoffset = utf8.offset(first_text, -1)
		first_text = string.sub(first_text, 1, byteoffset - 1)
		local new_text = first_text .. string.sub(old_text, old_idx)
		self.text:setText(new_text)
		if self.height_adaptive then
			self:refreashHeight()
		end
		self:refreashHint()
	elseif key == "kpenter" or key == "return" then
		self:AppendNewSection()
		self:ToNextSection()
	elseif key == "left" then
		self:moveCursorLeft()
	elseif key == "right" then
		self:moveCursorRight()
	elseif key == "up" then

	elseif key == "down" then

	end
end

function TextInput:onTextInput(text)
	if not self:isFocus() then
		return
	end
	local old_idx = self.cursor.index
	local old_text = self.sections[self.cursor.section]
	local len = #old_text
	if len > old_idx then
		old_text= table.concat({string.sub(old_text, 1, old_idx - 1), text, string.sub(old_text, old_idx)})
	else
		old_text = old_text .. text
	end
	self.sections[self.cursor.section] = old_text
	self:flushText()
	self:setCursorIndex(old_idx + #text)
	if self.height_adaptive then
		self:refreashHeight()
	end
	self:refreashHint()
end

function TextInput:onFocus()
	self:showCursor(true)
end

function TextInput:onRemoveFocus()
	self:showCursor(false)
end

function TextInput:onMousePressed(x, y, button)
	if button ~= 1 then
		return
	end
	local is_in_scope = self:regionDetection(x, y)
	local is_focus = self:isFocus()
	if is_in_scope then
		self:setCursorPosByScreenPos(x, y)
		if not is_focus then
			self:setFocus()
			return
		end
	end
	if not is_in_scope and is_focus then
		self:removeFocus()
		self:onHovered(is_in_scope, x, y)
	end
end

function TextInput:onHovered(hovered, x, y, dx, dy)
	if not self.bg or self:isFocus() then
		return
	end
	if hovered then
	else
	end
	if self.bg.onHovered then
		self.bg:onHovered(hovered, x, y, dx, dy)
	end
end

function TextInput:onUpdate(dt)
	-- 光标闪烁计时器
	cursor_blinking_timer = cursor_blinking_timer + dt
	if cursor_blinking_timer > cursor_blinking_duration then
		cursor_blinking_timer = cursor_blinking_timer - cursor_blinking_duration
	end
	if cursor_blinking_timer < cursor_blinking_duration_half then
		cursor_blinking = true
	else
		cursor_blinking = false
	end
end


function TextInput:onPostDraw()
	if self.cursor.show and cursor_blinking then
		--绘制光标
		local org_x, org_y, w, h, r = self.text.transform:getGlobalBounds()
		local top_x, top_y = org_x + self.cursor._local_pos_cache[1], org_y + self.cursor._local_pos_cache[2]
		local bottom_y = top_y + self.text:getFont():getHeight()

		love.graphics.push()
			if r ~= 0 and r ~= Utils.TWO_PI then
				local px, py = self.text.transform:getGlobalPosition()
				love.graphics.translate(px, py)
				love.graphics.rotate(r)
				love.graphics.translate(-px, -py)
			end
			love.graphics.setColor(1, 1, 1, 1)
			love.graphics.setLineWidth(1)
			love.graphics.line(top_x, top_y, top_x, bottom_y)
		love.graphics.pop()
	end
end


return TextInput