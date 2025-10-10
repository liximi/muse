--对一般功能的封装
local Components = {}

function Components.AddSize(widget)
	widget.isInUIScope = function(self, x, y)
		local aabb = self:getAABB()
		local minx, maxx = aabb[1], aabb[1] + aabb[3]
		local miny, maxy = aabb[2], aabb[2] + aabb[4]
		if minx > maxx then
			local temp = minx
			minx = maxx
			maxx = temp
		end
		if miny > maxy then
			local temp = miny
			miny = maxy
			maxy = temp
		end
		if x >= minx and x <= maxx and y >= miny and y <= maxy then
			return true
		end
		return false
	end
end


function Components.addHoverState(widget)
	widget.hovered = false
	widget.onMouseMoved = function(self, x, y, dx, dy)
		if self:isInUIScope(x, y) then
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