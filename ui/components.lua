-- 对一般功能的封装
local Components = {}

function Components.addHoverState(widget)
	widget.hovered = false
	widget.onMouseMoved = function(self, x, y, dx, dy)
		if self:regionDetection(x, y) then
			if not self.hovered then
				self.hovered = true
				if self.onHovered then
					self:onHovered(true, x, y, dx, dy)
				end
				return true
			end
		elseif self.hovered then
			self.hovered = false
			if self.onHovered then
				self:onHovered(false, x, y, dx, dy)
			end
		end
	end
end

--- 应用按钮文本样式变更
function Components.applyButtonTextStyle(button, new_style)
	if not button.text then
		return
	end
	local new_text = new_style.text
	if new_text then
		button.text:setText(new_text)
	end
	local new_text_color = new_style.text_color
	if new_text_color then
		button.text:setTextColor(new_text_color)
	end
	local new_font_size = new_style.font_size
	if new_font_size and button.text:getFontSize() ~= new_font_size then
		button.text:setFontSize(new_font_size)
	end
end

--- 应用按钮位置偏移和缩放变更
function Components.applyButtonTransform(button, old_style, new_style)
	local old_offset = old_style.offset or {0, 0}
	local offset = new_style.offset or {0, 0}
	local total_offset = {offset[1] - old_offset[1], offset[2] - old_offset[2]}
	local x, y = button:getPosition()
	button:setPosition(x + total_offset[1], y + total_offset[2])

	local scale = new_style.scale or {1, 1}
	button.transform:setScale(scale[1], scale[2])
end

return Components
