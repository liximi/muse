local Widget = require "ui.widgets.widget"
local Text = require "ui.widgets.text"
local utf8 = require "utf8"
local Utils = require "ui.utils"
local addHoverState = require"ui.components".addHoverState
local Class = require "dependencies.classic"

-- 伪常量
local CURSOR_BLINK_DURATION = 1       -- 光标闪烁周期（秒）
local CURSOR_BLINK_DURATION_HALF = 0.5 -- 光标闪烁半周期（秒）
local DEFAULT_MIN_HEIGHT = 75          -- 自适应高度时的最小高度（像素）
local UNDO_STACK_MAX = 100             -- 撤销栈最大容量
local UNDO_INACTIVITY_THRESHOLD = 0.3  -- 撤销操作组合并停顿阈值（秒）
local SELECTION_COLOR = {0.2, 0.4, 0.8, 0.35} -- 文本选区高亮颜色
local CURSOR_COLOR = {1, 1, 1, 1}     -- 光标颜色
local SKIP_FIRST_CHAR = 2             -- splitText 跳过首字符的偏移

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
	local count = 0 -- 距离最近的字符的索引
	local is_break = false
	for pos, code in utf8.codes(text) do
		local temp_text = string.sub(text, 1, pos - 1)
		local delta = math.abs(font:getWidth(temp_text) - target_x)
		if last_delta > delta then
			last_delta = delta
		else
			is_break = true
			break
		end
		count = count + 1
	end
	if not is_break then -- 处理光标位于行尾的情况
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
	self.min_height = datas.min_height or datas.h or DEFAULT_MIN_HEIGHT

	if datas.bg then
		self.bg = self:addChild(datas.bg)
		self.bg.transform:setAnchor(0, 0, 1, 1)
		self.bg.transform:setPadding(0, 0, 0, 0)
	end

	self.sections = {""} -- array<string> 由用户主动换行产生的段落，该信息主要用于计算光标位置
	self.cursor = {
		show = false,
		section = 1, -- 正在编辑的段落
		index = 1, -- 在当前的段落中的开始索引位置(基于utf8)
		head_or_tail = true, -- 当光标位于自动换行的位置时，光标显示在上一行的末尾还是下一行的开始，true表示显示在下一行的开始
		_local_pos_cache = {0, 0}, -- 相对本地坐标系的坐标（左上角为文本的原点，考虑padding）
		_sel_start = nil, -- 选区起点 {section, index}，nil 表示无选区
		_sel_end = nil -- 选区终点 {section, index}
	}
	self.cursor_blinking = true
	self.cursor_blinking_timer = 0

	self._is_dragging = false

	self._undo_stack = {}
	self._redo_stack = {}
	self._undo_stack_max = UNDO_STACK_MAX
	self._undo_group = nil -- 当前操作组的起点快照
	self._undo_group_type = nil -- "input" | "backspace" | "delete" | nil
	self._undo_inactivity_timer = 0
	self._undo_inactivity_threshold = UNDO_INACTIVITY_THRESHOLD

	self.focusable = true

	self.text = self:addChild(Text({
		anchor = {0, 0, 1, 1},
		padding = datas.text_padding or self.theme.textinput.text_padding or {0, 0, 0, 0},
		font_key = datas.font_key or self.theme.textinput.font_key,
		font_size = datas.font_size or self.theme.textinput.font_size,
		text_color = datas.text_color or self.theme.textinput.text_color,
		h_align = datas.h_align,
		v_align = datas.v_align
	}))
	if datas.hint then
		self.hint = self:addChild(Text({
			text = datas.hint,
			text_color = datas.hint_color or self.theme.textinput.hint_color,
			anchor = {0, 0, 1, 1},
			padding = datas.text_padding or {0, 0, 0, 0}
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
	index = math.max(1, math.min(utf8.len(text) + 1, index)) -- clamp
	self.cursor.index = index
	-- 计算光标的坐标
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
						self.cursor._local_pos_cache[1] = font:getWidth(
							string.sub(wrappedtext[l], 1, utf8.offset(wrappedtext[l], index) - 1))
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
	local line = math.max(math.min(math.ceil(local_y / line_height), #wrappedtext), 1)

	local _len = 0
	for l, s in ipairs(wrappedtext) do
		_len = _len + #s
		if l >= line then
			break
		end
	end
	local target_section = 1
	local temp_lines = line -- 用于存储target_section里占据的行数
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
		else -- 移动到当前段落里的上一行
			local last_line_text = wrappedtext[line - 1]
			local count = getNearestIndex(last_line_text, x_cache, font)
			self:setCursorIndex(len - utf8.len(last_line_text) + count)
		end
	else
		move_to_last_section = true
	end

	if move_to_last_section and old_section > 1 then -- 移动到上一段落里的最后一行
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
		else -- 移动到当前段落里的下一行
			local count = getNearestIndex(wrappedtext[line + 1], x_cache, font)
			self:setCursorIndex(len + cur_line_len + count)
		end
	else
		move_to_next_section = true
	end

	if move_to_next_section and old_section < #self.sections then -- 移动到下一段落里的第一行
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
	self:_saveOneShot()
	local old_section = self.cursor.section
	local old_text = self.sections[old_section]
	local old_idx = self.cursor.index
	local first_text, second_text = splitText(old_text, old_idx, "both")
	self.sections[old_section] = first_text
	self:insertNewSection(self.cursor.section + 1, second_text)
	self:toNextSection(1)
	self:flushText()
	if self.height_adaptive then
		self:refreshHeight()
	end
end

function TextInput:backspace()
	if self:_hasSelection() then
		self:_saveOneShot()
		self:_deleteSelection()
		return
	end
	local old_section = self.cursor.section
	local old_idx = self.cursor.index
	if old_section == 1 and old_idx == 1 then
		return
	end

	self:_preMutation("backspace")

	local old_text = self.sections[old_section]
	local first_text, second_text = splitText(old_text, old_idx, "both")

	if old_idx == 1 then -- 将当前段落加入上一个段落
		local last_section = self.sections[old_section - 1]
		if second_text ~= "" then
			self.sections[old_section - 1] = last_section .. second_text
		end
		self:removeSection(old_section)
		self:toLastSection(utf8.len(last_section) + 1)
	else -- 删除本段落当前index的前一个字符
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
	if self:_hasSelection() then
		self:_saveOneShot()
		self:_deleteSelection()
		return
	end
	local old_section = self.cursor.section
	local old_idx = self.cursor.index
	local old_text = self.sections[old_section]
	local old_text_len = utf8.len(old_text)
	if old_section == #self.sections and old_idx == old_text_len + 1 then
		return
	end

	self:_preMutation("delete")

	local first_text, second_text = splitText(old_text, old_idx, "both")

	if old_idx == old_text_len + 1 then -- 将下一段落加入当前段落
		local next_section = self.sections[old_section + 1]
		if next_section ~= "" then
			self.sections[old_section] = old_text .. next_section
		end
		self:removeSection(old_section + 1)
	else -- 删除本段落当前index的字符
		second_text = splitText(second_text, SKIP_FIRST_CHAR, "second")
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

--------------------------------------------------
---@region Selection Helpers
--------------------------------------------------

--- 比较两个 {section, index} 位置，返回 -1/0/1
function TextInput:_comparePos(s1, i1, s2, i2)
	if s1 ~= s2 then
		return s1 < s2 and -1 or 1
	end
	if i1 == i2 then
		return 0
	end
	return i1 < i2 and -1 or 1
end

function TextInput:_hasSelection()
	local s = self.cursor._sel_start
	local e = self.cursor._sel_end
	if not s or not e then
		return false
	end
	return self:_comparePos(s[1], s[2], e[1], e[2]) ~= 0
end

function TextInput:_clearSelection()
	self.cursor._sel_start = nil
	self.cursor._sel_end = nil
end

--- 返回 start_s, start_i, end_s, end_i（保证 start ≤ end）
function TextInput:_getOrderedSelection()
	local s = self.cursor._sel_start
	local e = self.cursor._sel_end
	if not s or not e then
		return nil
	end
	if self:_comparePos(s[1], s[2], e[1], e[2]) <= 0 then
		return s[1], s[2], e[1], e[2]
	else
		return e[1], e[2], s[1], s[2]
	end
end

function TextInput:_getSelectedText()
	local s_section, s_idx, e_section, e_idx = self:_getOrderedSelection()
	if not s_section then
		return ""
	end
	local parts = {}
	for i = s_section, e_section do
		local section = self.sections[i]
		local start_idx = (i == s_section) and s_idx or 1
		local end_idx = (i == e_section) and e_idx or (utf8.len(section) + 1)
		start_idx = math.max(1, start_idx)
		end_idx = math.min(utf8.len(section) + 1, end_idx)
		if start_idx <= utf8.len(section) and end_idx > start_idx then
			local sub = splitText(section, start_idx, "second")
			sub = splitText(sub, end_idx - start_idx + 1, "first")
			table.insert(parts, sub)
		elseif start_idx == 1 and end_idx > utf8.len(section) then
			table.insert(parts, section)
		end
	end
	return table.concat(parts, "\n")
end

function TextInput:_deleteSelection()
	local s_section, s_idx, e_section, e_idx = self:_getOrderedSelection()
	if not s_section then
		return
	end

	-- 合并被选区截断的段落
	local first_part = splitText(self.sections[s_section], s_idx, "first")
	local second_part = ""
	if e_section <= #self.sections then
		second_part = splitText(self.sections[e_section], e_idx, "second")
	end

	-- 删除中间段落（从后往前删）
	for i = e_section, s_section, -1 do
		self:removeSection(i)
	end

	-- 插入合并后的段落
	local merged = first_part .. second_part
	self:insertNewSection(s_section, merged)

	-- 清除选区，光标移到删除位置
	self:_clearSelection()
	self.cursor.section = s_section
	self.cursor.index = s_idx
	self:flushText()
	self:setCursorIndex(s_idx)
	if self.height_adaptive then
		self:refreshHeight()
	end
	self:refreshHint()
end

function TextInput:selectText(start_section, start_index, end_section, end_index)
	self.cursor._sel_start = {start_section, start_index}
	self.cursor._sel_end = {end_section, end_index}
end

function TextInput:selectAll()
	self.cursor._sel_start = {1, 1}
	local last_section = #self.sections
	self.cursor._sel_end = {last_section, utf8.len(self.sections[last_section]) + 1}
end

--------------------------------------------------
---@region Copy & Paste
--------------------------------------------------

function TextInput:copy()
	if self:_hasSelection() then
		love.system.setClipboardText(self:_getSelectedText())
	end
end

function TextInput:paste()
	self:_saveOneShot()
	local text = love.system.getClipboardText()
	if not text or text == "" then
		return
	end
	if self:_hasSelection() then
		self:_deleteSelection()
	end
	-- 按换行符分段插入
	local new_sections = split_by_newline(text)
	if #new_sections == 1 then
		-- 单行粘贴，直接在当前段落插入
		local old_text = self.sections[self.cursor.section]
		local old_idx = self.cursor.index
		local first_part = splitText(old_text, old_idx, "first")
		local second_part = splitText(old_text, old_idx, "second")
		self.sections[self.cursor.section] = first_part .. new_sections[1] .. second_part
		self:flushText()
		self:setCursorIndex(old_idx + utf8.len(new_sections[1]))
	else
		-- 多行粘贴，拆分当前段落
		local old_text = self.sections[self.cursor.section]
		local old_idx = self.cursor.index
		local first_part = splitText(old_text, old_idx, "first")
		local second_part = splitText(old_text, old_idx, "second")
		-- 第一行附加到当前段落头部
		self.sections[self.cursor.section] = first_part .. new_sections[1]
		-- 中间行作为新段落插入
		for i = 2, #new_sections do
			self:insertNewSection(self.cursor.section + i - 1, new_sections[i])
		end
		-- 最后一行附加 second_part
		local last_inserted = self.cursor.section + #new_sections - 1
		self.sections[last_inserted] = self.sections[last_inserted] .. second_part
		self:flushText()
		self.cursor.section = last_inserted
		self:setCursorIndex(utf8.len(self.sections[last_inserted]) - utf8.len(second_part) + 1)
	end
	if self.height_adaptive then
		self:refreshHeight()
	end
	self:refreshHint()
end

--------------------------------------------------
---@region Undo & Redo
--------------------------------------------------

function TextInput:_makeSnapshot()
	local sections_copy = {}
	for i, s in ipairs(self.sections) do
		sections_copy[i] = s
	end
	return {
		sections = sections_copy,
		cursor_section = self.cursor.section,
		cursor_index = self.cursor.index
	}
end

function TextInput:_restoreSnapshot(snap)
	self.sections = snap.sections
	self:_clearSelection()
	self.cursor.section = snap.cursor_section
	self.cursor.index = snap.cursor_index
	self:flushText()
	if self.height_adaptive then
		self:refreshHeight()
	end
	self:refreshHint()
	self:setCursorIndex(snap.cursor_index)
end

--- 提交当前操作组，将其起始快照推入撤销栈
function TextInput:_commitUndoGroup()
	if self._undo_group then
		table.insert(self._undo_stack, self._undo_group)
		if #self._undo_stack > self._undo_stack_max then
			table.remove(self._undo_stack, 1)
		end
		self._undo_group = nil
		self._undo_group_type = nil
		self._redo_stack = {}
	end
end

--- 在 mutation 前调用：若操作类型变化则提交旧组，若无活跃组则保存快照
function TextInput:_preMutation(mutation_type)
	self._undo_inactivity_timer = 0
	if self._undo_group_type and self._undo_group_type ~= mutation_type then
		self:_commitUndoGroup()
	end
	if not self._undo_group then
		self._undo_group = self:_makeSnapshot()
		self._undo_group_type = mutation_type
	end
end

--- 在光标移动/点击/回车等操作前调用，结束当前操作组
function TextInput:_breakUndoGroup()
	self:_commitUndoGroup()
end

--- 一次性操作（粘贴/回车/剪切）的撤销保存：直接推入快照
function TextInput:_saveOneShot()
	self:_commitUndoGroup()
	table.insert(self._undo_stack, self:_makeSnapshot())
	if #self._undo_stack > self._undo_stack_max then
		table.remove(self._undo_stack, 1)
	end
	self._redo_stack = {}
end

function TextInput:undo()
	self:_commitUndoGroup()
	if #self._undo_stack == 0 then
		return
	end
	table.insert(self._redo_stack, self:_makeSnapshot())
	if #self._redo_stack > self._undo_stack_max then
		table.remove(self._redo_stack, 1)
	end
	local snap = table.remove(self._undo_stack)
	self:_restoreSnapshot(snap)
end

function TextInput:redo()
	self:_commitUndoGroup()
	if #self._redo_stack == 0 then
		return
	end
	table.insert(self._undo_stack, self:_makeSnapshot())
	if #self._undo_stack > self._undo_stack_max then
		table.remove(self._undo_stack, 1)
	end
	local snap = table.remove(self._redo_stack)
	self:_restoreSnapshot(snap)
end

--------------------------------------------------
---@region Event Handlers
--------------------------------------------------

local function isCtrlPressed()
	return love.keyboard.isDown("rctrl", "lctrl")
end

local function _withShift(self, fn)
	self:_breakUndoGroup()
	if love.keyboard.isDown("lshift", "rshift") then
		if not self.cursor._sel_start then
			self.cursor._sel_start = {self.cursor.section, self.cursor.index}
		end
		fn(self)
		self.cursor._sel_end = {self.cursor.section, self.cursor.index}
	else
		self:_clearSelection()
		fn(self)
	end
end

local KEY_MAP = {
	backspace = function(self)
		self:backspace()
	end,
	delete = function(self)
		self:delete()
	end,
	kpenter = function(self)
		self:lineBreak()
	end,
	["return"] = function(self)
		self:lineBreak()
	end,
	left = function(self)
		_withShift(self, self.moveCursorLeft)
	end,
	right = function(self)
		_withShift(self, self.moveCursorRight)
	end,
	up = function(self)
		_withShift(self, self.moveCursorUp)
	end,
	down = function(self)
		_withShift(self, self.moveCursorDown)
	end,
	home = function(self)
		_withShift(self, self.moveCursorToHead)
	end,
	["end"] = function(self)
		_withShift(self, self.moveCursorToEnd)
	end
}
local CTRL_KEY_MAP = {
	a = function(self)
		self:selectAll()
	end,
	c = function(self)
		self:copy()
	end,
	v = function(self)
		self:paste()
	end,
	x = function(self)
		self:_saveOneShot();
		self:copy();
		if self:_hasSelection() then
			self:_deleteSelection()
		end
	end,
	z = function(self)
		if love.keyboard.isDown("lshift", "rshift") then
			self:redo()
		else
			self:undo()
		end
	end,
	y = function(self)
		self:redo()
	end
}
function TextInput:onKeyPressed(key, isrepeat)
	if not self:isFocus() then
		return
	end
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
	self:_preMutation("input")
	if self:_hasSelection() then
		self:_deleteSelection()
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
		self:_breakUndoGroup()
		self:setCursorPosByScreenPos(x, y)
		self:_clearSelection()
		self.cursor._sel_start = {self.cursor.section, self.cursor.index}
		self._is_dragging = true
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

function TextInput:onMouseMoved(x, y, dx, dy)
	if self._is_dragging then
		if self:regionDetection(x, y) then
			self:setCursorPosByScreenPos(x, y)
			self.cursor._sel_end = {self.cursor.section, self.cursor.index}
		end
	end
end

function TextInput:onMouseReleased(x, y, button)
	if button == 1 then
		self._is_dragging = false
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
	if self.cursor_blinking_timer > CURSOR_BLINK_DURATION then
		self.cursor_blinking_timer = self.cursor_blinking_timer - CURSOR_BLINK_DURATION
	end
	if self.cursor_blinking_timer < CURSOR_BLINK_DURATION_HALF then
		self.cursor_blinking = true
	else
		self.cursor_blinking = false
	end
	-- 撤销操作组停顿计时器：超过阈值自动提交当前组
	if self._undo_group then
		self._undo_inactivity_timer = self._undo_inactivity_timer + dt
		if self._undo_inactivity_timer > self._undo_inactivity_threshold then
			self:_commitUndoGroup()
		end
	end
	-- 自适应高度：构造时 transform 尺寸未就绪，首帧补刷新
	if self.height_adaptive then
		self:refreshHeight()
	end
end

function TextInput:onPostDraw()
	local org_x, org_y, _, _, r = self.text.transform:getGlobalBounds()
	local font = self.text:getFont()
	local line_height = font:getHeight() * font:getLineHeight()

	-- 绘制选区高亮
	if self:_hasSelection() then
		local s_section, s_idx, e_section, e_idx = self:_getOrderedSelection()
		local current_line = 0
		for i, section in ipairs(self.sections) do
			if i < s_section then
				local _, wt = font:getWrap(section, self.text.transform.w)
				current_line = current_line + #wt
			elseif i <= e_section then
				-- 计算当前段落内的选区范围
				local section_s_idx = 1
				local section_e_idx = utf8.len(section) + 1
				if i == s_section then
					section_s_idx = s_idx
				end
				if i == e_section then
					section_e_idx = e_idx
				end

				local _, wt = font:getWrap(section, self.text.transform.w)
				local char_offset = 0
				for l, line_text in ipairs(wt) do
					local line_len = utf8.len(line_text)
					local line_start_idx = char_offset + 1
					local line_end_idx = char_offset + line_len + 1

					if line_start_idx < section_e_idx and line_end_idx > section_s_idx then
						local sel_start = math.max(section_s_idx, line_start_idx)
						local sel_end = math.min(section_e_idx, line_end_idx)
						if sel_start < sel_end then
							local prefix = (sel_start > line_start_idx) and
											   string.sub(line_text, 1,
									utf8.offset(line_text, sel_start - char_offset) - 1) or ""
							local sel_start_byte = utf8.offset(line_text, math.max(1, sel_start - char_offset))
							local sel_end_rel = math.min(line_len + 1, sel_end - char_offset)
							local sel_end_byte = (sel_end_rel > line_len) and (#line_text + 1) or
													 utf8.offset(line_text, sel_end_rel)
							local sel_text = ""
							if sel_start_byte and sel_end_byte and sel_start_byte < sel_end_byte then
								sel_text = string.sub(line_text, sel_start_byte, sel_end_byte - 1)
							end
							local x_off = font:getWidth(prefix)
							local sel_w = font:getWidth(sel_text)
							local y_pos = org_y + (current_line + l - 1) * line_height

							love.graphics.push()
							if r ~= 0 and r ~= Utils.TWO_PI then
								local px, py = self.text.transform:getGlobalPosition()
								love.graphics.translate(px, py)
								love.graphics.rotate(r)
								love.graphics.translate(-px, -py)
							end
							love.graphics.setColor(unpack(SELECTION_COLOR))
							love.graphics.rectangle("fill", org_x + x_off, y_pos, sel_w, line_height)
							love.graphics.pop()
						end
					end
					char_offset = char_offset + line_len
				end
				current_line = current_line + #wt
			else
				break
			end
		end
	end

	-- 绘制光标
	if self.cursor.show and self.cursor_blinking then
		local top_x, top_y = org_x + self.cursor._local_pos_cache[1], org_y + self.cursor._local_pos_cache[2]
		local bottom_y = top_y + font:getHeight()

		love.graphics.push()
		if r ~= 0 and r ~= Utils.TWO_PI then
			local px, py = self.text.transform:getGlobalPosition()
			love.graphics.translate(px, py)
			love.graphics.rotate(r)
			love.graphics.translate(-px, -py)
		end
		love.graphics.setColor(unpack(CURSOR_COLOR))
		love.graphics.setLineWidth(1)
		love.graphics.line(top_x, top_y, top_x, bottom_y)
		love.graphics.pop()
	end
end

return TextInput
