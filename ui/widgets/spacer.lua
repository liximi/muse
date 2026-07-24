--------------------------------------------------
-- Spacer — 不可见的弹性占位控件
-- 参考 Godot BoxContainer::add_spacer
--
-- 用法：
--   hbox:addChild(Spacer())  -- 把所有后续子控件推到右边
--   vbox:addChild(Spacer())  -- 把所有后续子控件推到底部
--------------------------------------------------

local Widget = require "ui.widgets.widget"
local Utils = require "ui.utils"
local Class = require "dependencies.classic"

local Spacer = Class(Widget, function(self, datas)
	Widget.new(self, "Spacer", datas)
	self.raycast_target = false
	-- 两个轴都 EXPAND+FILL，父容器决定哪个轴生效（datas 可覆盖）
	if not datas or datas.h_size_flags == nil then
		self.h_size_flags = Utils.SIZE_FLAGS.FILL + Utils.SIZE_FLAGS.EXPAND
	end
	if not datas or datas.v_size_flags == nil then
		self.v_size_flags = Utils.SIZE_FLAGS.FILL + Utils.SIZE_FLAGS.EXPAND
	end
	if not datas or datas.stretch_ratio == nil then
		self.stretch_ratio = 1.0
	end
end)

return Spacer
