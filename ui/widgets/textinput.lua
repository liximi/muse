local Widget = require "ui.widgets.widget"
local Text = require "ui.widgets.text"
local Panel = require "ui.widgets.panel"
local Fonts = require "ui.fonts"
local utf8 = require "utf8"
local Utils = require "ui.utils"
local AddSizeComponent = require "ui.components".AddSize
local addHoverState = require "ui.components".addHoverState


local TextInput = Class(Widget, function(self, w, h, hint, enable_background, height_adaptive, min_height)
	Widget.new(self, "TextInput")

	self.outline_color = Utils.UI_COLORS.SECONDARY_TEXT
	self.hovered_outline_color = Utils.UI_COLORS.WHITE

	self.height_adaptive = height_adaptive == true
	self.min_height = min_height or h or 75

	if enable_background then
		self.bg = self:addChild(Panel(w or 200, h or 75))
		self.bg:SetBGColor(Utils.UI_COLORS.WHITE)
		self.bg:SetOutlineColor(self.outline_color)
	end

	self.text = self:addChild(Text())
	self.text:setTextColor(Utils.UI_COLORS.PRIMARY_TEXT)
	if hint then
		self.hint = self:addChild(Text(hint))
		self.hint:setTextColor(Utils.UI_COLORS.SECONDARY_TEXT)
	end

	AddSizeComponent(self)
	self.transform:setSize(w or 200, h or 75)

	addHoverState(self)
end)


function TextInput:SetOutlineColor(color)
	self.outline_color = color
end

function TextInput:SetHoveredOutlineColor(color)
	self.hovered_outline_color = color
end

function TextInput:RefreashHint()
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

function TextInput:RefreashHeight()
	local _, text_h = self.text:getScaledSize()
	text_h = math.max(self.min_height, text_h)
	local w, h = self.transform:getSize()
	if h ~= text_h then
		self.transform:setSize(w, text_h)
	end
end


function TextInput:onMouseReleased(x, y, button)
	if button ~= 1 then
		return
	end
	local is_in_scope = self:isInUIScope(x, y)
	local is_focus = self:isFocus()
	if is_in_scope and not is_focus then
		self:setFocus()
		return
	end
	if is_focus then
		self:removeFocus()
		self:OnHovered(is_in_scope)
	end
end

function TextInput:OnHovered(hovered, x, y, dx, dy)
	if not self.bg or self:isFocus() then
		return
	end
	if hovered then
		self.bg:SetOutlineColor(self.hovered_outline_color)
	else
		self.bg:SetOutlineColor(self.outline_color)
	end
end

function TextInput:OnKeyPressed(key, isrepeat)
	if key == "backspace" then
		local text = self.text:getText()
        local byteoffset = utf8.offset(text, -1)
        if byteoffset then
            text = string.sub(text, 1, byteoffset - 1)
			self.text:setText(text)
			if self.height_adaptive then
				self:RefreashHeight()
			end
			self:RefreashHint()
        end
	elseif key == "kpenter" or key == "return" then
		self:OnTextInput("\n")
	end
end

function TextInput:OnTextInput(text)
	if not self:isFocus() then
		return
	end
	local old_text = self.text:getText()
	self.text:setText(old_text..text)
	if self.height_adaptive then
		self:RefreashHeight()
	end
	self:RefreashHint()
end


return TextInput