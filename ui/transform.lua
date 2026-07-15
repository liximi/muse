local Class = require "dependencies.classic"

--------------------------------------------------
-- 私有辅助函数
--------------------------------------------------

-- 统一布局计算：padding（left/right/top/bottom）是唯一的真相源，
-- x/y/w/h 是从 padding + anchor + pivot 推导出的缓存值。
-- 点锚点（anchor_w == 0）和拉伸锚点在 parent_w == 0 时都跳过尺寸计算，
-- w/h 保留 setSize 设定的值（默认 0），避免构造期算出负尺寸。
local function _recalcLayout(self)
	local pw = self.parent and self.parent.w or love.graphics.getWidth()
	local ph = self.parent and self.parent.h or love.graphics.getHeight()
	local aw = pw * (self.anchor_max[1] - self.anchor_min[1])
	local ah = ph * (self.anchor_max[2] - self.anchor_min[2])

	-- 仅当锚点范围提供有效尺寸信息时才重算 w/h
	if aw > 0 then
		self.w = aw - self.left - self.right
	end
	if ah > 0 then
		self.h = ah - self.top - self.bottom
	end
	self.x = self.left + self.w * self.pivot[1]
	self.y = self.top + self.h * self.pivot[2]
end

local TWO_PI = math.pi * 2

local function normalizeRadians(rad)
	if rad > 0 and rad < TWO_PI then
		return rad
	end
	local normalized = math.fmod(rad, TWO_PI)
	if normalized < 0 then
		normalized = normalized + TWO_PI
	end
	return normalized
end

local function _calcAABB(x, y, sw, sh, px, py, r)
	local dx_left = -sw * px
	local dx_right = sw + dx_left
	local dy_top = -sh * py
	local dy_bottom = sh + dy_top
	local sin, cos = math.sin(r), math.cos(r)
	local cos_dx_l = dx_left * cos
	local cos_dx_r = dx_right * cos
	local sin_dy_t = dy_top * sin
	local sin_dy_b = dy_bottom * sin
	local sin_dx_l = dx_left * sin
	local sin_dx_r = dx_right * sin
	local cos_dy_t = dy_top * cos
	local cos_dy_b = dy_bottom * cos
	local verts = {
		{x + cos_dx_l - sin_dy_t, y + sin_dx_l + cos_dy_t}, -- Left Top
		{x + cos_dx_r - sin_dy_t, y + sin_dx_r + cos_dy_t}, -- Right Top
		{x + cos_dx_l - sin_dy_b, y + sin_dx_l + cos_dy_b}, -- Left Bottom
		{x + cos_dx_r - sin_dy_b, y + sin_dx_r + cos_dy_b}, -- Right Bottom
	}
	local minx, maxx, miny, maxy = verts[1][1], verts[1][1], verts[1][2], verts[1][2]
	for i, v in ipairs(verts) do
		if i ~= 1 then
			local vx, vy = v[1], v[2]
			if vx < minx then minx = vx
			elseif vx > maxx then maxx = vx end
			if vy < miny then miny = vy
			elseif vy > maxy then maxy = vy end
		end
	end
	return minx, miny, maxx - minx, maxy - miny
end

--------------------------------------------------
-- Transform 类定义
--------------------------------------------------

local Transform = Class(function(self)
	-- 缓存字段（只读，由 _recalcLayout 维护）
	self.x = 0
	self.y = 0
	self.w = 0
	self.h = 0

	self.rotation = 0 -- 弧度
	self.scale_x = 1
	self.scale_y = 1

	-- 配置字段
	self.anchor_min = {0, 0}
	self.anchor_max = {0, 0}
	self.pivot = {0, 0}

	-- 真相源（唯一的主数据，所有 setter 最终写入这里）
	self.left = 0
	self.right = 0
	self.top = 0
	self.bottom = 0

	-- 父 Transform 引用
	self.parent = nil

	-- 脏检测缓存
	self._cache = nil
end)

--------------------------------------------------
-- 公有 Setter
-- 所有 setter 直接写入 padding 真相源，然后调用 _recalcLayout 同步缓存
--------------------------------------------------

--- 设置 pivot 在锚点范围内的偏移（像素）。传入 nil 表示不修改该维度。
--- 同时调整 left/right（或 top/bottom）以保持当前尺寸不变。
function Transform:setPosition(x, y)
	local pw = self.parent and self.parent.w or love.graphics.getWidth()
	local ph = self.parent and self.parent.h or love.graphics.getHeight()
	local changed = false
	if x then
		local aw = pw * (self.anchor_max[1] - self.anchor_min[1])
		self.left = x - self.w * self.pivot[1]
		self.right = aw - self.left - self.w
		changed = true
	end
	if y then
		local ah = ph * (self.anchor_max[2] - self.anchor_min[2])
		self.top = y - self.h * self.pivot[2]
		self.bottom = ah - self.top - self.h
		changed = true
	end
	if changed then
		_recalcLayout(self)
	end
end

--- 设置控件的尺寸（像素）。传入 nil 表示不修改该维度。
function Transform:setSize(w, h)
	local pw = self.parent and self.parent.w or love.graphics.getWidth()
	local ph = self.parent and self.parent.h or love.graphics.getHeight()
	local changed = false
	if w then
		self.w = w
		local aw = pw * (self.anchor_max[1] - self.anchor_min[1])
		self.left = self.x - w * self.pivot[1]
		self.right = aw - self.left - w
		changed = true
	end
	if h then
		self.h = h
		local ah = ph * (self.anchor_max[2] - self.anchor_min[2])
		self.top = self.y - h * self.pivot[2]
		self.bottom = ah - self.top - h
		changed = true
	end
	if changed then
		_recalcLayout(self)
	end
end

--- 设置锚点边距（像素）。传入 nil 表示不修改该维度。
function Transform:setPadding(left, right, top, bottom)
	if left then self.left = left end
	if right then self.right = right end
	if top then self.top = top end
	if bottom then self.bottom = bottom end
	if left or right or top or bottom then
		_recalcLayout(self)
	end
end

function Transform:setScale(sx, sy)
	if sx then self.scale_x = sx end
	if sy then self.scale_y = sy end
end

--- 设置支点（自身尺寸百分比 0~1）。保持控件视觉位置和尺寸不变。
function Transform:setPivot(px, py)
	local pw = self.parent and self.parent.w or love.graphics.getWidth()
	local ph = self.parent and self.parent.h or love.graphics.getHeight()
	local changed = false
	if px then
		local aw = pw * (self.anchor_max[1] - self.anchor_min[1])
		self.pivot[1] = px
		self.left = self.x - self.w * px
		self.right = aw - self.left - self.w
		changed = true
	end
	if py then
		local ah = ph * (self.anchor_max[2] - self.anchor_min[2])
		self.pivot[2] = py
		self.top = self.y - self.h * py
		self.bottom = ah - self.top - self.h
		changed = true
	end
	if changed then
		_recalcLayout(self)
	end
end

--- 设置锚点范围（父容器百分比 0~1）。传入 nil 表示不修改该维度。
function Transform:setAnchor(minx, miny, maxx, maxy)
	if minx then self.anchor_min[1] = minx end
	if miny then self.anchor_min[2] = miny end
	if maxx then self.anchor_max[1] = maxx end
	if maxy then self.anchor_max[2] = maxy end
	if minx or maxx or miny or maxy then
		_recalcLayout(self)
	end
end

function Transform:setRotation(rot)
	self.rotation = normalizeRadians(rot)
end

--- 设置父 Transform。传入 nil 解除父子关系。
function Transform:setParent(parent_transform)
	self.parent = parent_transform
	self:onUpdate(true)
end

--------------------------------------------------
-- 公有 Getter（全部读缓存字段）
--------------------------------------------------

function Transform:getPosition()
	return self.x, self.y
end

function Transform:getSize()
	return self.w, self.h
end

function Transform:getScale()
	return self.scale_x, self.scale_y
end

function Transform:getScaledSize()
	return self.w * self.scale_x, self.h * self.scale_y
end

function Transform:getAnchor()
	return self.anchor_min[1], self.anchor_min[2], self.anchor_max[1], self.anchor_max[2]
end

function Transform:getPivot()
	return self.pivot[1], self.pivot[2]
end

function Transform:getPadding()
	return {
		left = self.left,
		right = self.right,
		top = self.top,
		bottom = self.bottom,
	}
end

function Transform:getRotation()
	return self.rotation
end

function Transform:getGlobalPosition()
	local parent_x, parent_y = 0, 0
	local parent_sx, parent_sy = 1, 1
	local parent_w, parent_h
	local parent_r = 0
	local parent_pivot = {0, 0}
	if self.parent then
		parent_x, parent_y = self.parent:getGlobalPosition()
		parent_sx, parent_sy = self.parent:getGlobalScale()
		parent_w, parent_h = self.parent:getGlobalScaledSize()
		parent_pivot = self.parent.pivot
		parent_r = self.parent:getGlobalRotation()
	else
		parent_w, parent_h = love.graphics.getWidth(), love.graphics.getHeight()
	end
	-- 计算当前元素相对于父级旋转中心的偏移量
	local dx = (self.anchor_min[1] - parent_pivot[1]) * parent_w + self.x * parent_sx
	local dy = (self.anchor_min[2] - parent_pivot[2]) * parent_h + self.y * parent_sy
	if parent_r == 0 or parent_r == TWO_PI then
		return parent_x + dx, parent_y + dy
	else
		local cos_r = math.cos(parent_r)
		local sin_r = math.sin(parent_r)
		local dx_rot = dx * cos_r - dy * sin_r
		local dy_rot = dx * sin_r + dy * cos_r
		return parent_x + dx_rot, parent_y + dy_rot
	end
end

function Transform:getGlobalScale()
	local parent_sx, parent_sy = 1, 1
	if self.parent then
		parent_sx, parent_sy = self.parent:getGlobalScale()
	end
	return self.scale_x * parent_sx, self.scale_y * parent_sy
end

function Transform:getGlobalScaledSize()
	local sx, sy = self:getGlobalScale()
	return self.w * sx, self.h * sy
end

function Transform:getGlobalRotation(no_normalize)
	local parent_r = self.parent and self.parent:getGlobalRotation(true) or 0
	return no_normalize and (parent_r + self.rotation) or normalizeRadians(parent_r + self.rotation)
end

---@return number x 左上角 X 坐标
---@return number y 左上角 Y 坐标
---@return number w
---@return number h
function Transform:getAABB()
	local sw, sh = self:getScaledSize()
	return _calcAABB(self.x, self.y, sw, sh, self.pivot[1], self.pivot[2], self.rotation)
end

---@return number x
---@return number y
---@return number w
---@return number h
function Transform:getGlobalAABB()
	local x, y = self:getGlobalPosition()
	local sw, sh = self:getGlobalScaledSize()
	return _calcAABB(x, y, sw, sh, self.pivot[1], self.pivot[2], self:getGlobalRotation())
end

---@return number x
---@return number y
---@return number w
---@return number h
---@return number r
function Transform:getBounds()
	local sw, sh = self:getScaledSize()
	return self.x - sw * self.pivot[1], self.y - sh * self.pivot[2], sw, sh, self.rotation
end

---@return number x
---@return number y
---@return number w
---@return number h
---@return number r
function Transform:getGlobalBounds()
	local x, y = self:getGlobalPosition()
	local sw, sh = self:getGlobalScaledSize()
	return x - sw * self.pivot[1], y - sh * self.pivot[2], sw, sh, self:getGlobalRotation()
end

function Transform:screenToLocal(screen_x, screen_y)
	local gx, gy = self:getGlobalPosition()
	local gr = self:getGlobalRotation()
	local gsx, gsy = self:getGlobalScale()

	local offset_x = screen_x - gx
	local offset_y = screen_y - gy

	local dx, dy
	if gr == 0 or gr == TWO_PI then
		dx = offset_x
		dy = offset_y
	else
		local cos_r = math.cos(gr)
		local sin_r = math.sin(gr)
		dx = offset_x * cos_r + offset_y * sin_r
		dy = -offset_x * sin_r + offset_y * cos_r
	end
	return dx / gsx, dy / gsy
end

--------------------------------------------------
-- 每帧更新
--------------------------------------------------

--- 每帧调用一次，检测真相源（padding/anchors/pivot/parent_size）是否变化，
--- 变化时重算缓存字段 x/y/w/h
function Transform:onUpdate(force)
	local pw = self.parent and self.parent.w or love.graphics.getWidth()
	local ph = self.parent and self.parent.h or love.graphics.getHeight()
	if not force and self._cache then
		if self._cache.l == self.left and self._cache.r == self.right and
			self._cache.t == self.top and self._cache.b == self.bottom and
			self._cache.amin1 == self.anchor_min[1] and self._cache.amax1 == self.anchor_max[1] and
			self._cache.amin2 == self.anchor_min[2] and self._cache.amax2 == self.anchor_max[2] and
			self._cache.p1 == self.pivot[1] and self._cache.p2 == self.pivot[2] and
			self._cache.pw == pw and self._cache.ph == ph then
			return
		end
	end
	self._cache = {
		l = self.left, r = self.right, t = self.top, b = self.bottom,
		amin1 = self.anchor_min[1], amax1 = self.anchor_max[1],
		amin2 = self.anchor_min[2], amax2 = self.anchor_max[2],
		p1 = self.pivot[1], p2 = self.pivot[2],
		pw = pw, ph = ph,
	}
	_recalcLayout(self)
end

function Transform:__tostring()
	return string.format(
		"position:[%.2f, %.2f] size:[%.2f, %.2f] rotation:%.2f scale:[%.2f, %.2f] anchor:[%.2f, %.2f, %.2f, %.2f] pivot:[%.2f, %.2f] padding:[l:%.2f, r:%.2f, t:%.2f b:%.2f]",
		self.x, self.y, self.w, self.h, self.rotation, self.scale_x, self.scale_y,
		self.anchor_min[1], self.anchor_min[2], self.anchor_max[1], self.anchor_max[2],
		self.pivot[1], self.pivot[2],
		self.left, self.right, self.top, self.bottom)
end

return Transform
