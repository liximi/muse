local Loc = require "dependencies.i18n.i18n"()
local Lovebird = require "dependencies.Lovebird.Lovebird"
Class = require "dependencies.classic"

local UiManager = require "ui.ui_manager"()
local Widget = require "ui.widgets.widget"
local Panel = require "ui.widgets.panel"
local Text = require "ui.widgets.text"
local Fonts = require "ui.fonts"
local Button = require "ui.widgets.button"
local Image = require "ui.widgets.image"
local ImageButton = require "ui.widgets.imagebutton"
local TextInput = require "ui.widgets.textinput"
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
    UI_ROOT = UiManager:AddRootWidget(Widget("UI_ROOT"))
    UI_ROOT:AddChild(CollapsibleScreenEdgePanel(300))

    panel1 = UI_ROOT:AddChild(Panel(200, 200))
    panel1:SetPosition(300, 100)

    test_btn = panel1:AddChild(Button())
    test_btn:SetPosition(40, 120)
    local count = 0
    function test_btn:OnClick()
        count = count + 1
        test_text:SetText(string.format("Click %d", count))
    end

    test_text = panel1:AddChild(Text("你好，世界\n换行测试"))
    test_text:SetMaxWidth(100)
    test_text:EnableDebug(true)

    img = love.graphics.newImage("assets/bilibili.png")
    test_img = panel1:AddChild(Image(img))
    -- test_img:EnableDebug(true)
    test_img:SetPosition(200, 0)

    test_imgbtn = panel1:AddChild(ImageButton())
    test_imgbtn:SetPosition(0, 250)
    test_imgbtn:SetStateDef("normal", {
        text = nil,
        texture = img,
    })
    test_imgbtn:SetStateDef("pressed", {
        text = nil,
        texture = img,
    })
    test_imgbtn:SetStateDef("disabled", {
        text = nil,
        texture = img,
    })
    test_imgbtn:EnableDebug(true)


    test_textinput = panel1:AddChild(TextInput(nil, nil, "请输入...", true))
    test_textinput:SetPosition(0, 350)
end


local FPS = 0
love.update = function(dt)
    -- 该方法应该总是在update的顶部使用
    -- 在浏览器里打开'127.0.0.1:8000'来查看控制台
    Lovebird.update(dt)

    UiManager:Update(dt)

    FPS = 1/dt
end


local function DrawGridBG()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    for i = 1, w+100, 100 do
        for j = 1, h+100, 100 do
            love.graphics.setColor(0.5, 0.5, 0.5)
            for k = 20, 80, 20 do
                love.graphics.line(i-2, j+k, i+2, j+k)
                love.graphics.line(i+k, j+2, i+k, j-2)
            end
            love.graphics.line(i, j+50, i+100, j+50)
            love.graphics.line(i+50, j, i+50, j+100)

            love.graphics.setColor(0, 0, 0)
            love.graphics.line(i, j, i+99, j, i+99, j+99)
        end
    end
end
local function DrawPerformanceInfo()
    love.graphics.setColor(0, 0.6, 0)
    local str = string.format("FPS: %.2f", FPS)
    local font = Fonts:GetFont("default", 16) ---@type love.Font
    local w = font:getWidth(str)
    love.graphics.printf(str, font, love.graphics.getWidth()-w-5, 5, w)
end
love.draw = function()
    -- love.graphics.clear(0.4, 0.9, 0.7, 1)
    love.graphics.clear(0.85, 0.85, 0.849, 1)
    DrawGridBG()

    UiManager:Draw()

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
end

function love.wheelmoved(x, y)
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