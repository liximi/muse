--------------------------------------------------
-- file_dialog.lua — 文件浏览对话框（保留备用）
-- 模态弹窗，支持目录导航、.mui 文件列表、保存/打开模式
-- 目前已被原生系统对话框替代，保留供未来使用
--------------------------------------------------

local Widget = require "ui.widgets.widget"
local Panel = require "ui.widgets.panel"
local Text = require "ui.widgets.text"
local TextInput = require "ui.widgets.textinput"
local Button = require "ui.widgets.button"
local BoxContainer = require "ui.widgets.containers.box_container"
local Scroll = require "ui.widgets.containers.scroll_container"
local UiManager = require "ui.ui_manager"
local Utils = require "ui.utils"
local FileUtils = require "ui_editor.editor.file_utils"

local uc = Utils.UI_COLORS

local DIALOG_W, DIALOG_H = 500, 420
local ITEM_H = 24

local function show(mode, start_dir, on_confirm, on_cancel)
	start_dir = start_dir or "."
	mode = mode or "open"

	local current_dir = start_dir
	local selected_file = nil
	local items = {}

	local function refreshItems()
		items = {}
		local raw = FileUtils.listDirectory(current_dir)
		for _, entry in ipairs(raw) do
			if entry.is_dir then
				table.insert(items, entry)
			elseif FileUtils.getExtension(entry.name) == "mui" then
				table.insert(items, entry)
			elseif mode == "save" then
				table.insert(items, entry)
			end
		end
		table.sort(items, function(a, b)
			if a.is_dir ~= b.is_dir then return a.is_dir end
			return a.name:lower() < b.name:lower()
		end)
		selected_file = nil
	end

	local popup = Widget({ anchor={0,0,1,1}, padding={0,0,0,0}, raycast_target=true })
	popup.render_layer = Utils.RENDER_LAYERS.DROPDOWN

	local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()
	local dx, dy = (sw - DIALOG_W) / 2, (sh - DIALOG_H) / 2

	local overlay = popup:addChild(Panel({
		bg_color = {0, 0, 0, 0.4}, rounding_radius = 0,
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

	local title_text = (mode == "save") and "Save .mui File" or "Open .mui File"
	local title = popup:addChild(Text({
		text = title_text, font_size = 14, font_key = "default_bold",
		text_color = uc.TITLE, h = 24,
		anchor = {0, 0, 0, 0}, padding = {dx + 16, 0, dy + 12, 0},
	}))
	title.raycast_target = false

	local path_label = popup:addChild(Text({
		text = current_dir, font_size = 10, text_color = uc.HINT,
		h = 18, anchor = {0, 0, 0, 0},
		padding = {dx + 16, 0, dy + 38, 0},
	}))
	path_label.raycast_target = false

	local list_x, list_y = dx + 16, dy + 60
	local list_w, list_h = DIALOG_W - 32, DIALOG_H - 170

	local list_bg = popup:addChild(Panel({
		bg_color = {0.1, 0.1, 0.13, 1}, outline_width = 1,
		outline_color = uc.LINE, rounding_radius = 4,
		anchor = {0, 0, 0, 0}, padding = {list_x, 0, list_y, 0},
		w = list_w, h = list_h,
	}))
	list_bg.raycast_target = false

	local scroll = popup:addChild(Scroll({
		anchor = {0, 0, 0, 0},
		padding = {list_x + 2, 0, list_y + 2, 0},
		w = list_w - 4, h = list_h - 4,
		enable_scroll_h = false,
	}))
	scroll.raycast_target = false

	local item_container = BoxContainer({
		auto_size = true, anchor = {0, 0, 1, 0},
		separation = 0,
	})
	item_container.raycast_target = false
	scroll:setItem(item_container)
	scroll:setScrollableH(0)

	local item_rows = {}

	local function buildItemRows()
		item_container:clearChildren()
		item_rows = {}

		local parent_dir = FileUtils.getParentPath(current_dir)
		if parent_dir ~= current_dir then
			local row = Widget({ anchor={0,0,1,0}, h=ITEM_H })
			row:setCustomMinimumSize(nil, ITEM_H)
			row:addChild(Text({
				text = "..", font_size = 12, text_color = uc.PRIMARY_TEXT,
				v_align = "center", h = ITEM_H,
				anchor = {0, 0, 1, 0}, padding = {8, 0, 0, 0},
			}))
			row._dir = parent_dir
			row._is_parent = true
			item_container:addChild(row)
			table.insert(item_rows, row)
		end

		for _, entry in ipairs(items) do
			local row = Widget({ anchor={0,0,1,0}, h=ITEM_H })
			row:setCustomMinimumSize(nil, ITEM_H)
			local prefix = entry.is_dir and "[+] " or "    "
			local color = entry.is_dir and {0.55, 0.7, 1, 1} or uc.PRIMARY_TEXT
			row:addChild(Text({
				text = prefix .. entry.name, font_size = 12,
				text_color = color, v_align = "center", h = ITEM_H,
				anchor = {0, 0, 1, 0}, padding = {8, 0, 0, 0},
			}))
			row._entry = entry
			if not entry.is_dir and entry.name == selected_file then
				row._selected = true
			end
			item_container:addChild(row)
			table.insert(item_rows, row)
		end

		if #items == 0 and (not parent_dir or parent_dir == current_dir) then
			local row = Widget({ anchor={0,0,1,0}, h=ITEM_H })
			row:setCustomMinimumSize(nil, ITEM_H)
			row:addChild(Text({
				text = "(empty)", font_size = 11,
				text_color = uc.HINT, v_align = "center", h = ITEM_H,
				anchor = {0, 0, 1, 0}, padding = {8, 0, 0, 0},
			}))
			item_container:addChild(row)
			table.insert(item_rows, row)
		end

		item_container:queueSort()
	end

	refreshItems()
	buildItemRows()

	local filename_input
	if mode == "save" then
		local fl_y = dy + DIALOG_H - 100
		popup:addChild(Text({
			text = "Filename:", font_size = 11, text_color = uc.SECONDARY_TEXT,
			h = 20, anchor = {0, 0, 0, 0},
			padding = {dx + 16, 0, fl_y, 0},
		}))

		filename_input = popup:addChild(TextInput({
			text = selected_file or "untitled.mui", font_size = 12,
			text_color = uc.PRIMARY_TEXT, single_line = true,
			bg = Panel({ bg_color={0.1,0.1,0.13,1}, outline_width=1,
				outline_color=uc.LINE, rounding_radius=4 }),
			anchor = {0, 0, 0, 0},
			w = DIALOG_W - 32, h = 26,
			padding = {dx + 16, 0, fl_y + 22, 0},
		}))
		if filename_input.bg then
			filename_input.bg.raycast_target = false
		end
	end

	local btn_y = dy + DIALOG_H - 48
	local confirm_label = (mode == "save") and "Save" or "Open"

	local cancel_btn = popup:addChild(Button({
		text = "Cancel", font_size = 12, w = 72, h = 28,
		anchor = {0, 0, 0, 0},
		padding = {dx + DIALOG_W - 172, 0, btn_y, 0},
		on_click = function()
			if on_cancel then on_cancel() end
			popup:hide(); popup._destroy = true
		end,
	}))

	local confirm_btn = popup:addChild(Button({
		text = confirm_label, font_size = 12, w = 72, h = 28,
		anchor = {0, 0, 0, 0},
		padding = {dx + DIALOG_W - 88, 0, btn_y, 0},
		on_click = function()
			local path
			if mode == "save" then
				local fname = filename_input:getText()
				if not fname or fname == "" then return end
				if not fname:lower():match("%.mui$") then
					fname = fname .. ".mui"
				end
				path = FileUtils.joinPath(current_dir, fname)
			else
				if not selected_file then return end
				path = FileUtils.joinPath(current_dir, selected_file)
			end
			if on_confirm then on_confirm(path) end
			popup:hide(); popup._destroy = true
		end,
	}))

	popup._closed = false
	local function close()
		if popup._closed then return end
		popup._closed = true
		if on_cancel then on_cancel() end
		popup:hide(); popup._destroy = true
	end

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
			close()
			return true
		end
		local row = getItemAt(mx, my)
		if row then
			if row._is_parent then
				current_dir = row._dir
				refreshItems()
				buildItemRows()
				path_label:setText(current_dir)
				return true
			elseif row._entry then
				if row._entry.is_dir then
					current_dir = FileUtils.joinPath(current_dir, row._entry.name)
					refreshItems()
					buildItemRows()
					path_label:setText(current_dir)
				else
					selected_file = row._entry.name
					if mode == "save" and filename_input then
						filename_input:setText(selected_file)
					end
					buildItemRows()
				end
				return true
			end
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
		if hovered_item._selected then
			love.graphics.setColor(0.3, 0.45, 0.8, 0.25)
			love.graphics.rectangle("fill", rx, ry, list_w - 4, ITEM_H)
			love.graphics.setColor(1, 1, 1, 1)
		end
	end

	function popup.onUpdate(self, dt)
		if popup._destroy then
			UiManager:GetInstance():removeWidget(popup)
		end
	end

	UiManager:GetInstance():addWidget(popup)

	if filename_input then
		filename_input:setFocus()
	end

	return popup
end

return { show = show }
