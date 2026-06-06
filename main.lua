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
local timer = 1
local update_count = 0
local FPS2 = 0
function love.update(dt)
	Lovebird.update(dt)
	UiManager:update(dt)

	FPS = 1 / dt
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
		for i = 0, screen_size[1] + 100, 100 do
			for j = 0, screen_size[2] + 100, 100 do
				love.graphics.setColor(unpack(line_color1))
				love.graphics.line(i, j + 25, i + 100, j + 25)
				love.graphics.line(i + 25, j, i + 25, j + 100)
				love.graphics.line(i, j + 50, i + 100, j + 50)
				love.graphics.line(i + 50, j, i + 50, j + 100)
				love.graphics.line(i, j + 75, i + 100, j + 75)
				love.graphics.line(i + 75, j, i + 75, j + 100)

				love.graphics.setColor(unpack(line_color2))
				love.graphics.line(i, j, i + 100, j, i + 100, j + 100)
			end
		end
		love.graphics.setCanvas()
	end
	love.graphics.setColor(1, 1, 1, 1)
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
	love.graphics.printf(str, font, window_w - w, -2, w)

	local memo = collectgarbage("count")
	str = string.format("RAM: %.2f kb", memo)
	w = font:getWidth(str)
	love.graphics.printf(str, font, window_w - w, 12, w)
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
