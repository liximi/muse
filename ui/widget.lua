local Lf = require "dependencies.loveframes"


local Widget = Class(function(self, name)
	self._name = name or "widget"
	self._valid = true
	--Local Transform
	self._x = 0
	self._y = 0
	self._sx = 1	--scale x
	self._sy = 1	--scale y
	self._rotation = 0	--0 ~ 2Pi

	self.children = {}
	self.parent = nil

	self.enabled = true
    self.shown = true
    self.focus = false
end)


function Widget:SetPosition(x, y)
	self._x = x
	self._y = y
end


function Widget:GetPosition(unpack)
	if unpack then
		return self._x, self._y
	else
		return {self._x, self._y}
	end
end


function Widget:GetGlobalPosition(unpack)
	
end


function Widget:AddChild(child)
	if child.parent == self then
		return child
	end
	if child.parent ~= nil and child.parent ~= self then
		child.parent:RemoveChild(child)
	end
	child.parent = self
	table.insert(self.children, child)
	return child
end


function Widget:RemoveChild(child)
	for _, _child in ipairs(self.children) do
		if _child == child then
			child.parent = nil
			table.remove(self.children, _child)
			return
		end
	end
end


function Widget:RemoveAllChildren()
	for _, child in ipairs(self.children) do
        child.parent = nil
    end
	self.children = {}
end

function Widget:Destroy()
	local temp_children = self.children
	self:RemoveAllChildren()
	for _, child in ipairs(temp_children) do
		child:Destroy()
	end
	if self.parent then
		self.parent:RemoveChild(self)
	end
	self._valid = false
end


function Widget:IsValid()
	return self._valid == true
end


function Widget:Draw()
	if not self._valid or not self.shown then
		return
	end
	if self.OnDraw then
		self:OnDraw()
	end
	for _, child in ipairs(self.children) do
		child:Draw()
	end
end


function Widget:Update(dt)
	if not self._valid or not self.enabled then
		return
	end
	if self.OnUpdate then
		self:OnUpdate(dt)
	end
	for _, child in ipairs(self.children) do
		child:Update(dt)
	end
end


function Widget:IsShown()
	return self.shown
end


function Widget:Show()
	self.shown = true
end


function Widget:Hide()
	self.shown = false
end


return Widget