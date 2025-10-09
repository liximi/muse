--对一般功能的封装
local Components = {}

function Components.AddSize(widget)
	widget.width = 0
	widget.height = 0
	widget.SetSize = function(self, w, h)
		self.width = w
		self.height = h
		if self.OnSetSize then
			self:OnSetSize(w, h)
		end
	end
	widget.GetSize = function(self)
		return self.width, self.height
	end
	widget.GetScaledSize = function(self)
		local w, h = self:GetSize()
		return w * self._sx, h * self._sy
	end
	widget.GetGlobalScaledSize = function(self)
		local w, h = self:GetSize()
		local sx, sy = self:getGlobalScale()
		return w * sx, h * sy
	end

	widget.GetAABBB = function(self)
		local x, y = self:getGlobalPosition()
		local w, h = self:GetGlobalScaledSize()
		return {x, y, w, h}
	end

	widget.IsInUIScope = function(self, x, y)
		local aabb = self:GetAABBB()
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


function Components.AddHoverState(widget)
	widget.hovered = false
	widget.OnMouseMoved = function(self, x, y, dx, dy)
		if self:IsInUIScope(x, y) then
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