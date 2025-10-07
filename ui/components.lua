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
		local sx, sy = self:GetGlobalScale()
		return w * sx, h * sy
	end
end


return Components