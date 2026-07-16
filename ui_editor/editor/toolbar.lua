--------------------------------------------------
-- toolbar.lua — 编辑器底部工具栏
--------------------------------------------------

local Widget = require "ui.widgets.widget"
local Panel = require "ui.widgets.panel"
local Button = require "ui.widgets.button"
local BoxContainer = require "ui.widgets.containers.box_container"
local Utils = require "ui.utils"

local uc = Utils.UI_COLORS

local TOOLBAR_H = 32
local BTN_W = 56

local function makeToolBtn(text, onClick)
	local btn = Button({
		text = text,
		w = BTN_W,
		h = 22,
		normal = Utils.newButtonStateStyle(text, uc.SECONDARY_TEXT, 11, { 0, 0, 0, 0 }, 0, nil, nil, nil, 0),
		hover = Utils.newButtonStateStyle(nil, uc.PRIMARY_TEXT, 11, uc.BTN_HOVER, 0, nil, nil, nil, 4),
		pressed = Utils.newButtonStateStyle(nil, uc.TITLE, 11, uc.BTN_SELECTED, 0, nil, nil, nil, 4),
		on_click = onClick,
	})
	return btn
end

local Toolbar = Class(Widget, function(self, datas)
	Widget.new(self, "Toolbar", datas)
	self.raycast_target = true
	self.onNew = nil
	self.onOpen = nil
	self.onSave = nil
	self.onExport = nil
	self.onUndo = nil
	self.onRedo = nil

	self:_buildUI()
end)

function Toolbar:_buildUI()
	-- 顶部细线
	self:addChild(Panel({
		bg_color = uc.LINE,
		rounding_radius = 0,
		anchor = { 0, 0, 1, 0 },
		h = 1,
	}))

	-- 按钮行
	local row = self:addChild(BoxContainer({
		orientation = "horizontal",
		separation = 4,
		anchor = { 0, 0, 1, 0 },
		padding = { 8, 8, 5, 5 },
		h = TOOLBAR_H,
	}))
	row:setCustomMinimumSize(nil, TOOLBAR_H)

	row:addChild(makeToolBtn("New", function()
		if self.onNew then self:onNew() end
	end))

	row:addChild(makeToolBtn("Open", function()
		if self.onOpen then self:onOpen() end
	end))

	row:addChild(makeToolBtn("Save", function()
		if self.onSave then self:onSave() end
	end))

	row:addChild(makeToolBtn("Export", function()
		if self.onExport then self:onExport() end
	end))

	-- 分隔
	row:addChild(Panel({
		bg_color = uc.LINE,
		rounding_radius = 0,
		w = 1,
		h = 20,
	}))
	row.children[#row.children]:setCustomMinimumSize(1, 20)

	-- Undo / Redo
	row:addChild(makeToolBtn("Undo", function()
		if self.onUndo then self:onUndo() end
	end))

	row:addChild(makeToolBtn("Redo", function()
		if self.onRedo then self:onRedo() end
	end))
end

return Toolbar
