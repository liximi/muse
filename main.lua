local Loc = require "dependencies.i18n.i18n"()
local Lovebird = require "dependencies.Lovebird.Lovebird"
Class = require "dependencies.classic"

local UiManager = require "ui.ui_manager":GetInstance()
local Widget = require "ui.widgets.widget"
local Panel = require "ui.widgets.panel"
local Text = require "ui.widgets.text"
local Fonts = require "ui.fonts"
local Button = require "ui.widgets.button"
local Image = require "ui.widgets.image"
local ImageButton = require "ui.widgets.imagebutton"
local TextInput = require "ui.widgets.textinput"
local ScrollableList = require "ui.widgets.scrollable_list"
local UiUtils = require "ui.utils"

local CollapsibleScreenEdgePanel = require "ui.collapsible_h_screen_edge_panel"

local languages = {"zh-cn"}

local UI_ROOT

love.load = function()
    -- 加载本地化文本
    for _, lan in ipairs(languages) do
        Loc:load("localization/" .. lan .. ".lua")
    end
    Loc:set_fallback("zh-cn")
    Loc:set_locale("zh-cn")

    --允许键盘重复，这样就可以按住退格一直删除字符
    love.keyboard.setKeyRepeat(true)

    --UI
    -- UI_ROOT = UiManager:addWidget(Widget("UI_ROOT"))

    -- local root_panel = UI_ROOT:addChild(CollapsibleScreenEdgePanel(300))
    local root_panel = UiManager:addWidget(Panel({
        pivot = {0.5, 0.5},
        w = 300,
        h = 300,
        anchors = {0.4, 0.25, 0.6, 0.75},
        padding = {0, 0, 0, 0},
        rounding_radius = 5,
    }))
    -- root_panel:enableDebug(true)

    local text = root_panel:addChild(Text({
        pivot = {0.5, 0.5},
        anchors = {0, 0, 1, 1},
        padding = {8, 8, 8, 8},
        h_align = "left",
        text = "或许你已经知道了，LÖVE是一个使用 Lua 作为编程语言的 2D 游戏框架。LÖVE 完全免费，能用在任何开源项目，或闭源、商业项目。"
    }))
    text:enableDebug(true)

    -- local panel1 = root_panel:addChild(Panel({
    --     pivot = {0.5, 0.5},
    --     w = 100, h = 200,
    --     bg_color = UiUtils.UI_COLORS.LIGHT_PRIMARY
    -- }))

    -- local title = root_panel:addChild(Text({
    --     text = "Widget Examples",
    --     text_color = UiUtils.UI_COLORS.PRIMARY_TEXT,
    --     font = "default",
    --     font_size = 20,
    --     x = 10,
    --     w = 300,
    --     h = 20,
    -- }))
    -- title:enableDebug(true)

    -- local list = root_panel:addChild(ScrollableList(280, 675))
    -- list:setPosition(10, 36)

    -- local example_btn_1 = Button("Panel")
    -- example_btn_1.transform:setSize(276, 50)
    -- example_btn_1.onClick = function(self)

    -- end
    -- local example_btn_2 = Button("Text")
    -- example_btn_2.transform:setSize(276, 50)
    -- example_btn_2.onClick = function(self)

    -- end
    -- local example_btn_3 = Button("Image")
    -- example_btn_3.transform:setSize(276, 50)
    -- example_btn_3.onClick = function(self)

    -- end
    -- local example_btn_4 = Button("Button")
    -- example_btn_4.transform:setSize(276, 50)
    -- example_btn_4.onClick = function(self)

    -- end
    -- local example_btn_5 = Button("ImageButton")
    -- example_btn_5.transform:setSize(276, 50)
    -- example_btn_5.onClick = function(self)

    -- end
    -- local example_btn_6 = Button("TextInput")
    -- example_btn_6.transform:setSize(276, 50)
    -- example_btn_6.onClick = function(self)

    -- end
    -- list:SetItems({
    --     example_btn_1,
    --     example_btn_2,
    --     example_btn_3,
    --     example_btn_4,
    --     example_btn_5,
    --     example_btn_6,
    -- })
    -- list:SetXOffset(2)
end


local FPS = 0
love.update = function(dt)
    -- 该方法应该总是在update的顶部使用
    -- 在浏览器里打开'127.0.0.1:8000'来查看控制台
    Lovebird.update(dt)

    UiManager:update(dt)

    FPS = 1/dt
end


local line_color1 = UiUtils.RGB(160, 160, 160, 0.1)
local line_color2 = UiUtils.RGB(200, 200, 200, 0.25)
local function DrawGridBG()
    love.graphics.setLineWidth(1)
    love.graphics.setLineStyle("rough")
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    for i = 0, w+100, 100 do
        for j = 0, h+100, 100 do
            love.graphics.setColor(unpack(line_color1))
            -- for k = 25, 75, 25 do
            --     love.graphics.line(i-2, j+k, i+2, j+k)
            --     love.graphics.line(i+k, j+2, i+k, j-2)
            -- end
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
end
local function DrawPerformanceInfo()
    love.graphics.setColor(0, 0.6, 0)
    local window_w = love.graphics.getWidth()
    local str = string.format("FPS: %.2f", FPS)
    local font = Fonts:getFont("default", 14) ---@type love.Font
    local w = font:getWidth(str)
    love.graphics.printf(str, font, window_w-w, -2, w)

    local memo = collectgarbage("count")
    str = string.format("RAM: %.2f kb", memo)
    w = font:getWidth(str)
    love.graphics.printf(str, font, window_w-w, 12, w)
end
love.draw = function()
    love.graphics.clear(unpack(UiUtils.UI_COLORS.BLACK))
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

---@param button integer 1 是鼠标左键，2 鼠标右键，3 是鼠标中键
function love.mousepressed(x, y, button)
    UiManager:MousePressed(x, y, button)
end

---@param button integer 1 是鼠标左键，2 鼠标右键，3 是鼠标中键
function love.mousereleased(x, y, button)
    UiManager:MouseReleased(x, y, button)
end

function love.mousemoved(x, y, dx, dy)
    UiManager:MouseMoved(x, y, dx, dy)
end