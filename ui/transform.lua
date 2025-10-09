local function _updateLeftRight(transform)
	local parent_w = transform.parent and transform.parent.w or love.graphics.getWidth()
	transform.left = transform.x - transform.w * transform.pivot[1] - transform.anchors_min[1] * parent_w
	transform.right = transform.anchors_max[1] * parent_w - transform.x - transform.w * (1 - transform.pivot[1])
end

local function _updateTopBottom(transform)
	local parent_h = transform.parent and transform.parent.h or love.graphics.getHeight()
	transform.top = transform.y - transform.h * transform.pivot[2] - transform.anchors_min[2] * parent_h
	transform.bottom = transform.anchors_max[2] * parent_h - transform.y - transform.h * (1 - transform.pivot[2])
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
local function setPosition(transform, x, y)
	if x then
		transform.x = x
		_updateLeftRight(transform)
	end
	if y then
		transform.y = y
		_updateTopBottom(transform)
	end
end

--- 会额外影响Padding
local function setSize(transform, w, h)
	if w then
		transform.w = w
		_updateLeftRight(transform)
	end
	if h then
		transform.h = h
		_updateTopBottom(transform)
	end
end

--- 会额外影响坐标和尺寸
local function setPadding(transform, left, right, top, bottom)
	if left then
		transform.left = left
	end
	if right then
		transform.right = right
	end
	if top then
		transform.top = top
	end
	if bottom then
		transform.bottom = bottom
	end
	if left or right then
		local parent_w = transform.parent and transform.parent.w or love.graphics.getWidth()
		local w = parent_w - transform.right - transform.left
		transform.w = w
		transform.x = transform.left + w * transform.pivot[1]
	end
	if top or bottom then
		local parent_h = transform.parent and transform.parent.h or love.graphics.getHeight()
		local h = parent_h - transform.top - transform.bottom
		transform.h = h
		transform.y = transform.top + h * transform.pivot[2]
	end
end

local function setScale(transform, sx, sy)
	if sx then
		transform.scale_x = sx
	end
	if sy then
		transform.scale_y = sy
	end
end

--- 会额外影响坐标
local function setPivot(transform, px, py)
	local x, y
	if px then
		x = transform.x + (px - transform.pivot[1]) * transform.w
		transform.pivot[1] = px
	end
	if py then
		y = transform.y + (py - transform.pivot[2]) * transform.h
		transform.pivot[2] = py
	end
	setPosition(transform, x, y)
end

--- 会额外影响Padding
local function setAnchors(transform, minx, miny, maxx, maxy)
	if minx then
		transform.anchors_min[1] = minx
	end
	if miny then
		transform.anchors_min[2] = miny
	end
	if maxx then
		transform.anchors_max[1] = maxx
	end
	if maxy then
		transform.anchors_max[2] = maxy
	end
	if minx or maxx then
		_updateLeftRight(transform)
	end
	if miny or maxy then
		_updateTopBottom(transform)
	end
end

local function setRotation(transform, rot)
	transform.rotation = rot
end


--------------------------------------------------
-- Public Getter
--------------------------------------------------


local function getPosition(transform)
	return transform.x, transform.y
end

local function getSize(transform)
	return transform.w, transform.h
end

local function getScale(transform)
	return transform.scale_x, transform.scale_y
end

local function getScaledSize(transform)
	return transform.w * transform.scale_x, transform.h * transform.scale_y
end

local function getAnchors(transform)
	return transform.anchors_min[1], transform.anchors_min[2], transform.anchors_max[1], transform.anchors_max[2]
end

local function getPivot(transform)
	return transform.pivot[1], transform.pivot[2]
end

local function getPadding(transform)
	return {
		left = transform.left,
		right = transform.right,
		top = transform.top,
		bottom = transform.bottom,
	}
end

local function getGlobalPosition(transform)
	local parent_x, parent_y = 0, 0
	local parent_sx, parent_sy = 1, 1
	if transform.parent then
		parent_x, parent_y = transform.parent:getGlobalPosition()
		parent_sx, parent_sy = transform.parent:getGlobalScale()
	end
	return parent_x + transform.x * parent_sx, parent_y + transform.y * parent_sy
end

local function getGlobalScale(transform)
	local parent_sx, parent_sy = 1, 1
	if transform.parent then
		parent_sx, parent_sy = transform.parent:getGlobalScale()
	end
	return transform.scale_x * parent_sx, transform.scale_y * parent_sy
end

local function getGloablScaledSize(transform)
	local sx, sy = transform:getGlobalScale()
	return transform.w * sx, transform.h * sy
end

local function getGlobalRotation(transform)
	local parent_r = transform.parent and transform.parent:getGlobalRotation() or 0
	return normalizeRadians(parent_r + transform.rotation)
end




local function Transform()
	return {
		-- parent = Transform(),
		x = 0,
		y = 0,

		w = 0,
		h = 0,

		rotation = 0,--单位：弧度

		scale_x = 1,
		scale_y = 1,
		--锚点，决定了元素在父容器中的定位基准，虽然说是点，但其实是一个范围
		anchors_min = {0, 1},--锚点的左上角坐标（百分比）
		anchors_max = {0, 1},--锚点的右下角坐标（百分比）
		--支点，决定了元素自身坐标的原点，同时也是旋转、缩放等变换的中心（百分比）。
		pivot = {0, 0},

		left = 0,--元素的左边缘到锚点左侧的距离（像素）
		right = 0,--元素的右边缘到锚点右侧的距离（像素）
		top = 0,--元素的上边缘到锚点顶部的距离（像素）
		bottom = 0,--元素的下边缘到锚点底部的距离（像素）

		setParent = function (self, parent_transform)
			self.parent = parent_transform
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

		getGlobalPosition = getGlobalPosition,
		getGlobalScale = getGlobalScale,
		getGloablScaledSize = getGloablScaledSize,
		getGlobalRotation = getGlobalRotation,
	}
end

return Transform