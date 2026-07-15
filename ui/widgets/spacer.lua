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

local Spacer = Class(Widget, function(self)
	Widget.new(self, "Spacer")
	self.raycast_target = false
	-- 两个轴都 EXPAND+FILL，父容器决定哪个轴生效
	self.h_size_flags = Utils.SIZE_FLAGS.FILL + Utils.SIZE_FLAGS.EXPAND
	self.v_size_flags = Utils.SIZE_FLAGS.FILL + Utils.SIZE_FLAGS.EXPAND
	self.stretch_ratio = 1.0
end)

return Spacer
