local Loc = require "dependencies.i18n.i18n"()
local Lovebird = require "dependencies.Lovebird.Lovebird"
Class = require "dependencies.classic"

local UiManager = require "ui.ui_manager":GetInstance()
local UiUtils = require "ui.utils"
local Fonts = require "ui.fonts"

local Widget = require "ui.widgets.widget"
local Gallery = require "tests.gallery"

local languages = {"zh-cn"}

function love.load()
	-- 加载本地化文本
	for _, lan in ipairs(languages) do
		Loc:load("localization/" .. lan .. ".lua")
	end
	Loc:set_fallback("zh-cn")
	Loc:set_locale("zh-cn")

	love.keyboard.setKeyRepeat(true)

	local ui_root = UiManager:addWidget(Widget({
		anchor = {0, 0, 1, 1},
		padding = {0, 0, 0, 0}
	}))

	Gallery(ui_root)
end

local FPS = 0
local memo = 0
local timer = 1
local update_count = 0
function love.update(dt)
	Lovebird.update(dt)
	UiManager:update(dt)

	update_count = update_count + 1
	timer = timer - dt
	if timer <= 0 then
		timer = 1 - timer
		FPS = update_count
		memo = collectgarbage("count")
		update_count = 0
	end
end

local function DrawPerformanceInfo()
	love.graphics.setColor(0, 0.6, 0)
	local window_w = love.graphics.getWidth()
	local font = Fonts:getFont("default", 14)

	local str = string.format("FPS: %d", FPS)
	local w = font:getWidth(str)
	love.graphics.printf(str, font, window_w - w, -2, w)

	str = string.format("RAM: %.2f kb", memo)
	w = font:getWidth(str)
	love.graphics.printf(str, font, window_w - w, 12, w)
end
function love.draw()
	love.graphics.clear(unpack(UiUtils.UI_COLORS.BG))
	-- DrawGridBG()

	love.graphics.setLineStyle("smooth")
	UiManager:draw()

	DrawPerformanceInfo()
end

function love.keypressed(key, scancode, isrepeat)
	local ui_handled = UiManager:KeyPressed(key, isrepeat)
	-- 外部系统可通过 ui_handled 判断是否需要自行处理该按键
end

function love.textinput(text)
	local ui_handled = UiManager:TextInput(text)
end

function love.keyreleased(key, scancode)
	local ui_handled = UiManager:KeyReleased(key)
	if not ui_handled and key == "escape" then
		love.event.quit()
	end
end

function love.wheelmoved(x, y)
	local ui_handled = UiManager:WheelMoved(x, y)
end

function love.mousepressed(x, y, button)
	local ui_handled = UiManager:MousePressed(x, y, button)
	-- 外部系统可通过 ui_handled 判断点击是否落在 UI 区域
end

function love.mousereleased(x, y, button)
	local ui_handled = UiManager:MouseReleased(x, y, button)
end

function love.mousemoved(x, y, dx, dy)
	local ui_handled = UiManager:MouseMoved(x, y, dx, dy)
end
