-- 统一布局计算：padding（left/right/top/bottom）是唯一的真相源，
-- x/y/w/h 是从 padding + anchor + pivot 推导出的缓存值。
-- 点锚点（anchor_w == 0）和拉伸锚点在 parent_w == 0 时都跳过尺寸计算，
-- w/h 保留 setSize 设定的值（默认 0），避免构造期算出负尺寸。
local function _recalcLayout(transform)
	local pw = transform.parent and transform.parent.w or love.graphics.getWidth()
	local ph = transform.parent and transform.parent.h or love.graphics.getHeight()
	local aw = pw * (transform.anchor_max[1] - transform.anchor_min[1])
	local ah = ph * (transform.anchor_max[2] - transform.anchor_min[2])

	-- 仅当锚点范围提供有效尺寸信息时才重算 w/h
	if aw > 0 then
		transform.w = aw - transform.left - transform.right
	end
	if ah > 0 then
		transform.h = ah - transform.top - transform.bottom
	end
	transform.x = transform.left + transform.w * transform.pivot[1]
	transform.y = transform.top + transform.h * transform.pivot[2]
end

local twoPi = 2 * math.pi
local function normalizeRadians(rad)
	if rad > 0 and rad < twoPi then
		return rad
	end
	local normalized = math.fmod(rad, twoPi)
	if normalized < 0 then
		normalized = normalized + twoPi
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
	local verts = {{x + cos_dx_l - sin_dy_t, y + sin_dx_l + cos_dy_t}, -- Left Top
	{x + cos_dx_r - sin_dy_t, y + sin_dx_r + cos_dy_t}, -- Right Top
	{x + cos_dx_l - sin_dy_b, y + sin_dx_l + cos_dy_b}, -- Left Bottom
	{x + cos_dx_r - sin_dy_b, y + sin_dx_r + cos_dy_b} -- Right Bottom
	}
	local minx, maxx, miny, maxy = verts[1][1], verts[1][1], verts[1][2], verts[1][2]
	for i, v in ipairs(verts) do
		if i ~= 1 then
			local vx, vy = v[1], v[2]
			if vx < minx then
				minx = vx
			elseif vx > maxx then
				maxx = vx
			end
			if vy < miny then
				miny = vy
			elseif vy > maxy then
				maxy = vy
			end
		end
	end
	return minx, miny, maxx - minx, maxy - miny
end

--------------------------------------------------
-- Public Setter
-- 所有 setter 直接写入 padding 真相源，然后调用 _recalcLayout 同步缓存
--------------------------------------------------

--- 设置 pivot 在锚点范围内的偏移（像素）。传入 nil 表示不修改该维度。
--- 同时调整 left/right（或 top/bottom）以保持当前尺寸不变。
local function setPosition(self, x, y)
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
--- 直接写入 self.w/h 保证点锚点可用；同时调整 left/right 保持 pivot 位置不变。
local function setSize(self, w, h)
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
local function setPadding(self, left, right, top, bottom)
	if left then
		self.left = left
	end
	if right then
		self.right = right
	end
	if top then
		self.top = top
	end
	if bottom then
		self.bottom = bottom
	end
	if left or right or top or bottom then
		_recalcLayout(self)
	end
end

local function setScale(self, sx, sy)
	if sx then
		self.scale_x = sx
	end
	if sy then
		self.scale_y = sy
	end
end

--- 设置支点（自身尺寸百分比 0~1）。保持控件视觉位置和尺寸不变。
local function setPivot(self, px, py)
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
local function setAnchor(self, minx, miny, maxx, maxy)
	if minx then
		self.anchor_min[1] = minx
	end
	if miny then
		self.anchor_min[2] = miny
	end
	if maxx then
		self.anchor_max[1] = maxx
	end
	if maxy then
		self.anchor_max[2] = maxy
	end
	if minx or maxx or miny or maxy then
		_recalcLayout(self)
	end
end

local function setRotation(self, rot)
	self.rotation = normalizeRadians(rot)
end

--------------------------------------------------
-- Public Getter（全部读缓存字段，不受重构影响）
--------------------------------------------------

local function getPosition(self)
	return self.x, self.y
end

local function getSize(self)
	return self.w, self.h
end

local function getScale(self)
	return self.scale_x, self.scale_y
end

local function getScaledSize(self)
	return self.w * self.scale_x, self.h * self.scale_y
end

local function getAnchor(self)
	return self.anchor_min[1], self.anchor_min[2], self.anchor_max[1], self.anchor_max[2]
end

local function getPivot(self)
	return self.pivot[1], self.pivot[2]
end

local function getPadding(self)
	return {
		left = self.left,
		right = self.right,
		top = self.top,
		bottom = self.bottom
	}
end

local function getRotation(self)
	return self.rotation
end

local two_pi = math.pi * 2
local function getGlobalPosition(self)
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
	if parent_r == 0 or parent_r == two_pi then
		return parent_x + dx, parent_y + dy
	else
		-- 应用父级旋转
		local cos_r = math.cos(parent_r)
		local sin_r = math.sin(parent_r)
		local dx_rot = dx * cos_r - dy * sin_r -- 旋转后的x偏移
		local dy_rot = dx * sin_r + dy * cos_r -- 旋转后的y偏移
		-- 最终全局坐标 = 父级旋转中心全局坐标 + 旋转后的偏移量
		return parent_x + dx_rot, parent_y + dy_rot
	end
end

local function getGlobalScale(self)
	local parent_sx, parent_sy = 1, 1
	if self.parent then
		parent_sx, parent_sy = self.parent:getGlobalScale()
	end
	return self.scale_x * parent_sx, self.scale_y * parent_sy
end

local function getGlobalScaledSize(self)
	local sx, sy = self:getGlobalScale()
	return self.w * sx, self.h * sy
end

local function getGlobalRotation(self, no_normalize)
	local parent_r = self.parent and self.parent:getGlobalRotation(true) or 0
	return no_normalize and (parent_r + self.rotation) or normalizeRadians(parent_r + self.rotation)
end

---@return number x 左上角 X 坐标
---@return number y 左上角 Y 坐标
---@return number w
---@return number h
local function getAABB(self)
	local sw, sh = getScaledSize(self)
	return _calcAABB(self.x, self.y, sw, sh, self.pivot[1], self.pivot[2], self.rotation)
end

---@return number x
---@return number y
---@return number w
---@return number h
local function getGlobalAABB(self)
	local x, y = getGlobalPosition(self)
	local sw, sh = getGlobalScaledSize(self)
	return _calcAABB(x, y, sw, sh, self.pivot[1], self.pivot[2], self:getGlobalRotation())
end

---@return number x
---@return number y
---@return number w
---@return number h
---@return number r
local function getBounds(self)
	local sw, sh = getScaledSize(self)
	return self.x - sw * self.pivot[1], self.y - sh * self.pivot[2], sw, sh, self.rotation
end

---@return number x
---@return number y
---@return number w
---@return number h
---@return number r
local function getGlobalBounds(self)
	local x, y = getGlobalPosition(self)
	local sw, sh = getGlobalScaledSize(self)
	return x - sw * self.pivot[1], y - sh * self.pivot[2], sw, sh, self:getGlobalRotation()
end

local function screenToLocal(self, screen_x, screen_y)
	local gx, gy = self:getGlobalPosition()
	local gr = self:getGlobalRotation()
	local gsx, gsy = self:getGlobalScale()

	local offset_x = screen_x - gx
	local offset_y = screen_y - gy

	local dx, dy
	if gr == 0 or gr == two_pi then
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

local function Transform()
	return {
		-- parent = Transform(),

		-- ── 缓存字段（只读，由 _recalcLayout 维护）──
		x = 0, -- pivot 在锚点范围内的水平偏移（像素）
		y = 0, -- pivot 在锚点范围内的垂直偏移（像素）
		w = 0, -- 控件宽度（像素）
		h = 0, -- 控件高度（像素）

		rotation = 0, -- 弧度
		scale_x = 1,
		scale_y = 1,

		-- ── 配置字段（锚点模式由此决定）──
		anchor_min = {0, 0}, -- 锚点范围左上角（父容器百分比 0~1）
		anchor_max = {0, 0}, -- 锚点范围右下角（父容器百分比 0~1）
		pivot = {0, 0},      -- 支点（自身尺寸百分比 0~1），旋转和缩放的中心

		-- ── 真相源（唯一的主数据，所有 setter 最终写入这里）──
		left = 0,   -- 控件左边缘到锚点左边缘的距离（像素）
		right = 0,  -- 锚点右边缘到控件右边缘的距离（像素）
		top = 0,    -- 控件上边缘到锚点上边缘的距离（像素）
		bottom = 0, -- 锚点下边缘到控件下边缘的距离（像素）

		setParent = function(self, parent_transform)
			self.parent = parent_transform
			self:onUpdate(true)
		end,
		setPosition = setPosition,
		setSize = setSize,
		setPadding = setPadding,
		setScale = setScale,
		setPivot = setPivot,
		setAnchor = setAnchor,
		setRotation = setRotation,

		getPosition = getPosition,
		getSize = getSize,
		getScale = getScale,
		getScaledSize = getScaledSize,
		getAnchor = getAnchor,
		getPivot = getPivot,
		getPadding = getPadding,
		getRotation = getRotation,
		getAABB = getAABB,
		getBounds = getBounds,

		getGlobalPosition = getGlobalPosition,
		getGlobalScale = getGlobalScale,
		getGlobalScaledSize = getGlobalScaledSize,
		getGlobalRotation = getGlobalRotation,
		getGlobalAABB = getGlobalAABB,
		getGlobalBounds = getGlobalBounds,

		screenToLocal = screenToLocal,

		-- 每帧调用一次，检测真相源（padding/anchors/pivot/parent_size）是否变化，
		-- 变化时重算缓存字段 x/y/w/h
		onUpdate = function(self, force)
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
		end,

		__tostring = function(self)
			return string.format(
				"position:[%.2f, %.2f] size:[%.2f, %.2f] rotation:%.2f scale:[%.2f, %.2f] anchor:[%.2f, %.2f, %.2f, %.2f] pivot:[%.2f, %.2f] padding:[l:%.2f, r:%.2f, t:%.2f b:%.2f]",
				self.x, self.y, self.w, self.h, self.rotation, self.scale_x, self.scale_y, self.anchor_min[1],
				self.anchor_min[2], self.anchor_max[1], self.anchor_max[2], self.pivot[1], self.pivot[2], self.left,
				self.right, self.top, self.bottom)
		end,
	}
end

return Transform
