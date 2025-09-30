local Lf = require "dependencies.loveframes"

local Widget = Class(function(self, name)
	self._name = name or "widget"
	self._valid = true
	-- Local Transform
	self._x = 0
	self._y = 0
	self._sx = 1 -- scale x
	self._sy = 1 -- scale y
	self._rotation = 0 -- 0 ~ 2Pi
	-- Global Transform
	self._gx = 0
	self._gy = 0
	self._gsx = 1
	self._gsy = 1
	self._grotation = 0
	self._g_transform_dirty = false

	self.children = {}
	self.parent = nil

	self.enabled = true
	self.shown = true
	self.focus = false
end)

function Widget:SetPosition(x, y)
	if self._x ~= x or self._y ~= y then
		self._x = x
		self._y = y
		self._g_transform_dirty = true
	end
end

function Widget:GetPosition()
	return self._x, self._y
end

function Widget:SetScale(x, y)
	if self._sx ~= x or self._sy ~= y then
		self._sx = x
		self._sy = y
		self._g_transform_dirty = true
	end
end

function Widget:GetScale()
	return self._sx, self._sy
end

function Widget:SetRotation(rot)-- 0 ~ 2Pi
	if self._rotation ~= rot then
		self._rotation = rot % (2 * math.pi)
		self._g_transform_dirty = true
	end
end


function Widget:_UpdateGlobalTransform()
	if self.parent then
		local px, py = self.parent:GetGlobalPosition()
		local psx, psy = self.parent:GetGlobalScale()
		local prot = self.parent:GetGlobalRotation()

		-- 计算全局位置（考虑父级缩放和旋转）
		local scaled_x = self._x * psx
		local scaled_y = self._y * psy
		local rotated_x = scaled_x * math.cos(prot) - scaled_y * math.sin(prot)
		local rotated_y = scaled_x * math.sin(prot) + scaled_y * math.cos(prot)
		self._gx = px + rotated_x
		self._gy = py + rotated_y

		-- 计算全局缩放（累积父级缩放）
		self._gsx = self._sx * psx
		self._gsy = self._sy * psy

		-- 计算全局旋转（累积父级旋转）
		self._grotation = (self._rotation + prot) % (2 * math.pi)
	else
		-- 没有父级时，全局变换等于局部变换
		self._gx = self._x
		self._gy = self._y
		self._gsx = self._sx
		self._gsy = self._sy
		self._grotation = self._rotation
	end

	self._g_transform_dirty = false
end

function Widget:GetGlobalPosition()
	if self._g_transform_dirty then
		self:_UpdateGlobalTransform()
	end
	return self._gx, self._gy
end

function Widget:GetGlobalScale()
	if self._g_transform_dirty then
		self:_UpdateGlobalTransform()
	end
	return self._gsx, self._gsy
end

function Widget:GetGlobalRotation()
	if self._g_transform_dirty then
		self:_UpdateGlobalTransform()
	end
	return self._grotation
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

function Widget:KeyPressed(key, isrepeat)
	if not self._valid or not self.enabled or not self.shown then
		return
	end
	for _, child in ipairs(self.children) do
		if child:KeyPressed(key, isrepeat) then--如果子UI返回true，则表示要拦截该消息
			return true
		end
	end
	if self.OnKeyPressed then
		return self:OnKeyPressed(key, isrepeat)
	end
end


function Widget:KeyReleased(key)
	if not self._valid or not self.enabled or not self.shown then
		return
	end
	for _, child in ipairs(self.children) do
		if child:KeyReleased(key) then--如果子UI返回true，则表示要拦截该消息
			return true
		end
	end
	if self.OnKeyReleased then
		return self:OnKeyReleased(key)
	end
end


function Widget:TextInput(text)
	if not self._valid or not self.enabled or not self.shown then
		return
	end
	for _, child in ipairs(self.children) do
		if child:TextInput(text) then--如果子UI返回true，则表示要拦截该消息
			return true
		end
	end
	if self.OnTextInput then
		return self:OnTextInput(text)
	end
end


function Widget:MouseMoved(x, y, dx, dy)
	if not self._valid or not self.enabled or not self.shown then
		return
	end
	for _, child in ipairs(self.children) do
		if child:MouseMoved(x, y, dx, dy) then--如果子UI返回true，则表示要拦截该消息
			return true
		end
	end
	if self.OnMouseMoved then
		return self:OnMouseMoved(x, y, dx, dy)
	end
end


function Widget:MousePressed(x, y, button, presses)
	if not self._valid or not self.enabled or not self.shown then
		return
	end
	for _, child in ipairs(self.children) do
		if child:MousePressed(x, y, button, presses) then--如果子UI返回true，则表示要拦截该消息
			return true
		end
	end
	if self.OnMousePressed then
		return self:OnMousePressed(x, y, button, presses)
	end
end


function Widget:MouseReleased(x, y, button, presses)
	if not self._valid or not self.enabled or not self.shown then
		return
	end
	for _, child in ipairs(self.children) do
		if child:MouseReleased(x, y, button, presses) then--如果子UI返回true，则表示要拦截该消息
			return true
		end
	end
	if self.OnMouseReleased then
		return self:OnMouseReleased(x, y, button, presses)
	end
end


function Widget:WheelMoved(x, y)
	if not self._valid or not self.enabled or not self.shown then
		return
	end
	for _, child in ipairs(self.children) do
		if child:WheelMoved(x, y) then--如果子UI返回true，则表示要拦截该消息
			return true
		end
	end
	if self.OnWheelMoved then
		return self:OnWheelMoved(x, y)
	end
end


return Widget
