--------------------------------------------------
-- VirtualListItem — VirtualList 的元素基类
--
-- 子类必须覆写：
--   getItemSize() → along_size  沿主轴方向的固定尺寸（像素）
--   bindData(data, index)        填充数据，data 可能为 nil（无数据）
--------------------------------------------------

local Widget = require "ui.widgets.widget"
local Class = require "dependencies.classic"

--[[datas: 此处不包括基类所支持的字段
	（VirtualListItem 无额外 datas 字段，由子类定义）
]]
local VirtualListItem = Class(Widget, function(self, datas, theme)
	Widget.new(self, "VirtualListItem", datas, theme)
end)

--- 返回沿主轴方向的固定尺寸。子类必须覆写。
--- 对于 vertical 列表返回高度，horizontal 列表返回宽度。
---@return number along_size
function VirtualListItem:getItemSize()
	error("VirtualListItem subclass must implement getItemSize()")
end

--- 用指定索引的数据填充控件。子类必须覆写。
--- data 可能为 nil（索引超出数据范围时）。
---@param data  table|nil  数据项
---@param index number     数据索引（0-based）
function VirtualListItem:bindData(data, index)
	error("VirtualListItem subclass must implement bindData(data, index)")
end

return VirtualListItem
