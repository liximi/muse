local function _updateLeftRight(transform)
	local parent_w = transform.parent and transform.parent.w or love.graphics.getWidth()
	transform.left = transform.x - transform.w * transform.pivot[1]
	transform.right = parent_w * transform.anchors_max[1] - transform.x - transform.w * (1 - transform.pivot[1])
end

local function _updateTopBottom(transform)
	local parent_h = transform.parent and transform.parent.h or love.graphics.getHeight()
	transform.top = transform.y - transform.h * transform.pivot[2]
	transform.bottom = parent_h * transform.anchors_max[2] - transform.y - transform.h * (1 - transform.pivot[2])
end

local function _updateWidthAndX(transform)
	local parent_w = transform.parent and transform.parent.w or love.graphics.getWidth()
	local anchor_w = parent_w * (transform.anchors_max[1] - transform.anchors_min[1])
	local w = anchor_w - transform.left - transform.right
	transform.w = w
	transform.x = transform.left + w * transform.pivot[1]
end

local function _updateHeightAndY(transform)
	local parent_h = transform.parent and transform.parent.h or love.graphics.getHeight()
	local anchor_h = parent_h * (transform.anchors_max[2] - transform.anchors_min[2])
	local h = anchor_h - transform.top - transform.bottom
	transform.h = h
	transform.y = transform.top + h * transform.pivot[2]
end


local function normalizeRadians(rad)
    local twoPi = 2 * math.pi
    local normalized = math.fmod(rad, twoPi)
    if normalized < 0 then
        normalized = normalized + twoPi
    end
    return normalized
end


--------------------------------------------------
-- Public Setter
--------------------------------------------------


--- 会额外影响Padding
local function setPosition(self, x, y)
	if x then
		self.x = x
		_updateLeftRight(self)
	end
	if y then
		self.y = y
		_updateTopBottom(self)
	end
end

--- 会额外影响Padding
local function setSize(self, w, h)
	if w then
		self.w = w
		_updateLeftRight(self)
	end
	if h then
		self.h = h
		_updateTopBottom(self)
	end
end

--- 会额外影响坐标和尺寸
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
	if left or right then
		local parent_w = self.parent and self.parent.w or love.graphics.getWidth()
		local w = parent_w * (self.anchors_max[1] - self.anchors_min[1]) - self.right - self.left
		self.w = w
		self.x = self.left + w * self.pivot[1]
	end
	if top or bottom then
		local parent_h = self.parent and self.parent.h or love.graphics.getHeight()
		local h = parent_h * (self.anchors_max[2] - self.anchors_min[2]) - self.top - self.bottom
		self.h = h
		self.y = self.top + h * self.pivot[2]
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

--- 会额外影响坐标
local function setPivot(self, px, py)
	local x, y
	if px then
		x = self.x + (px - self.pivot[1]) * self.w
		self.pivot[1] = px
	end
	if py then
		y = self.y + (py - self.pivot[2]) * self.h
		self.pivot[2] = py
	end
	setPosition(self, x, y)
end

--- 会额外影响Padding
local function setAnchors(self, minx, miny, maxx, maxy)
	if minx then
		self.anchors_min[1] = minx
	end
	if miny then
		self.anchors_min[2] = miny
	end
	if maxx then
		self.anchors_max[1] = maxx
	end
	if maxy then
		self.anchors_max[2] = maxy
	end
	if minx or maxx then
		_updateLeftRight(self)
	end
	if miny or maxy then
		_updateTopBottom(self)
	end
end

local function setRotation(self, rot)
	self.rotation = rot
end


--------------------------------------------------
-- Public Getter
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

local function getAnchors(self)
	return self.anchors_min[1], self.anchors_min[2], self.anchors_max[1], self.anchors_max[2]
end

local function getPivot(self)
	return self.pivot[1], self.pivot[2]
end

local function getPadding(self)
	return {
		left = self.left,
		right = self.right,
		top = self.top,
		bottom = self.bottom,
	}
end

local function getGlobalPosition(self)
	local parent_x, parent_y = 0, 0
	local parent_sx, parent_sy = 1, 1
	local parent_w, parent_h
	local parent_pivot = {0, 0}
	if self.parent then
		parent_x, parent_y = self.parent:getGlobalPosition()
		parent_sx, parent_sy = self.parent:getGlobalScale()
		parent_w, parent_h = self.parent:getGlobalScaledSize()
		parent_pivot = self.parent.pivot
	else
		parent_w, parent_h = love.graphics.getWidth(), love.graphics.getHeight()
	end

	local x_begin = parent_x + parent_w * (self.anchors_min[1] - parent_pivot[1])
	local y_begin = parent_y + parent_h * (self.anchors_min[2] - parent_pivot[2])
	return x_begin + self.x * parent_sx, y_begin + self.y * parent_sy
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

local function getGlobalRotation(self)
	local parent_r = self.parent and self.parent:getGlobalRotation() or 0
	return normalizeRadians(parent_r + self.rotation)
end

---@return number x 左上角 X 坐标
---@return number y 左上角 Y 坐标
---@return number w
---@return number h
local function getAABB(self)
	local sw, sh = getScaledSize(self)
	return
		self.x - sw * self.pivot[1],
		self.y - sh * self.pivot[2],
		sw, sh
end

---@return number x
---@return number y
---@return number w
---@return number h
local function getGlobalAABB(self)
	local x, y = getGlobalPosition(self)
	local sw, sh = getGlobalScaledSize(self)
	return
		x - sw * self.pivot[1],
		y - sh * self.pivot[2],
		sw, sh
end




local function Transform()
	return {
		-- parent = Transform(),
		x = 0,--pivot相对锚点范围左边缘的偏移量（像素）
		y = 0,--pivot相对锚点范围上边缘的偏移量（像素）

		w = 0,
		h = 0,

		rotation = 0,--单位：弧度

		scale_x = 1,
		scale_y = 1,
		--锚点，决定了元素在父容器中的定位基准，虽然说是点，但其实是一个范围
		anchors_min = {0, 0},--锚点的左上角坐标（百分比）
		anchors_max = {0, 0},--锚点的右下角坐标（百分比）
		--支点，决定了元素自身坐标的原点，同时也是旋转、缩放等变换的中心（百分比）。
		pivot = {0, 0},

		left = 0,--元素的左边缘到锚点左侧的距离（像素）
		right = 0,--元素的右边缘到锚点右侧的距离（像素）
		top = 0,--元素的上边缘到锚点顶部的距离（像素）
		bottom = 0,--元素的下边缘到锚点底部的距离（像素）

		setParent = function (self, parent_transform)
			self.parent = parent_transform
			self:onUpdate()
		end,
		setPosition = setPosition,
		setSize = setSize,
		setPadding = setPadding,
		setScale = setScale,
		setPivot = setPivot,
		setAnchors = setAnchors,
		setRotation = setRotation,

		getPosition = getPosition,
		getSize = getSize,
		getScale = getScale,
		getScaledSize = getScaledSize,
		getAnchors = getAnchors,
		getPivot = getPivot,
		getPadding = getPadding,
		getAABB = getAABB,

		getGlobalPosition = getGlobalPosition,
		getGlobalScale = getGlobalScale,
		getGlobalScaledSize = getGlobalScaledSize,
		getGlobalRotation = getGlobalRotation,
		getGlobalAABB = getGlobalAABB,

		onUpdate = function(self)
			if self.anchors_min[1] == self.anchors_max[1] then
				_updateLeftRight(self)
			else
				_updateWidthAndX(self)
			end
			if self.anchors_min[2] == self.anchors_max[2] then
				_updateTopBottom(self)
			else
				_updateHeightAndY(self)
			end
		end,

		__tostring = function(self)
			return string.format("position:[%.2f, %.2f] size:[%.2f, %.2f] rotation:%.2f scale:[%.2f, %.2f] anchors:[%.2f, %.2f, %.2f, %.2f] pivot:[%.2f, %.2f] padding:[l:%.2f, r:%.2f, t:%.2f b:%.2f]",
				self.x, self.y, self.w, self.h, self.rotation, self.scale_x, self.scale_y, self.anchors_min[1], self.anchors_min[2], self.anchors_max[1], self.anchors_max[2], self.pivot[1], self.pivot[2], self.left, self.right, self.top, self.bottom)
		end
	}
end

return Transform