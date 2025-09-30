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
	-- 全局变换缓存
	self._transform_cache = nil

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
		self:InvalidateTransform()
	end
end

function Widget:GetPosition()
	return self._x, self._y
end

function Widget:SetScale(x, y)
	if self._sx ~= x or self._sy ~= y then
		self._sx = x
		self._sy = y
		self:InvalidateTransform()
	end
end

function Widget:GetScale()
	return self._sx, self._sy
end

function Widget:SetRotation(rot) -- 0 ~ 2Pi
	if self._rotation ~= rot then
		self._rotation = rot % (2 * math.pi)
		self:InvalidateTransform()
	end
end

-- 缓存失效机制
function Widget:InvalidateTransform()
	self._transform_cache = nil
	-- 只有当变换实际影响子组件时才失效子缓存
	if #self.children > 0 then
		for _, child in ipairs(self.children) do
			child:InvalidateTransform()
		end
	end
end

-- 全局变换计算 - 使用缓存
function Widget:GetGlobalTransform()
	if self._transform_cache then
		return unpack(self._transform_cache)
	end

	local gx, gy, gsx, gsy, grotation

	if self.parent then
		local px, py = self.parent:GetGlobalPosition()
		local psx, psy = self.parent:GetGlobalScale()
		local prot = self.parent:GetGlobalRotation()

		-- 计算全局位置（考虑父级缩放和旋转）
		local scaled_x = self._x * psx
		local scaled_y = self._y * psy
		local rotated_x = scaled_x * math.cos(prot) - scaled_y * math.sin(prot)
		local rotated_y = scaled_x * math.sin(prot) + scaled_y * math.cos(prot)
		gx = px + rotated_x
		gy = py + rotated_y

		-- 计算全局缩放（累积父级缩放）
		gsx = self._sx * psx
		gsy = self._sy * psy

		-- 计算全局旋转（累积父级旋转）
		grotation = (self._rotation + prot) % (2 * math.pi)
	else
		-- 没有父级时，全局变换等于局部变换
		gx = self._x
		gy = self._y
		gsx = self._sx
		gsy = self._sy
		grotation = self._rotation
	end

	-- 缓存结果
	self._transform_cache = {gx, gy, gsx, gsy, grotation}
	return gx, gy, gsx, gsy, grotation
end

-- 优化的全局变换获取函数 - 避免不必要的计算
function Widget:GetGlobalPosition()
	if self._transform_cache then
		return self._transform_cache[1], self._transform_cache[2]
	end

	if self.parent then
		local px, py = self.parent:GetGlobalPosition()
		local psx, psy = self.parent:GetGlobalScale()
		local prot = self.parent:GetGlobalRotation()

		local scaled_x = self._x * psx
		local scaled_y = self._y * psy
		local rotated_x = scaled_x * math.cos(prot) - scaled_y * math.sin(prot)
		local rotated_y = scaled_x * math.sin(prot) + scaled_y * math.cos(prot)
		return px + rotated_x, py + rotated_y
	else
		return self._x, self._y
	end
end

function Widget:GetGlobalScale()
	if self._transform_cache then
		return self._transform_cache[3], self._transform_cache[4]
	end

	if self.parent then
		local psx, psy = self.parent:GetGlobalScale()
		return self._sx * psx, self._sy * psy
	else
		return self._sx, self._sy
	end
end

function Widget:GetGlobalRotation()
	if self._transform_cache then
		return self._transform_cache[5]
	end

	if self.parent then
		local prot = self.parent:GetGlobalRotation()
		return (self._rotation + prot) % (2 * math.pi)
	else
		return self._rotation
	end
end

function Widget:AddChild(child)
	-- 防止循环引用
	assert(child ~= self, "Cannot add widget as its own child")
	-- 检查是否会导致循环引用
	local current = self.parent
	while current do
		assert(current ~= child, "Circular reference detected: cannot add parent as child")
		current = current.parent
	end

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
	for i, _child in ipairs(self.children) do
		if _child == child then
			child.parent = nil
			table.remove(self.children, i)
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

-- 统一的状态检查方法
function Widget:IsOperational()
	return self._valid and self.enabled and self.shown
end

function Widget:ShouldDraw()
	return self._valid and self.shown
end

function Widget:ShouldUpdate()
	return self._valid and self.enabled
end

function Widget:Draw()
	if not self:ShouldDraw() then
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
	if not self:ShouldUpdate() then
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

function Widget:HandleEvent(event_type, ...)
	if not self:IsOperational() then
		return
	end

	for i = #self.children, 1, -1 do
		if self.children[i]:HandleEvent(event_type, ...) then
			return true -- 事件被拦截
		end
	end

	local handler_name = "On" .. event_type
	local handler = self[handler_name]
	if handler then
		return handler(self, ...)
	end
end


return Widget
