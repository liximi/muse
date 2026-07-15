--------------------------------------------------
-- BoxContainer — 线性排列子控件（水平 / 垂直）
-- scene/gui/box_container.cpp BoxContainer::_resort
--
-- HBoxContainer = BoxContainer({ orientation = "horizontal" })
-- VBoxContainer = BoxContainer({ orientation = "vertical" })
--
-- 算法（三趟式）：
--   第一趟：收集每个孩子的最小/期望尺寸 + 标记 EXPAND
--   第二趟 A：先分配 desired_size（"我需要这么多"）
--   第二趟 B：按 stretch_ratio 比例分配剩余（"我贪婪"）
--   第三趟：fitChildInRect 逐个定位 + alignment 偏移
--------------------------------------------------

local Container = require "ui.widgets.containers.container"
local Utils = require "ui.utils"
local Class = require "dependencies.classic"

local SZ = Utils.SIZE_FLAGS
local ALIGN = Utils.ALIGNMENT
local ORIENT = Utils.ORIENTATION

--[[datas:
	orientation = "horizontal" | "vertical"  默认 "vertical"
	separation  = number  子控件间距，默认 0
	alignment   = "begin" | "center" | "end"  无 EXPAND 时的整体偏移，默认 "begin"
]]
local BoxContainer = Class(Container, function(self, datas, theme)
	datas = datas or {}
	local orientation = Utils.validateEnum(
		datas.orientation, ORIENT, ORIENT.VERTICAL, "BoxContainer.orientation")
	local is_horizontal = orientation == ORIENT.HORIZONTAL

	Container.new(self, is_horizontal and "HBoxContainer" or "VBoxContainer", datas, theme)

	self._is_horizontal = is_horizontal
	self._auto_size_axis = is_horizontal and "h" or "v"
	self.separation = datas.separation or 0
	self.alignment = datas.alignment or ALIGN.BEGIN
end)

--- 返回容器自身的最小尺寸（子控件推导 + 显式尺寸取 max）
--- box_container.cpp get_minimum_size
function BoxContainer:getMinimumSize()
	local along, cross = 0, 0  -- 主轴总尺寸、交叉轴最大尺寸
	local first = true

	for _, c in ipairs(self.children) do
		if c:isShown() then
			local mw, mh = c:getCombinedMinimumSize()
			local child_along, child_cross
			if self._is_horizontal then
				child_along, child_cross = mw, mh
			else
				child_along, child_cross = mh, mw
			end
			if not first then along = along + self.separation end
			along = along + child_along
			cross = math.max(cross, child_cross)
			first = false
		end
	end

	-- 显式尺寸不低于推导值
	local cw, ch = self.transform:getSize()
	local result_w, result_h
	if self._is_horizontal then
		result_w, result_h = math.max(along, cw), math.max(cross, ch)
	else
		result_w, result_h = math.max(cross, cw), math.max(along, ch)
	end
	print(string.format("[Box.getMinSize] %s along=%.0f cross=%.0f result={%.0f,%.0f}",
		self._name, along, cross, result_w, result_h))
	return result_w, result_h
end

function BoxContainer:_sortChildren()
	local children = self:_visibleChildren()
	if #children == 0 then return end

	local cw, ch = self.transform.w, self.transform.h
	local along_size, cross_size
	if self._is_horizontal then
		along_size, cross_size = cw, ch
	else
		along_size, cross_size = ch, cw
	end

	--------------------------------------------------
	-- 第一趟：收集尺寸 + 标记 stretch
	--------------------------------------------------
	local cache = {}  -- { child, min, desired, stretch, final }
	local total_min = 0
	local desired_extra = 0
	local stretch_avail = 0
	local stretch_ratio_total = 0

	for _, c in ipairs(children) do
		local mw, mh = c:getCombinedMinimumSize()
		local dw, dh = c:getDesiredSize()
		local flags = self._is_horizontal and c.h_size_flags or c.v_size_flags
		local min, desired = self._is_horizontal and mw or mh, self._is_horizontal and dw or dh

		local entry = {
			child = c, min = min, desired = desired,
			stretch = Utils.hasFlag(flags, SZ.EXPAND), final = min,
		}
		table.insert(cache, entry)
		total_min = total_min + min
		if desired > min then
			desired_extra = desired_extra + (desired - min)
		end
		if entry.stretch then
			stretch_avail = stretch_avail + min
			stretch_ratio_total = stretch_ratio_total + (c.stretch_ratio or 1)
		end
	end

	local max_space = along_size - self.separation * (#children - 1)
	local stretch_diff = math.max(0, max_space - total_min)
	stretch_avail = stretch_avail + stretch_diff

	--------------------------------------------------
	-- 第二趟 A：desired_size
	--------------------------------------------------
	if stretch_diff > 0 and desired_extra > 0 then
		local ratio = math.min(stretch_diff / desired_extra, 1.0)
		for _, entry in ipairs(cache) do
			if entry.desired > entry.min then
				local inc = math.floor((entry.desired - entry.min) * ratio)
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
	-- 第二趟 B：stretch_ratio
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
		if ok then break end
	end

	--------------------------------------------------
	-- alignment（无 EXPAND 时整体偏移）
	--------------------------------------------------
	local final_diff = max_space - total_min
	for _, entry in ipairs(cache) do
		final_diff = final_diff - (entry.final - entry.min)
	end
	final_diff = math.max(0, final_diff)

	local offset = 0
	if not self:_hasStretched(cache) then
		if self.alignment == ALIGN.END then
			offset = final_diff
		elseif self.alignment == ALIGN.CENTER then
			offset = math.floor(final_diff / 2)
		end
	end

	--------------------------------------------------
	-- 第三趟：fitChildInRect
	--------------------------------------------------
	for i, entry in ipairs(cache) do
		local size = entry.final
		-- 最后一个 EXPAND 收容舍入误差
		if entry.stretch and i == #cache then
			size = along_size - offset
		end

		local rx, ry, rw, rh
		if self._is_horizontal then
			rx, ry, rw, rh = offset, 0, size, cross_size
		else
			rx, ry, rw, rh = 0, offset, cross_size, size
		end
		self:fitChildInRect(entry.child, rx, ry, rw, rh)
		offset = offset + size + self.separation
	end
end

function BoxContainer:_hasStretched(cache)
	for _, entry in ipairs(cache) do
		if entry.stretch then return true end
	end
	return false
end

--- 添加弹性占位符。后续子控件被推到主轴末端。
--- BoxContainer::add_spacer
function BoxContainer:addSpacer()
	local Spacer = require "ui.widgets.spacer"
	return self:addChild(Spacer())
end

return BoxContainer
