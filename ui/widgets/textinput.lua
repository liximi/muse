local Widget = require "ui.widgets.widget"
local Text = require "ui.widgets.text"
local Fonts = require "ui.fonts"
local utf8 = require "utf8"
local Utils = require "ui.utils"
local addHoverState = require "ui.components".addHoverState


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
		pivot = {0.5, 0.5},
	}))
	if datas.hint then
		self.hint = self:addChild(Text({
			text = datas.hint,
			text_color = datas.hint_color or self.theme.hint_color,
			anchors = {0, 0, 1, 1},
			padding = datas.text_padding or {0, 0, 0, 0},
			pivot = {0.5, 0.5},
		}))
	end

	self.cursor = {
		show = false,
		pos = {1, 0},--{行, 当行的字符索引值}
		_local_pos_cache = {0, 0}--相对本地坐标系的坐标（左上角为文本的原点，考虑padding）
	}

	addHoverState(self)
end)


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

function TextInput:showCursor(show)
	if show then
		self.cursor.show = true
	else
		self.cursor.show = false
	end
end

function TextInput:setCursorPos(line, index)
	local font = self.text:getFont()
	local text = self.text:getText(true)
	local maxw, wrappedtext = font:getWrap(text, self.text.transform.w)
	if line then
		line = math.max(1, math.min(#wrappedtext, line))--clamp
		self.cursor.pos[1] = line
	end
	if index then
		index = math.max(0, math.min(utf8.len(wrappedtext[line or self.cursor.pos[1]]), index))--clamp
		self.cursor.pos[2] = index
	end

	if not text or text == "" then
		self.cursor._local_pos_cache[1] = 0
		self.cursor._local_pos_cache[2] = 0
	end
	local line_height = font:getHeight() * font:getLineHeight()
	self.cursor._local_pos_cache[2] = line_height * (line - 1)
	local byteoffset = utf8.offset(wrappedtext[line], -1)
	self.cursor._local_pos_cache[1] = font:getWidth(string.sub(wrappedtext[line], 1, byteoffset))
end

function TextInput:setCursorPosByScreenPos(screen_x, screen_y)
	local local_x, local_y = self.text.transform:screenToLocal(screen_x, screen_y)
	local font = self.text:getFont()
	local text = self.text:getText(true)
	local maxw, wrappedtext = font:getWrap(text, self.text.transform.w)
	local line_height = font:getHeight() * font:getLineHeight()
	local line = math.min(math.ceil(local_y/line_height), #wrappedtext)
	self.cursor.pos[1] = line

	--TODO
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
	if is_in_scope and not is_focus then
		self:setCursorPosByScreenPos(x, y)
		self:setFocus()
		return
	end
	if is_focus then
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

function TextInput:onKeyPressed(key, isrepeat)
	if key == "backspace" then
		local text = self.text:getText()
        local byteoffset = utf8.offset(text, -1)
        if byteoffset then
            text = string.sub(text, 1, byteoffset - 1)
			self.text:setText(text)
			if self.height_adaptive then
				self:refreashHeight()
			end
			self:refreashHint()
        end
	elseif key == "kpenter" or key == "return" then
		self:onTextInput("\n")
	end
end

function TextInput:onTextInput(text)
	if not self:isFocus() then
		return
	end
	local old_text = self.text:getText()
	local new_text = old_text..text
	self.text:setText(new_text)
	if self.height_adaptive then
		self:refreashHeight()
	end
	self:refreashHint()
end


local cursor_blinking, cursor_blinking_timer = true, 0
local cursor_blinking_duration, cursor_blinking_duration_half = 2, 1
function TextInput:onUpdate(dt)
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
	end
end


return TextInput