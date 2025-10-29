local Widget = require "ui.widgets.widget"
local Text = require "ui.widgets.text"
local Fonts = require "ui.fonts"
local utf8 = require "utf8"
local Utils = require "ui.utils"
local addHoverState = require "ui.components".addHoverState


local cursor_blinking, cursor_blinking_timer = true, 0
local cursor_blinking_duration, cursor_blinking_duration_half = 1, 0.5


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

	self.text = self:addChild(Text({
		text_color = datas.text_color or self.theme.text_color,
		anchors = {0, 0, 1, 1},
		padding = datas.text_padding or {0, 0, 0, 0},
	}))
	if datas.hint then
		self.hint = self:addChild(Text({
			text = datas.hint,
			text_color = datas.hint_color or self.theme.hint_color,
			anchors = {0, 0, 1, 1},
			padding = datas.text_padding or {0, 0, 0, 0},
		}))
	end

	self.cursor = {
		show = false,
		index = 1,
		_local_pos_cache = {0, 0}--相对本地坐标系的坐标（左上角为文本的原点，考虑padding）
	}

	addHoverState(self)
end)


--------------------------------------------------
-- Hint
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

function TextInput:refreashHeight()
	local _, text_h = self.text:getScaledSize()
	text_h = math.max(self.min_height, text_h)
	local w, h = self.transform:getSize()
	if h ~= text_h then
		self.transform:setSize(w, text_h)
	end
end


--------------------------------------------------
-- Cursor
--------------------------------------------------

function TextInput:showCursor(show)
	if show then
		self.cursor.show = true
	else
		self.cursor.show = false
	end
end

function TextInput:setCursorPos(index)
	if not index then
		return
	end

	local text = self.text:getText(true)
	self.cursor.index = math.max(0, math.min(#text+1, index))--clamp

	local font = self.text:getFont()
	local maxw, wrappedtext = font:getWrap(text, self.text.transform.w)
	local line = 1
	for l, s in ipairs(wrappedtext) do
		local len = #s
		print("line:", l, len, index)
		line = l
		if len + 1 >= index then
			break
		end
		index = index - len
	end

	if not text or text == "" then
		self.cursor._local_pos_cache[1] = 0
		self.cursor._local_pos_cache[2] = 0
	else
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


--------------------------------------------------
-- Event Handlers
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
		self:onTextInput("\n")
	elseif key == "left" then
		local old_idx = self.cursor.index
		if old_idx > 0 then
			local old_text = self.text:getText(true)
			local first_text = string.sub(old_text, 1, old_idx - 1)
			local byteoffset = utf8.offset(first_text, -1)
			self:setCursorPos(byteoffset)
		end
	elseif key == "right" then
		local old_text = self.text:getText(true)
		local old_idx = self.cursor.index
		if old_idx < #old_text then
			local second_text = string.sub(old_text, old_idx)
			local byteoffset = utf8.offset(second_text, 2)
			self:setCursorPos(old_idx + byteoffset - 1)
		end
	elseif key == "up" then

	elseif key == "down" then

	end
end

function TextInput:onTextInput(text)
	if not self:isFocus() then
		return
	end
	local old_text = self.text:getText(true)
	local old_idx = self.cursor.index
	local new_text = table.concat({string.sub(old_text, 1, old_idx - 1), text, string.sub(old_text, old_idx)})
	self.text:setText(new_text)
	self:setCursorPos(old_idx + #text)
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
		self:onHovered(is_in_scope)
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