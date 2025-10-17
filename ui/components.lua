--对一般功能的封装
local Components = {}


function Components.addHoverState(widget)
	widget.hovered = false
	widget.onMouseMoved = function(self, x, y, dx, dy)
		if self:regionDetection(x, y) then
			if not self.hovered then
				self.hovered = true
				if self.OnHovered then
					self:OnHovered(true, x, y, dx, dy)
				end
			end
		elseif self.hovered then
			self.hovered = false
			if self.OnHovered then
				self:OnHovered(false, x, y, dx, dy)
			end
		end
	end
end


return Components