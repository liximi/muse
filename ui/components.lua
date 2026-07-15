-- 对一般功能的封装
local Components = {}

function Components.addHoverState(widget)
	widget.hovered = false
	local original_onMouseMoved = widget.onMouseMoved
	widget.onMouseMoved = function(self, x, y, dx, dy)
		-- 先调用原始 handler（如 TextInput 的拖选逻辑），避免被完全覆盖
		if original_onMouseMoved then
			original_onMouseMoved(self, x, y, dx, dy)
		end
		-- 然后执行 hover 检测
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
	-- 注意：text 本身不在样式中管理 —— 按钮文字由 setText() / 构造参数控制，
	-- 状态切换只改变颜色和字号，不改变文字内容。
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
