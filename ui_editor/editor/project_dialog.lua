--------------------------------------------------
-- project_dialog.lua — 启动时的项目选择对话框
-- 显示最近使用的项目列表，支持选择、浏览新目录、新建项目
--------------------------------------------------

local Widget = require "ui.widgets.widget"
local Panel = require "ui.widgets.panel"
local Text = require "ui.widgets.text"
local Button = require "ui.widgets.button"
local BoxContainer = require "ui.widgets.containers.box_container"
local Scroll = require "ui.widgets.containers.scroll_container"
local UiManager = require "ui.ui_manager"
local Utils = require "ui.utils"
local FileUtils = require "ui_editor.editor.file_utils"

local uc = Utils.UI_COLORS

local DIALOG_W, DIALOG_H = 480, 360
local ITEM_H = 32

local CONFIG_PATH = "ui_editor/projects_config.json"

--------------------------------------------------
-- 加载配置
--------------------------------------------------
local function loadConfig()
	local f = io.open(CONFIG_PATH, "r")
	if not f then return { recent_projects = {} } end
	local content = f:read("*a")
	f:close()
	local ok, data = pcall(function() return require("ui_editor.runtime.json").decode(content) end)
	if ok and data then return data end
	return { recent_projects = {} }
end

--------------------------------------------------
-- 保存配置
--------------------------------------------------
local function saveConfig(config)
	local Json = require "ui_editor.runtime.json"
	local content = Json.encode(config)
	local f = io.open(CONFIG_PATH, "w")
	if f then
		f:write(content)
		f:close()
	end
end

--------------------------------------------------
-- 添加项目到最近列表
--------------------------------------------------
local function addRecentProject(path)
	local config = loadConfig()
	local recent = config.recent_projects or {}
	for i = #recent, 1, -1 do
		if recent[i] == path then
			table.remove(recent, i)
		end
	end
	table.insert(recent, 1, path)
	if #recent > 10 then
		recent = {table.unpack(recent, 1, 10)}
	end
	config.recent_projects = recent
	saveConfig(config)
end

--------------------------------------------------
-- 展示项目选择对话框
--------------------------------------------------
local function show(on_select)
	local config = loadConfig()
	local recent = config.recent_projects or {}

	local popup = Widget({ anchor={0,0,1,1}, padding={0,0,0,0}, raycast_target=true })
	popup.render_layer = Utils.RENDER_LAYERS.DROPDOWN

	local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()
	local dx, dy = (sw - DIALOG_W) / 2, (sh - DIALOG_H) / 2

	local overlay = popup:addChild(Panel({
		bg_color = {0, 0, 0, 0.5}, rounding_radius = 0,
		anchor = {0, 0, 1, 1}, padding = {0, 0, 0, 0},
	}))
	overlay.raycast_target = false

	local dialog_bg = popup:addChild(Panel({
		bg_color = {0.16, 0.16, 0.2, 1}, outline_width = 1,
		outline_color = uc.LINE, rounding_radius = 8,
		anchor = {0, 0, 0, 0}, padding = {dx, 0, dy, 0},
		w = DIALOG_W, h = DIALOG_H,
	}))
	dialog_bg.raycast_target = false

	popup:addChild(Text({
		text = "Muse UI Editor", font_size = 18, font_key = "default_bold",
		text_color = uc.TITLE, h = 28,
		anchor = {0, 0, 0, 0}, padding = {dx + 20, 0, dy + 16, 0},
	}))

	popup:addChild(Text({
		text = "Select a project folder, or create a new one", font_size = 11,
		text_color = uc.HINT, h = 18,
		anchor = {0, 0, 0, 0}, padding = {dx + 20, 0, dy + 44, 0},
	}))

	local list_x, list_y = dx + 20, dy + 72
	local list_w, list_h = DIALOG_W - 40, DIALOG_H - 168

	if #recent > 0 then
		popup:addChild(Text({
			text = "Recent projects:", font_size = 11,
			text_color = uc.SECONDARY_TEXT, h = 18,
			anchor = {0, 0, 0, 0}, padding = {list_x, 0, list_y, 0},
		}))
		list_y = list_y + 20
		list_h = list_h - 20
	end

	local list_bg = popup:addChild(Panel({
		bg_color = {0.1, 0.1, 0.13, 1}, outline_width = 1,
		outline_color = uc.LINE, rounding_radius = 4,
		anchor = {0, 0, 0, 0}, padding = {list_x, 0, list_y, 0},
		w = list_w, h = list_h,
	}))
	list_bg.raycast_target = false

	if #recent == 0 then
		popup:addChild(Text({
			text = "No recent projects.\nUse the buttons below to browse or create one.",
			font_size = 12, text_color = uc.HINT,
			h_align = "center", v_align = "center",
			anchor = {0, 0, 0, 0},
			padding = {list_x, 0, list_y, 0},
			w = list_w, h = list_h,
		}))
	end

	local scroll = popup:addChild(Scroll({
		anchor = {0, 0, 0, 0},
		padding = {list_x + 2, 0, list_y + 2, 0},
		w = list_w - 4, h = list_h - 4,
		enable_scroll_h = false,
	}))
	scroll.raycast_target = false

	local item_container = BoxContainer({
		auto_size = true, anchor = {0, 0, 1, 0},
		separation = 2,
	})
	item_container.raycast_target = false
	scroll:setItem(item_container)
	scroll:setScrollableH(0)

	local item_rows = {}

	for i, proj_path in ipairs(recent) do
		local row = Widget({ anchor={0,0,1,0}, h=ITEM_H })
		row:setCustomMinimumSize(nil, ITEM_H)

		local display = proj_path
		if #display > 60 then
			display = "..." .. display:sub(-57)
		end

		row:addChild(Text({
			text = "  " .. display, font_size = 12,
			text_color = uc.PRIMARY_TEXT, v_align = "center",
			h = ITEM_H, anchor = {0, 0, 1, 0},
			padding = {8, 0, 0, 0},
		}))

		row._project_path = proj_path
		item_container:addChild(row)
		table.insert(item_rows, row)
	end
	item_container:queueSort()

	local btn_y = dy + DIALOG_H - 48

	popup:addChild(Button({
		text = "Browse...", font_size = 12, w = 100, h = 28,
		anchor = {0, 0, 0, 0},
		padding = {dx + 20, 0, btn_y, 0},
		on_click = function()
			popup:hide()
			local dir = FileUtils.nativeSelectFolder(".")
			if dir then
				addRecentProject(dir)
				popup._destroy = true
				if on_select then on_select(dir) end
			else
				popup:show()
			end
		end,
	}))

	popup:addChild(Button({
		text = "New Project...", font_size = 12, w = 110, h = 28,
		anchor = {0, 0, 0, 0},
		padding = {dx + 128, 0, btn_y, 0},
		on_click = function()
			popup:hide()
			local dir = FileUtils.nativeSelectFolder(".")
			if dir then
				FileUtils.createDirectory(dir)
				addRecentProject(dir)
				popup._destroy = true
				if on_select then on_select(dir) end
			else
				popup:show()
			end
		end,
	}))

	popup._closed = false

	local hovered_item = nil

	local function getItemAt(sx, sy)
		for i, row in ipairs(item_rows) do
			local rx, ry = row.transform:getGlobalPosition()
			if sx >= rx and sx <= rx + list_w - 4 and
			   sy >= ry and sy <= ry + ITEM_H then
				return row, i
			end
		end
		return nil
	end

	function popup.onMousePressed(self, mx, my, btn)
		if btn ~= 1 then return false end
		if mx < dx or mx > dx + DIALOG_W or my < dy or my > dy + DIALOG_H then
			popup:hide(); popup._destroy = true
			return true
		end
		local row = getItemAt(mx, my)
		if row and row._project_path then
			local proj = row._project_path
			addRecentProject(proj)
			popup:hide(); popup._destroy = true
			if on_select then on_select(proj) end
			return true
		end
		return true
	end

	function popup.onMouseMoved(self, mx, my, dx_, dy_)
		local row = getItemAt(mx, my)
		if row ~= hovered_item then
			hovered_item = row
		end
		return false
	end

	function popup.onMouseReleased(self, mx, my, btn)
		return true
	end

	local draw_layer = popup:addChild(Widget({ anchor={0,0,0,0}, padding={0,0,0,0}, w=0, h=0 }))
	draw_layer.raycast_target = false

	function draw_layer.onDraw(self)
		if not hovered_item then return end
		local rx, ry = hovered_item.transform:getGlobalPosition()
		love.graphics.setColor(1, 1, 1, 0.06)
		love.graphics.rectangle("fill", rx, ry, list_w - 4, ITEM_H)
		love.graphics.setColor(1, 1, 1, 1)
	end

	function popup.onUpdate(self, dt)
		if popup._destroy then
			UiManager:GetInstance():removeWidget(popup)
		end
	end

	UiManager:GetInstance():addWidget(popup)
	return popup
end

return {
	show = show,
	loadConfig = loadConfig,
	saveConfig = saveConfig,
	addRecentProject = addRecentProject,
}
