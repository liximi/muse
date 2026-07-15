--------------------------------------------------
-- HBoxContainer — 水平排列子控件
-- 参考 Godot scene/gui/box_container.cpp BoxContainer::_resort
--
-- 算法（三趟式）：
--   第一趟：收集每个孩子的最小宽度 + 标记 EXPAND
--   第二趟：按 stretch_ratio 比例分配剩余宽度
--           （装不下的从 stretch 池移除 → 重新分配）
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
	alignment  = "begin" | "center" | "end"  无 EXPAND 孩子时的整体水平偏移，默认 "begin"
]]
local HBoxContainer = Class(Container, function(self, datas, theme)
	Container.new(self, "HBoxContainer", datas, theme)

	self._auto_size_axis = "h"  -- auto_size 时只自动宽度
	self.separation = (datas and datas.separation) or 0
	self.alignment = (datas and datas.alignment) or "begin"
end)

--- 返回容器自身的最小尺寸 = 所有孩子最小宽度的和 + 间距 + 最高孩子的高度
--- 参考 Godot box_container.cpp get_minimum_size
function HBoxContainer:getMinimumSize()
	local total_w = 0
	local max_h = 0
	local first = true

	for _, c in ipairs(self.children) do
		if c:isShown() then
			local mw, mh = c:getCombinedMinimumSize()
			if not first then
				total_w = total_w + self.separation
			end
			total_w = total_w + mw
			if mh > max_h then
				max_h = mh
			end
			first = false
		end
	end

	return math.max(total_w, self.transform.w), math.max(max_h, self.transform.h)
end

function HBoxContainer:_sortChildren()
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
	local cache = {}          -- { child, min, desired, stretch, final }
	local total_min = 0
	local desired_extra = 0
	local stretch_avail = 0
	local stretch_ratio_total = 0

	for _, c in ipairs(children) do
		local mw = c:getCombinedMinimumSize()
		local dw = c:getDesiredSize()
		local will_stretch = hasFlag(c.h_size_flags, SZ.EXPAND)
		local entry = {
			child = c,
			min = mw,
			desired = dw,
			stretch = will_stretch,
			final = mw,
		}
		table.insert(cache, entry)
		total_min = total_min + mw
		if dw > mw then
			desired_extra = desired_extra + (dw - mw)
		end
		if will_stretch then
			stretch_avail = stretch_avail + mw
			stretch_ratio_total = stretch_ratio_total + (c.stretch_ratio or 1)
		end
	end

	local max_space = container_w - self.separation * (#children - 1)
	local stretch_diff = math.max(0, max_space - total_min)
	stretch_avail = stretch_avail + stretch_diff

	--------------------------------------------------
	-- 第二趟 A：先分配 desired_size（"我需要这么多"）
	-- 参考 Godot box_container.cpp:100
	--------------------------------------------------
	if stretch_diff > 0 and desired_extra > 0 then
		local space_ratio = math.min(stretch_diff / desired_extra, 1.0)
		for _, entry in ipairs(cache) do
			if entry.desired > entry.min then
				local inc = math.floor((entry.desired - entry.min) * space_ratio)
				if entry.stretch then
					-- 提高 min，防止 stretch 把它缩回去
					entry.min = entry.min + inc
				else
					-- 非 stretch 孩子：从 stretch 池扣除
					stretch_avail = stretch_avail - inc
				end
				entry.final = entry.final + inc
			end
		end
	end

	--------------------------------------------------
	-- 第二趟 B：按 stretch_ratio 比例分配剩余（"我贪婪"）
	--------------------------------------------------
	while stretch_ratio_total > 0 do
		local ok = true
		for _, entry in ipairs(cache) do
			if entry.stretch then
				local ratio = entry.child.stretch_ratio or 1
				local size = stretch_avail * ratio / stretch_ratio_total
				if size < entry.min then
					-- 装不下 → 移出 stretch 池，重新分配
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
	-- alignment（无 EXPAND 孩子时整体偏移）
	-- 参考 Godot box_container.cpp:190
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
		-- "begin" → offset = 0
	end

	--------------------------------------------------
	-- 第三趟：fitChildInRect 逐个定位
	--------------------------------------------------
	for i, entry in ipairs(cache) do
		local w = entry.final
		-- 最后一个 EXPAND 孩子吸收所有舍入误差
		-- 参考 Godot box_container.cpp:211
		if entry.stretch and i == #cache then
			w = container_w - offset
		end

		self:fitChildInRect(entry.child, offset, 0, w, container_h)
		offset = offset + w + self.separation
	end
end

function HBoxContainer:_hasStretched(cache)
	for _, entry in ipairs(cache) do
		if entry.stretch then
			return true
		end
	end
	return false
end

return HBoxContainer
