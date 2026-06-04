local Loc = require "dependencies.i18n.i18n"()
local Lovebird = require "dependencies.Lovebird.Lovebird"
Class = require "dependencies.classic"

local UiManager = require "ui.ui_manager":GetInstance()
local UiUtils = require "ui.utils"
local Fonts = require "ui.fonts"

local Widget = require "ui.widgets.widget"
local Panel = require "ui.widgets.panel"
local Text = require "ui.widgets.text"
local Button = require "ui.widgets.button"
local Scroll = require "ui.widgets.containers.scroll_container"

local languages = {"zh-cn"}

local ui_root
local display_area  -- 右侧展示区，测试脚本将内容加入此容器
local current_test  -- 当前选中的测试模块名称
local gallery_btns = {}  -- 左侧导航按钮列表

-- 加载所有测试模块
local test_modules = {
	require "tests.ui.test_buttons",
	require "tests.ui.test_textinput",
	require "tests.ui.test_checkbox",
	require "tests.ui.test_progressbar",
	require "tests.ui.test_radio",
	require "tests.ui.test_tabview",
	require "tests.ui.test_slider",
	require "tests.ui.test_modal",
	require "tests.ui.test_chat",
}

function love.load()
	-- 加载本地化文本
	for _, lan in ipairs(languages) do
		Loc:load("localization/" .. lan .. ".lua")
	end
	Loc:set_fallback("zh-cn")
	Loc:set_locale("zh-cn")

	love.keyboard.setKeyRepeat(true)

	-- 根容器
	ui_root = UiManager:addWidget(Widget({
		anchor = {0, 0, 1, 1},
		padding = {0, 0, 0, 0},
	}))

	--------------------------------------------------
	-- 左侧导航面板
	--------------------------------------------------
	local sidebar_w = 200
	local left_panel = ui_root:addChild(Panel({
		w = sidebar_w,
		anchor = {0, 0, 0, 1},
		padding = {0, nil, 0, 0},
	}))

	left_panel:addChild(Text({
		text = "UI Gallery",
		font_size = 20,
		font_key = "default_bold",
		h = 28,
		text_color = UiUtils.UI_COLORS.TITLE,
		anchor = {0, 0, 1, 0},
		padding = {16, 16, 12, 0},
	}))

	left_panel:addChild(Text({
		text = "Select a component to view",
		font_size = 12,
		h = 16,
		text_color = UiUtils.UI_COLORS.SECONDARY_TEXT,
		anchor = {0, 0, 1, 0},
		padding = {16, 16, 42, 0},
	}))

	-- 可滚动的导航按钮列表
	local scroll = left_panel:addChild(Scroll({
		anchor = {0, 0, 1, 1},
		padding = {4, 4, 62, 4},
		enable_scroll_h = false,
	}))

	-- 将所有按钮放入一个容器
	local btn_list = Widget()
	local btn_h = 32
	local btn_space = 4
	local total_h = #test_modules * (btn_h + btn_space)

	for i, mod in ipairs(test_modules) do
		local y_pos = (i - 1) * (btn_h + btn_space)
		local btn = Button({
			normal = UiUtils.newButtonStateStyle(mod.name),
			anchor = {0, 0, 1, 0},
			padding = {0, 0, y_pos, 0},
			h = btn_h,
			font_size = 13,
			on_click = function()
				selectTest(i)
			end,
		})
		btn_list:addChild(btn)
		gallery_btns[i] = btn
	end
	btn_list.transform:setSize(nil, total_h)

	scroll:setItem(btn_list)

	--------------------------------------------------
	-- 右侧展示画布
	--------------------------------------------------
	local right_panel = ui_root:addChild(Panel({
		anchor = {0, 0, 1, 1},
		padding = {sidebar_w + 4, 4, 4, 4},
	}))

	right_panel:addChild(Text({
		text = "Component Preview",
		font_size = 14,
		h = 20,
		text_color = UiUtils.UI_COLORS.HINT,
		anchor = {0, 0, 1, 0},
		padding = {12, 12, 12, 0},
	}))

	display_area = right_panel:addChild(Widget({
		anchor = {0, 0, 1, 1},
		padding = {12, 12, 38, 12},
	}))

	-- 默认选中第一个
	if #test_modules > 0 then
		selectTest(1)
	end
end


-- 切换测试模块
function selectTest(index)
	if index == current_test then return end

	-- 更新按钮高亮
	if current_test and gallery_btns[current_test] then
		gallery_btns[current_test]:setSelected(false)
	end
	current_test = index
	gallery_btns[index]:setSelected(true)

	-- 加载测试内容
	local mod = test_modules[index]
	if mod and mod.create then
		mod.create(display_area)
	end
end


local FPS = 0
local timer = 1
local update_count = 0
local FPS2 = 0
function love.update(dt)
	Lovebird.update(dt)
	UiManager:update(dt)

	FPS = 1/dt
	update_count = update_count + 1
	timer = timer - dt
	if timer <= 0 then
		timer = 1 - timer
		FPS2 = update_count
		update_count = 0
	end
end


local line_color1 = UiUtils.RGB(120, 120, 120, 0.06)
local line_color2 = UiUtils.RGB(160, 160, 160, 0.12)
local grid_canvas
local screen_size = {0, 0}
local function DrawGridBG()
	local cur_size = {love.graphics.getWidth(), love.graphics.getHeight()}
	if screen_size[1] ~= cur_size[1] or screen_size[2] ~= cur_size[2] then
		screen_size = cur_size
		grid_canvas = love.graphics.newCanvas()
		love.graphics.setCanvas(grid_canvas)
		love.graphics.setLineWidth(1)
		love.graphics.setLineStyle("rough")
		for i = 0, screen_size[1]+100, 100 do
			for j = 0, screen_size[2]+100, 100 do
				love.graphics.setColor(unpack(line_color1))
				love.graphics.line(i, j+25, i+100, j+25)
				love.graphics.line(i+25, j, i+25, j+100)
				love.graphics.line(i, j+50, i+100, j+50)
				love.graphics.line(i+50, j, i+50, j+100)
				love.graphics.line(i, j+75, i+100, j+75)
				love.graphics.line(i+75, j, i+75, j+100)

				love.graphics.setColor(unpack(line_color2))
				love.graphics.line(i, j, i+100, j, i+100, j+100)
			end
		end
		love.graphics.setCanvas()
	end
	love.graphics.setColor(1,1,1,1)
	love.graphics.setBlendMode("alpha", "premultiplied")
	love.graphics.draw(grid_canvas)
	love.graphics.setBlendMode("alpha")
end
local function DrawPerformanceInfo()
	love.graphics.setColor(0, 0.6, 0)
	local window_w = love.graphics.getWidth()
	local str = string.format("FPS: %.2f | FPS2: %d", FPS, FPS2)
	local font = Fonts:getFont("default", 14)
	local w = font:getWidth(str)
	love.graphics.printf(str, font, window_w-w, -2, w)

	local memo = collectgarbage("count")
	str = string.format("RAM: %.2f kb", memo)
	w = font:getWidth(str)
	love.graphics.printf(str, font, window_w-w, 12, w)
end
function love.draw()
	love.graphics.clear(unpack(UiUtils.UI_COLORS.BG))
	DrawGridBG()

	love.graphics.setLineStyle("smooth")
	UiManager:draw()

	DrawPerformanceInfo()
end


function love.keypressed(key, scancode, isrepeat)
	UiManager:KeyPressed(key, isrepeat)
end

function love.textinput(text)
	UiManager:TextInput(text)
end

function love.keyreleased(key, scancode)
	UiManager:KeyReleased(key)
	if key == "escape" then
		love.event.quit()
	end
end

function love.wheelmoved(x, y)
	UiManager:WheelMoved(x, y)
end

function love.mousepressed(x, y, button)
	UiManager:MousePressed(x, y, button)
end

function love.mousereleased(x, y, button)
	UiManager:MouseReleased(x, y, button)
end

function love.mousemoved(x, y, dx, dy)
	UiManager:MouseMoved(x, y, dx, dy)
end
