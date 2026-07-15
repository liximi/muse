--------------------------------------------------
-- VBoxContainer — 垂直排列子控件
-- 参考 Godot scene/gui/box_container.cpp BoxContainer::_resort
--
-- 算法同 HBoxContainer，轴换成垂直：
--   第一趟：收集每个孩子的最小高度 + 标记 EXPAND
--   第二趟：按 stretch_ratio 比例分配剩余高度
--   第三趟：fitChildInRect 逐个定位 + alignment 偏移
--------------------------------------------------

local Container = require "ui.widgets.containers.container"
local Utils = require "ui.utils"
local Class = require "dependencies.classic"

local SZ = Utils.SIZE_FLAGS

-- 检查 size_flags 中是否包含某个标志位
local function hasFlag(flags, flag)
	return flags % (flag * 2) >= flag
end

--[[datas:
	separation = number  子控件间距，默认 0
	alignment  = "begin" | "center" | "end"  无 EXPAND 孩子时的整体垂直偏移，默认 "begin"
]]
local VBoxContainer = Class(Container, function(self, datas, theme)
	Container.new(self, "VBoxContainer", datas, theme)

	self.separation = (datas and datas.separation) or 0
	self.alignment = (datas and datas.alignment) or "begin"
end)

--- 返回容器自身的最小尺寸 = 最高孩子的高度和 + 间距 + 最宽孩子的宽度
--- 参考 Godot box_container.cpp get_minimum_size
function VBoxContainer:getMinimumSize()
	local max_w = 0
	local total_h = 0
	local first = true

	for _, c in ipairs(self.children) do
		if c:isShown() then
			local mw, mh = c:getCombinedMinimumSize()
			if not first then
				total_h = total_h + self.separation
			end
			total_h = total_h + mh
			if mw > max_w then
				max_w = mw
			end
			first = false
		end
	end

	return max_w, total_h
end

function VBoxContainer:_sortChildren()
	-- 参考 Godot box_container.cpp:43 _resort()
	local children = self:_visibleChildren()
	if #children == 0 then
		return
	end

	local container_w = self.transform.w
	local container_h = self.transform.h

	--------------------------------------------------
	-- 第一趟：收集最小尺寸 + 标记 stretch
	--------------------------------------------------
	local cache = {}
	local total_min = 0
	local desired_extra = 0
	local stretch_avail = 0
	local stretch_ratio_total = 0

	for _, c in ipairs(children) do
		local _, mh = c:getCombinedMinimumSize()
		local _, dh = c:getDesiredSize()
		local will_stretch = hasFlag(c.v_size_flags, SZ.EXPAND)
		local entry = {
			child = c,
			min = mh,
			desired = dh,
			stretch = will_stretch,
			final = mh,
		}
		table.insert(cache, entry)
		total_min = total_min + mh
		if dh > mh then
			desired_extra = desired_extra + (dh - mh)
		end
		if will_stretch then
			stretch_avail = stretch_avail + mh
			stretch_ratio_total = stretch_ratio_total + (c.stretch_ratio or 1)
		end
	end

	local max_space = container_h - self.separation * (#children - 1)
	local stretch_diff = math.max(0, max_space - total_min)
	stretch_avail = stretch_avail + stretch_diff

	--------------------------------------------------
	-- 第二趟 A：先分配 desired_size（"我需要这么多"）
	--------------------------------------------------
	if stretch_diff > 0 and desired_extra > 0 then
		local space_ratio = math.min(stretch_diff / desired_extra, 1.0)
		for _, entry in ipairs(cache) do
			if entry.desired > entry.min then
				local inc = math.floor((entry.desired - entry.min) * space_ratio)
				if entry.stretch then
					entry.min = entry.min + inc
				else
					stretch_avail = stretch_avail - inc
				end
				entry.final = entry.final + inc
			end
		end
	end

	--------------------------------------------------
	-- 第二趟 B：按 stretch_ratio 比例分配剩余
	--------------------------------------------------
	while stretch_ratio_total > 0 do
		local ok = true
		for _, entry in ipairs(cache) do
			if entry.stretch then
				local ratio = entry.child.stretch_ratio or 1
				local size = stretch_avail * ratio / stretch_ratio_total
				if size < entry.min then
					entry.stretch = false
					stretch_ratio_total = stretch_ratio_total - ratio
					stretch_avail = stretch_avail - entry.min
					entry.final = entry.min
					ok = false
					break
				else
					entry.final = size
				end
			end
		end
		if ok then
			break
		end
	end

	--------------------------------------------------
	-- alignment
	--------------------------------------------------
	local final_diff = max_space - total_min
	for _, entry in ipairs(cache) do
		final_diff = final_diff - (entry.final - entry.min)
	end
	final_diff = math.max(0, final_diff)

	local offset = 0
	if not self:_hasStretched(cache) then
		if self.alignment == "end" then
			offset = final_diff
		elseif self.alignment == "center" then
			offset = math.floor(final_diff / 2)
		end
	end

	--------------------------------------------------
	-- 第三趟：fitChildInRect
	--------------------------------------------------
	for i, entry in ipairs(cache) do
		local h = entry.final
		if entry.stretch and i == #cache then
			h = container_h - offset
		end

		self:fitChildInRect(entry.child, 0, offset, container_w, h)
		offset = offset + h + self.separation
	end
end

function VBoxContainer:_hasStretched(cache)
	for _, entry in ipairs(cache) do
		if entry.stretch then
			return true
		end
	end
	return false
end

return VBoxContainer
