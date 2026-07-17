--------------------------------------------------
-- widget_palette.lua — Widget 类型面板
-- 职责：展示可用 widget 类型，点击创建并添加到选中的父容器
--------------------------------------------------

local Widget = require "ui.widgets.widget"
local Panel = require "ui.widgets.panel"
local Text = require "ui.widgets.text"
local Image = require "ui.widgets.image"
local Scroll = require "ui.widgets.containers.scroll_container"
local BoxContainer = require "ui.widgets.containers.box_container"
local Utils = require "ui.utils"

local uc = Utils.UI_COLORS
local ROW_H = 26
local GAP = 1
local ICON_SZ = 14

--------------------------------------------------
-- 图标生成（Canvas → 纹理，惰性缓存）
--------------------------------------------------

local _iconCache = {}

local _ICON_DRAW = {
	Panel = function(w, h)
		local c = 0.45; love.graphics.setColor(c, c + 0.1, c + 0.2)
		love.graphics.rectangle("fill", 0, 1, w, h - 2)
		love.graphics.setColor(c + 0.15, c + 0.25, c + 0.35)
		love.graphics.rectangle("line", 0, 1, w, h - 2)
	end,
	Text = function(w, h)
		love.graphics.setColor(0.7, 0.75, 0.8)
		for i = 0, 2 do
			local y = 3 + i * 4
			local tw = w - 4 - i * 2
			love.graphics.rectangle("fill", 2, y, tw, 2)
		end
	end,
	Button = function(w, h)
		love.graphics.setColor(0.45, 0.5, 0.6)
		love.graphics.rectangle("fill", 1, 2, w - 2, h - 4, 3, 3)
		love.graphics.setColor(0.6, 0.65, 0.75)
		love.graphics.rectangle("line", 1, 2, w - 2, h - 4, 3, 3)
		love.graphics.setColor(0.8, 0.8, 0.85)
		love.graphics.rectangle("fill", w / 2 - 3, h / 2 - 1, 6, 2)
	end,
	Image = function(w, h)
		love.graphics.setColor(0.5, 0.7, 0.9); love.graphics.rectangle("fill", 0, 5, w, h - 5)
		love.graphics.setColor(1, 0.85, 0.3);  love.graphics.circle("fill", w - 4, 4, 3)
		love.graphics.setColor(0.3, 0.6, 0.35); love.graphics.polygon("fill", 1, h - 2, 3, 4, 5, h - 2)
	end,
	BoxContainer = function(w, h)
		love.graphics.setColor(0.45, 0.55, 0.65)
		for i = 0, 2 do
			local y = 2 + i * 4
			love.graphics.rectangle("fill", 2, y, w - 4, 3)
		end
	end,
	HBoxContainer = function(w, h)
		love.graphics.setColor(0.45, 0.55, 0.65)
		for i = 0, 2 do
			local x = 2 + i * 4
			love.graphics.rectangle("fill", x, 2, 3, h - 4)
		end
	end,
	MarginContainer = function(w, h)
		love.graphics.setColor(0.45, 0.55, 0.65)
		love.graphics.rectangle("line", 1, 1, w - 2, h - 2)
		love.graphics.setColor(0.55, 0.65, 0.75)
		love.graphics.rectangle("fill", 3, 3, w - 6, h - 6)
		love.graphics.setColor(0.45, 0.55, 0.65)
		love.graphics.rectangle("line", 3, 3, w - 6, h - 6)
	end,
	CenterContainer = function(w, h)
		love.graphics.setColor(0.45, 0.55, 0.65)
		love.graphics.rectangle("line", 1, 1, w - 2, h - 2)
		love.graphics.setColor(0.65, 0.7, 0.8)
		love.graphics.circle("fill", w / 2, h / 2, 3)
	end,
	TextInput = function(w, h)
		love.graphics.setColor(0.5, 0.55, 0.6)
		love.graphics.rectangle("line", 1, 2, w - 2, h - 4)
		love.graphics.setColor(0.75, 0.8, 0.85)
		love.graphics.line(4, h / 2, w - 6, h / 2)
		love.graphics.setColor(0.9, 0.9, 0.9)
		love.graphics.line(w - 5, h / 2 - 3, w - 5, h / 2 + 3)
	end,
	Checkbox = function(w, h)
		love.graphics.setColor(0.5, 0.55, 0.65)
		love.graphics.rectangle("line", 1, 1, w - 2, h - 2)
		love.graphics.setColor(0.4, 0.7, 0.5)
		love.graphics.setLineWidth(2)
		love.graphics.line(3, h / 2, w / 2, h - 4)
		love.graphics.line(w / 2, h - 4, w - 3, 2)
		love.graphics.setLineWidth(1)
	end,
	ProgressBar = function(w, h)
		love.graphics.setColor(0.4, 0.45, 0.55)
		love.graphics.rectangle("fill", 1, 1, w - 2, h - 2)
		love.graphics.setColor(0.35, 0.65, 0.5)
		love.graphics.rectangle("fill", 1, 1, w * 0.65, h - 2)
		love.graphics.setColor(0.55, 0.6, 0.7)
		love.graphics.rectangle("line", 1, 1, w - 2, h - 2)
	end,
	SliderBar = function(w, h)
		love.graphics.setColor(0.4, 0.45, 0.55)
		love.graphics.rectangle("fill", 1, h / 2 - 2, w - 2, 4)
		love.graphics.setColor(0.65, 0.7, 0.8)
		love.graphics.circle("fill", w * 0.6, h / 2, 4)
		love.graphics.setColor(0.8, 0.8, 0.85)
		love.graphics.circle("fill", w * 0.6, h / 2, 2)
	end,
	Scroll = function(w, h)
		love.graphics.setColor(0.5, 0.55, 0.65)
		love.graphics.rectangle("line", 1, 1, w - 2, h - 2)
		love.graphics.setColor(0.55, 0.6, 0.7)
		love.graphics.rectangle("fill", w - 5, 2, 4, h * 0.45)
		-- arrows
		love.graphics.setColor(0.65, 0.7, 0.8)
		love.graphics.polygon("fill", 3, 4, w / 2, 1, w - 3, 4)
		love.graphics.polygon("fill", 3, h - 4, w / 2, h - 1, w - 3, h - 4)
	end,
	Spacer = function(w, h)
		love.graphics.setColor(0.5, 0.55, 0.6)
		love.graphics.setLineWidth(1.5)
		local cx = w / 2
		love.graphics.line(cx - 4, 3, cx, 1); love.graphics.line(cx + 4, 3, cx, 1)
		love.graphics.line(cx - 4, h - 3, cx, h - 1); love.graphics.line(cx + 4, h - 3, cx, h - 1)
		love.graphics.line(cx, 2, cx, h - 2)
		love.graphics.setLineWidth(1)
	end,
}

local function makeIcon(drawFn)
	local canvas = love.graphics.newCanvas(ICON_SZ, ICON_SZ)
	local prev = love.graphics.getCanvas()
	love.graphics.setCanvas(canvas)
	love.graphics.clear(0, 0, 0, 0)
	drawFn(ICON_SZ, ICON_SZ)
	love.graphics.setCanvas(prev)
	return canvas
end

local function getIcon(key)
	if _iconCache[key] then return _iconCache[key] end
	local fn = _ICON_DRAW[key]
	if fn then
		_iconCache[key] = makeIcon(fn)
	end
	return _iconCache[key]
end

--------------------------------------------------
-- Widget 类型定义
--------------------------------------------------

local WIDGET_TYPES = {
	"Panel",
	"Text",
	"Button",
	"Image",
	"BoxContainer",
	"HBoxContainer",
	"MarginContainer",
	"CenterContainer",
	"TextInput",
	"Checkbox",
	"ProgressBar",
	"SliderBar",
	"Scroll",
	"Spacer",
}

--------------------------------------------------
-- 工厂：根据类型名创建默认 widget
--------------------------------------------------

local WIDGET_FACTORY = {}

function WIDGET_FACTORY.Panel()
	return Panel({
		w = 120, h = 80,
		bg_color = uc.SURFACE,
		outline_width = 1,
		outline_color = uc.LINE,
		rounding_radius = 4,
	})
end

function WIDGET_FACTORY.Text()
	return Text({
		text = "Label",
		font_size = 14,
		h = 20,
		text_color = uc.PRIMARY_TEXT,
	})
end

function WIDGET_FACTORY.Button()
	return require("ui.widgets.button")({
		text = "Button",
		w = 80, h = 28,
	})
end

function WIDGET_FACTORY.Image()
	local img = require("ui.widgets.image")({
		w = 64, h = 64,
	})
	img._mui_type = "Image"
	return img
end

function WIDGET_FACTORY.BoxContainer()
	local bc = require("ui.widgets.containers.box_container")({
		orientation = "vertical",
		auto_size = true,
		bg_color = { uc.SURFACE[1], uc.SURFACE[2], uc.SURFACE[3], 0.3 },
		outline_width = 1,
		outline_color = { uc.LINE[1], uc.LINE[2], uc.LINE[3], 0.5 },
		rounding_radius = 4,
	})
	bc._mui_type = "BoxContainer"
	bc.transform:setSize(80, 40)
	return bc
end

function WIDGET_FACTORY.HBoxContainer()
	local bc = require("ui.widgets.containers.box_container")({
		orientation = "horizontal",
		auto_size = true,
		bg_color = { uc.SURFACE[1], uc.SURFACE[2], uc.SURFACE[3], 0.3 },
		outline_width = 1,
		outline_color = { uc.LINE[1], uc.LINE[2], uc.LINE[3], 0.5 },
		rounding_radius = 4,
	})
	bc._mui_type = "HBoxContainer"
	bc.transform:setSize(80, 40)
	return bc
end

function WIDGET_FACTORY.MarginContainer()
	local mc = require("ui.widgets.containers.margin_container")({
		margin_left = 8, margin_right = 8,
		margin_top = 8, margin_bottom = 8,
		bg_color = { uc.SURFACE[1], uc.SURFACE[2], uc.SURFACE[3], 0.3 },
		outline_width = 1,
		outline_color = { uc.LINE[1], uc.LINE[2], uc.LINE[3], 0.5 },
		rounding_radius = 4,
	})
	mc._mui_type = "MarginContainer"
	mc.transform:setSize(80, 40)
	return mc
end

function WIDGET_FACTORY.CenterContainer()
	local cc = require("ui.widgets.containers.center_container")({
		bg_color = { uc.SURFACE[1], uc.SURFACE[2], uc.SURFACE[3], 0.3 },
		outline_width = 1,
		outline_color = { uc.LINE[1], uc.LINE[2], uc.LINE[3], 0.5 },
		rounding_radius = 4,
	})
	cc._mui_type = "CenterContainer"
	cc.transform:setSize(80, 40)
	return cc
end

function WIDGET_FACTORY.TextInput()
	return require("ui.widgets.textinput")({
		w = 120, h = 28,
		single_line = true,
		text = "",
	})
end

function WIDGET_FACTORY.Checkbox()
	return require("ui.widgets.checkbox")({
		text = "Option",
	})
end

function WIDGET_FACTORY.ProgressBar()
	return require("ui.widgets.progressbar")({
		w = 120, h = 16,
		value = 50,
	})
end

function WIDGET_FACTORY.SliderBar()
	return require("ui.widgets.sliderbar")({
		w = 120, h = 16,
	})
end

function WIDGET_FACTORY.Scroll()
	local sc = require("ui.widgets.containers.scroll_container")({
		w = 100, h = 100,
	})
	sc._mui_type = "Scroll"
	return sc
end

function WIDGET_FACTORY.Spacer()
	local sp = require("ui.widgets.spacer")({})
	sp._mui_type = "Spacer"
	return sp
end

--------------------------------------------------
-- 公共：创建 widget（供外部使用）
--------------------------------------------------

local _createCounter = 0

local function createWidget(widgetType)
	local factory = WIDGET_FACTORY[widgetType]
	if not factory then
		print("WidgetPalette: unknown type " .. widgetType)
		return nil
	end
	local w = factory()
	if w then
		w._mui_type = widgetType
		w._mui_id = widgetType:lower() .. "_" .. math.random(100, 999)
		w._name = widgetType .. " (" .. w._mui_id .. ")"

		_createCounter = _createCounter + 1
		local ox = 20 + (_createCounter % 5) * 30
		local oy = 20 + math.floor(_createCounter / 5) * 30
		w.transform:setPadding(ox, nil, oy, nil)
	end
	return w
end

--------------------------------------------------
-- Palette UI
--------------------------------------------------

local Palette = Class(Widget, function(self, datas)
	Widget.new(self, "WidgetPalette", datas)
	self.raycast_target = true
	self.onWidgetCreate = nil
	self:_buildUI()
end)

function Palette:_buildUI()
	-- 标题
	self:addChild(Text({
		text = "Widgets",
		font_size = 11,
		font_key = "default_bold",
		text_color = uc.HINT,
		h = 18,
		anchor = {0, 0, 1, 0},
		padding = {8, 8, 2, 0},
	}))

	-- 可滚动类型列表
	local scroll = self:addChild(Scroll({
		anchor = {0, 0, 1, 1},
		padding = {2, 2, 22, 2},
		enable_scroll_h = false,
	}))

	local list = BoxContainer({
		orientation = "vertical",
		auto_size = true,
		anchor = {0, 0, 1, 0},
		separation = GAP,
	})
	scroll:setItem(list)
	scroll:setScrollableH(0)

	for _, name in ipairs(WIDGET_TYPES) do
		local row = self:_makeRow(name)
		list:addChild(row)
	end
end

function Palette:_makeRow(widgetName)
	local row = Widget({
		anchor = {0, 0, 1, 0},
		h = ROW_H,
		raycast_target = true,
	})
	row:setCustomMinimumSize(nil, ROW_H)

	-- 背景（hover 变色用）
	local bg = row:addChild(Panel({
		bg_color = {0, 0, 0, 0},
		rounding_radius = 4,
		anchor = {0, 0, 1, 1},
		padding = {2, 2, 0, 0},
	}))
	bg.raycast_target = false

	-- 图标
	local tex = getIcon(widgetName)
	if tex then
		local icon = row:addChild(Image({
			texture = tex,
			anchor = {0, 0, 0, 0},
			padding = {6, 0, (ROW_H - ICON_SZ) / 2, 0},
			w = ICON_SZ,
			h = ICON_SZ,
		}))
		icon.raycast_target = false
	end

	-- 标签（左对齐）
	local label = row:addChild(Text({
		text = widgetName,
		font_size = 11,
		text_color = uc.SECONDARY_TEXT,
		h_align = "left",
		v_align = "center",
		anchor = {0, 0, 1, 0},
		padding = {ICON_SZ + 10, 6, 0, 0},
		h = ROW_H,
	}))
	label.raycast_target = false

	-- 点击
	row.onMousePressed = function(r, mx, my, btn)
		if btn == 1 and r:regionDetection(mx, my) and self.onWidgetCreate then
			self.onWidgetCreate(widgetName)
			return true
		end
		return false
	end

	-- hover 效果
	row._hover_bg = bg
	row.onMouseMoved = function(r, mx, my)
		local inside = r:regionDetection(mx, my)
		if inside and not r._was_hover then
			bg.bg_color = { uc.BTN_HOVER[1], uc.BTN_HOVER[2], uc.BTN_HOVER[3], uc.BTN_HOVER[4] }
			r._was_hover = true
		elseif not inside and r._was_hover then
			bg.bg_color = {0, 0, 0, 0}
			r._was_hover = nil
		end
	end

	return row
end

--------------------------------------------------
-- 对外导出 createWidget 工厂函数
--------------------------------------------------
Palette.createWidget = createWidget

return Palette
