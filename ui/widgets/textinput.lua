local Widget = require "ui.widgets.widget"
local Text = require "ui.widgets.text"
local utf8 = require "utf8"
local Utils = require "ui.utils"
local addHoverState = require "ui.components".addHoverState


local cursor_blinking_duration, cursor_blinking_duration_half = 1, 0.5


---使用utf8字符的下标来分割文本
---@param text string
---@param pos integer 注意是基于utf8字符的下标，而不是普通字符的下标
---@param mode "first"|"second"|"both"
local function splitText(text, pos, mode)
	local byteoffset = utf8.offset(text, pos)
	if mode == "first" then
		local first_text = string.sub(text, 1, byteoffset - 1)
		return first_text
	elseif mode == "second" then
		local second_text = string.sub(text, byteoffset)
		return second_text
	else
		local first_text = string.sub(text, 1, byteoffset - 1)
		local second_text = string.sub(text, byteoffset)
		return first_text, second_text
	end
end

local function getNearestIndex(text, target_x, font)
	local last_delta = math.huge
	local count = 0--距离最近的字符的索引
	local is_break = false
	for pos, code in utf8.codes(text) do
		local temp_text = string.sub(text, 1, pos-1)
		local delta = math.abs(font:getWidth(temp_text) - target_x)
		if last_delta > delta then
			last_delta = delta
		else
			is_break = true
			break
		end
		count = count + 1
	end
	if not is_break then--处理光标位于行尾的情况
		local delta = math.abs(font:getWidth(text) - target_x)
		if last_delta > delta then
			last_delta = delta
			count = count + 1
		end
	end
	return count
end


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
	text = string
]]
local TextInput = Class(Widget, function(self, datas, theme)
	datas = datas or {}
	Widget.new(self, "TextInput", datas, theme)

	self.height_adaptive = datas.height_adaptive == true
	self.min_height = datas.min_height or datas.h or 75

	if datas.bg then
		self.bg = self:addChild(datas.bg)
		self.bg.transform:setAnchor(0, 0, 1, 1)
		self.bg.transform:setPadding(0, 0, 0, 0)
	end

	self.sections = {""}--array<string> 由用户主动换行产生的段落，该信息主要用于计算光标位置
	self.cursor = {
		show = false,
		section = 1,--正在编辑的段落
		index = 1,--在当前的段落中的开始索引位置(基于utf8)
		head_or_tail = true,--当光标位于自动换行的位置时，光标显示在上一行的末尾还是下一行的开始，true表示显示在下一行的开始
		_local_pos_cache = {0, 0},--相对本地坐标系的坐标（左上角为文本的原点，考虑padding）
	}
	self.cursor_blinking = true
	self.cursor_blinking_timer = 0

	self.text = self:addChild(Text({
		anchor = {0, 0, 1, 1},
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
			anchor = {0, 0, 1, 1},
			padding = datas.text_padding or {0, 0, 0, 0},
		}))
	end

	addHoverState(self)
	if datas.text then
		self:setText(datas.text)
	end
end)


--------------------------------------------------
---@region Text
--------------------------------------------------

local function split_by_newline(str)
    local lines = {}
    for line in string.gmatch(str .. "\n", "(.-)\r?\n") do
        table.insert(lines, line)
    end
    return lines
end
--- 设置文本，会覆盖当前的文本。注意设置文本后是否需要更新光标位置
---@param text string
function TextInput:setText(text)
	self.sections = split_by_newline(text)
	self:flushText()
	self:refreshHint()
	if self.height_adaptive then
		self:refreshHeight()
	end
end

function TextInput:getText()
	return self.text:getText(true)
end

---@param color table 颜色表 {r, g, b, a}，各分量 0~1
function TextInput:setTextColor(color)
	self.text:setTextColor(color)
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

function TextInput:refreshHint()
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

function TextInput:refreshHeight()
	local _, text_h = self.text:getScaledSize()
	text_h = math.max(self.min_height, text_h)
	local w, h = self.transform:getSize()
	if h ~= text_h then
		local text_padding = self.text.transform:getPadding()
		self.transform:setSize(w, text_h + text_padding.top + text_padding.bottom)
	end
end


--------------------------------------------------
---@region Cursor
--------------------------------------------------

function TextInput:showCursor(show)
	if show then
		self.cursor.show = true
		self.cursor_blinking_timer = 0
	else
		self.cursor.show = false
	end
end

function TextInput:setCursorIndex(index)
	index = index or self.cursor.index
	local text = self.sections[self.cursor.section]
	index = math.max(1, math.min(utf8.len(text) + 1, index))--clamp
	self.cursor.index = index
	--计算光标的坐标
	text = table.concat(self.sections, "\n")
	if not text or text == "" then
		self.cursor._local_pos_cache[1] = 0
		self.cursor._local_pos_cache[2] = 0
	else
		local font = self.text:getFont()
		local line = 0
		for i, section in ipairs(self.sections) do
			local _, wrappedtext = font:getWrap(section, self.text.transform.w)
			if i < self.cursor.section then
				line = line + #wrappedtext
			else
				for l, s in ipairs(wrappedtext) do
					local len = utf8.len(s)
					line = line + 1
					if len + 1 > index then
						self.cursor._local_pos_cache[1] = font:getWidth(string.sub(wrappedtext[l], 1, utf8.offset(wrappedtext[l], index) - 1))
						break
					elseif len + 1 == index then
						if self.cursor.head_or_tail and l < #wrappedtext then
							self.cursor._local_pos_cache[1] = 0
							line = line + 1
						else
							self.cursor._local_pos_cache[1] = font:getWidth(wrappedtext[l])
						end
						break
					end
					index = index - len
				end
				break
			end
		end
		local line_height = font:getHeight() * font:getLineHeight()
		self.cursor._local_pos_cache[2] = line_height * (line - 1)
	end

	self.cursor_blinking_timer = 0
end

---这是根据self.text:getText() 计算的坐标，因此需要保证调用之前self.text的文本是最新的
function TextInput:setCursorPosByScreenPos(screen_x, screen_y)
	local local_x, local_y = self.text.transform:screenToLocal(screen_x, screen_y)
	local font = self.text:getFont()
	local text = table.concat(self.sections, "\n")
	local maxw, wrappedtext = font:getWrap(text, self.text.transform.w)
	local line_height = font:getHeight() * font:getLineHeight()
	local line = math.max(math.min(math.ceil(local_y/line_height), #wrappedtext), 1)

	local _len = 0
	for l, s in ipairs(wrappedtext) do
		_len = _len + #s
		if l >= line then
			break
		end
	end
	local target_section = 1
	local temp_lines = line--用于存储target_section里占据的行数
	for i, section in ipairs(self.sections) do
		local _, _wrappedtext = font:getWrap(section, self.text.transform.w)
		_len = _len - #section
		if _len <= 0 then
			target_section = i
			break
		end
		temp_lines = temp_lines - #_wrappedtext
	end
	self.cursor.section = target_section

	local target_index = 0
	local target_x = 0
	local _, wrappedtext = font:getWrap(self.sections[target_section], self.text.transform.w)
	for l, s in ipairs(wrappedtext) do
		if l >= temp_lines then
			local count = getNearestIndex(s, local_x, font)
			local byteoffset = utf8.offset(s, count)
			target_x = font:getWidth(string.sub(s, 1, byteoffset - 1))
			target_index = target_index + count
			break
		end
		target_index = target_index + utf8.len(s)
	end

	self.cursor.index = target_index
	self.cursor._local_pos_cache[1] = target_x
	self.cursor._local_pos_cache[2] = line_height * (line - 1)
	if target_x == 0 then
		self.cursor.head_or_tail = true
	end
	self.cursor_blinking_timer = 0
end

function TextInput:moveCursorLeft()
	local old_section = self.cursor.section
	local new_idx = self.cursor.index - 1
	if new_idx < 1 then
		local new_section = self:toLastSection()
		if new_section ~= old_section then
			new_idx = utf8.len(self.sections[new_section]) + 1
		else
			new_idx = 1
		end
	end
	self.cursor.head_or_tail = true
	self:setCursorIndex(new_idx)
end

function TextInput:moveCursorRight()
	local old_section = self.cursor.section
	local new_idx = self.cursor.index + 1
	local text = self.sections[old_section]
	local text_max_len = utf8.len(text)
	if new_idx > text_max_len + 1 then
		local new_section = self:toNextSection(1)
		if new_section ~= old_section then
			return
		else
			new_idx = text_max_len + 1
		end
	end
	self.cursor.head_or_tail = false
	self:setCursorIndex(new_idx)
end


local function findLineByIndex(wrappedtext, index, head_or_tail)
	local len = 0
	local total_line = #wrappedtext
	for l, s in ipairs(wrappedtext) do
		local cur_line_len = utf8.len(s)
		local _len = len + cur_line_len
		if _len + 1 > index then
			return l, cur_line_len, len
		elseif _len + 1 == index then
			if l < total_line and head_or_tail then
				return l + 1, utf8.len(wrappedtext[l + 1]), _len
			else
				return l, cur_line_len, len
			end
		end
		len = _len
	end
end

function TextInput:moveCursorUp()
	local old_section = self.cursor.section
	local old_idx = self.cursor.index
	local font = self.text:getFont()
	local _, wrappedtext = font:getWrap(self.sections[old_section], self.text.transform.w)
	local lines = #wrappedtext
	local x_cache = self.cursor._local_pos_cache[1]
	local move_to_last_section = false
	if lines > 1 then
		local line, cur_line_len, len = findLineByIndex(wrappedtext, old_idx, self.cursor.head_or_tail)
		if line == 1 then
			move_to_last_section = true
		else--移动到当前段落里的上一行
			local last_line_text = wrappedtext[line-1]
			local count = getNearestIndex(last_line_text, x_cache, font)
			self:setCursorIndex(len - utf8.len(last_line_text) + count)
		end
	else
		move_to_last_section = true
	end

	if move_to_last_section and old_section > 1 then--移动到上一段落里的最后一行
		local _, wrappedtext = font:getWrap(self.sections[old_section - 1], self.text.transform.w)
		local last_line_text = wrappedtext[#wrappedtext]
		local count = getNearestIndex(last_line_text, x_cache, font)
		local len = utf8.len(self.sections[old_section - 1])
		self:toLastSection(len - utf8.len(last_line_text) + count)
	end
end

function TextInput:moveCursorDown()
	local old_section = self.cursor.section
	local old_idx = self.cursor.index
	local font = self.text:getFont()
	local _, wrappedtext = font:getWrap(self.sections[old_section], self.text.transform.w)
	local lines = #wrappedtext
	local x_cache = self.cursor._local_pos_cache[1]
	local move_to_next_section = false
	if lines > 1 then
		local line, cur_line_len, len = findLineByIndex(wrappedtext, old_idx, self.cursor.head_or_tail)
		if line == #wrappedtext then
			move_to_next_section = true
		else--移动到当前段落里的下一行
			local count = getNearestIndex(wrappedtext[line + 1], x_cache, font)
			self:setCursorIndex(len + cur_line_len + count)
		end
	else
		move_to_next_section = true
	end

	if move_to_next_section and old_section < #self.sections then--移动到下一段落里的第一行
		local _, wrappedtext = font:getWrap(self.sections[old_section + 1], self.text.transform.w)
		local count = getNearestIndex(wrappedtext[1], x_cache, font)
		self:toNextSection(count)
	end
end

function TextInput:moveCursorToHead()
	local old_section = self.cursor.section
	local old_idx = self.cursor.index
	if old_idx <= 1 then
		return
	end
	local font = self.text:getFont()
	local _, wrappedtext = font:getWrap(self.sections[old_section], self.text.transform.w)
	local line, cur_line_len, len = findLineByIndex(wrappedtext, old_idx, self.cursor.head_or_tail)
	self.cursor.head_or_tail = true
	self:setCursorIndex(len + 1)
end

function TextInput:moveCursorToEnd()
	local old_section = self.cursor.section
	local old_idx = self.cursor.index
	local font = self.text:getFont()
	local _, wrappedtext = font:getWrap(self.sections[old_section], self.text.transform.w)
	local line, cur_line_len, len = findLineByIndex(wrappedtext, old_idx, self.cursor.head_or_tail)
	self.cursor.head_or_tail = false
	self:setCursorIndex(len + cur_line_len + 1)
end

--------------------------------------------------
---@region Special Input
--------------------------------------------------

function TextInput:lineBreak()
	local old_section = self.cursor.section
	local old_text = self.sections[old_section]
	local old_idx = self.cursor.index
	local first_text, second_text = splitText(old_text, old_idx, "both")
	self.sections[old_section] = first_text
	self:insertNewSection(self.cursor.section+1, second_text)
	self:toNextSection(1)
	self:flushText()
	if self.height_adaptive then
		self:refreshHeight()
	end
end

function TextInput:backspace()
	local old_section = self.cursor.section
	local old_idx = self.cursor.index
	if old_section == 1 and old_idx == 1 then
		return
	end

	local old_text = self.sections[old_section]
	local first_text, second_text = splitText(old_text, old_idx, "both")

	if old_idx == 1 then--将当前段落加入上一个段落
		local last_section = self.sections[old_section - 1]
		if second_text ~= "" then
			self.sections[old_section - 1] = last_section .. second_text
		end
		self:removeSection(old_section)
		self:toLastSection(utf8.len(last_section) + 1)
	else--删除本段落当前index的前一个字符
		first_text = splitText(first_text, -1, "first")
		self.sections[old_section] = first_text .. second_text
		self:setCursorIndex(old_idx - 1)
	end

	self:flushText()
	if self.height_adaptive then
		self:refreshHeight()
	end
	self:refreshHint()
end

function TextInput:delete()
	local old_section = self.cursor.section
	local old_idx = self.cursor.index
	local old_text = self.sections[old_section]
	local old_text_len = utf8.len(old_text)
	if old_section == #self.sections and old_idx == old_text_len + 1 then
		return
	end

	local first_text, second_text = splitText(old_text, old_idx, "both")

	if old_idx == old_text_len + 1 then--将下一段落加入当前段落
		local next_section = self.sections[old_section + 1]
		if next_section ~= "" then
			self.sections[old_section] = old_text .. next_section
		end
		self:removeSection(old_section + 1)
	else--删除本段落当前index的字符
		second_text = splitText(second_text, 2, "second")
		self.sections[old_section] = first_text .. second_text
	end

	self:flushText()
	if self.height_adaptive then
		self:refreshHeight()
	end
	self:refreshHint()
end


--------------------------------------------------
---@region Section
--------------------------------------------------

function TextInput:appendNewSection()
	table.insert(self.sections, "")
	return #self.sections
end

--- 注意插入之后是否需要更新self.cursor.section
---@param pos integer
---@param section string|nil
function TextInput:insertNewSection(pos, section)
	pos = math.max(1, math.min(#self.sections + 1, pos))
	table.insert(self.sections, pos, section or "")
	return pos
end

--- 注意移除之后是否需要更新self.cursor.section
---@param pos integer
function TextInput:removeSection(pos)
	table.remove(self.sections, pos)
	if #self.sections == 0 then
		self:appendNewSection()
	end
end

function TextInput:toNextSection(index)
	local old_section = self.cursor.section
	local new_section = math.min(#self.sections, self.cursor.section + 1)
	if old_section ~= new_section then
		self.cursor.section = new_section
		self:setCursorIndex(index or self.cursor.index)
	end
	return new_section
end

function TextInput:toLastSection(index)
	local old_section = self.cursor.section
	local new_section = math.max(1, self.cursor.section - 1)
	if old_section ~= new_section then
		self.cursor.section = new_section
		self:setCursorIndex(index or self.cursor.index)
	end
	return new_section
end


--------------------------------------------------
---@region Select Text
--------------------------------------------------

function TextInput:selectText(start_index, end_index)
	
end

function TextInput:selectAll()
	
end


--------------------------------------------------
---@region Copy & Paste
--------------------------------------------------

function TextInput:copy()
	--TODO
end

function TextInput:paste()
	--TODO
end


--------------------------------------------------
---@region Event Handlers
--------------------------------------------------

local function isCtrlPressed()
	return love.keyboard.isDown("rctrl", "lctrl")
end
local KEY_MAP = {
	backspace = function(self) self:backspace() end,
	delete = function(self) self:delete() end,
	kpenter = function(self) self:lineBreak() end,
	["return"] = function(self) self:lineBreak() end,
	left = function(self) self:moveCursorLeft() end,
	right = function(self) self:moveCursorRight() end,
	up = function(self) self:moveCursorUp() end,
	down = function(self) self:moveCursorDown() end,
	home = function(self) self:moveCursorToHead() end,
	["end"] = function(self) self:moveCursorToEnd() end,
}
local CTRL_KEY_MAP = {
	a = function(self) self:selectAll() end,
	c = function(self) self:copy() end,
	v = function(self) self:paste() end,
}
function TextInput:onKeyPressed(key, isrepeat)
	local handler
	if isCtrlPressed() then
		handler = CTRL_KEY_MAP[key]
	else
		handler = KEY_MAP[key]
    end
	if handler then
		handler(self)
	end
end

function TextInput:onTextInput(text)
	if not self:isFocus() then
		return
	end
	local old_idx = self.cursor.index
	local old_text = self.sections[self.cursor.section]
	local len = string.len(old_text)
	if len > old_idx then
		local first_text, second_text = splitText(old_text, old_idx, "both")
		old_text = table.concat({first_text, text, second_text})
	else
		old_text = old_text .. text
	end
	self.sections[self.cursor.section] = old_text
	self:flushText()
	self:setCursorIndex(old_idx + utf8.len(text))
	if self.height_adaptive then
		self:refreshHeight()
	end
	self:refreshHint()
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
	if hovered then
		local cursor = love.mouse.getSystemCursor("ibeam")
		love.mouse.setCursor(cursor)
	else
		love.mouse.setCursor()
	end
	if self.bg.onHovered then
		self.bg:onHovered(hovered, x, y, dx, dy)
	end
end

function TextInput:onUpdate(dt)
	-- 光标闪烁计时器
	self.cursor_blinking_timer = self.cursor_blinking_timer + dt
	if self.cursor_blinking_timer > cursor_blinking_duration then
		self.cursor_blinking_timer = self.cursor_blinking_timer - cursor_blinking_duration
	end
	if self.cursor_blinking_timer < cursor_blinking_duration_half then
		self.cursor_blinking = true
	else
		self.cursor_blinking = false
	end
end


function TextInput:onPostDraw()
	if self.cursor.show and self.cursor_blinking then
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