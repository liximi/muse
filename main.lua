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
local Image = require "ui.widgets.image"
local ImageButton = require "ui.widgets.imagebutton"
local NineSlice = require "ui.widgets.nineslice"
local TextInput = require "ui.widgets.textinput"

local Scroll = require "ui.widgets.containers.scroll_container"
local ChatHistory = require "ui.widgets.advanced.chat_history"

local languages = {"zh-cn"}

local ui_root

function love.load()
    -- 加载本地化文本
    for _, lan in ipairs(languages) do
        Loc:load("localization/" .. lan .. ".lua")
    end
    Loc:set_fallback("zh-cn")
    Loc:set_locale("zh-cn")

    --允许键盘重复，这样就可以按住退格一直删除字符
    love.keyboard.setKeyRepeat(true)


    --UI
    ui_root = UiManager:addWidget(Widget("ui_root", {
        anchors = {0, 0, 1, 1},
        padding = {0, 0, 0, 0}
    }))

    local left_panel = ui_root:addChild(Panel({
        w = 400,
        anchors = {0, 0, 0, 1},
        padding = {20, nil, 20, 20},
    }))

    local title = left_panel:addChild(Text({
        text = "Title",
        font_size = 24,
        font_key = "default_bold",
        h = 30,
        text_color = UiUtils.UI_COLORS.TITLE,
        anchors = {0, 0, 1, 0},
        padding = {20, 20, 16}
    }))
    local test_img = love.graphics.newImage("assets/bilibili.png")
    local image = left_panel:addChild(Image({
        texture = test_img,
        h = 200,
        anchors = {0, 0, 1, 0},
        padding = {20, 20, 55},
    }))
    local btns_root = left_panel:addChild(Widget("btns_root", {
        anchors = {0, 0, 1, 0},
        padding = {20, 20, 220, -255},
    }))
    -- btns_root:enableDebug(true)
    local btn = btns_root:addChild(Button({
        normal = UiUtils.newButtonStateStyle("Normal"),
        anchors = {0, 0, 0.3, 1},
        padding = {0, 0, 0, 0},
    }))
    local btn2 = btns_root:addChild(Button({
        normal = UiUtils.newButtonStateStyle("Selected"),
        anchors = {0.35, 0, 0.65, 1},
        padding = {0, 0, 0, 0},
    }))
    btn2:setSelected(true)
    local btn3 = btns_root:addChild(Button({
        normal = UiUtils.newButtonStateStyle("Disabled"),
        anchors = {0.7, 0, 1, 1},
        padding = {0, 0, 0, 0},
    }))
    btn3:disable()

    local b_img = love.graphics.newImage("assets/panel_glass.png")
    local img_btn = btns_root:addChild(ImageButton({
        no_text = true,
        normal = UiUtils.newImageButtonStateStyle(b_img, nil, "Normal"),
        anchors = {0, 1.2, 0.3, 3},
        padding = {0, 0, 0, 0},
    }))
    local img_btn2 = btns_root:addChild(ImageButton({
        no_text = true,
        normal = UiUtils.newImageButtonStateStyle(b_img, nil, "Normal"),
        anchors = {0.35, 1.2, 0.65, 3},
        padding = {0, 0, 0, 0},
    }))
    img_btn2:setSelected(true)
    local img_btn3 = btns_root:addChild(ImageButton({
        no_text = true,
        normal = UiUtils.newImageButtonStateStyle(b_img, nil, "Normal"),
        anchors = {0.7, 1.2, 1, 3},
        padding = {0, 0, 0, 0},
    }))
    img_btn3:disable()

    local text_input = left_panel:addChild(TextInput({
        height_adaptive = true,
        texture = b_img,
        -- pivot = {0.5, 0.5},
        anchors = {0, 0, 1, 0},
        padding = {20, 20, 350, 0},
        bg = Panel(),
        text_padding = {10, 10, 10, 10},
        text = "测试文本：\nMermaid 是一种基于文本的图表绘制工具，通过简单的语法就能生成流程图、时序图、类图等多种图表，广泛应用于文档、笔记和代码注释中。\n一、基础结构\nMermaid 代码通常包裹在 ```mermaid 和 ``` 标签之间。",
    }))
    -- text_input:enableDebug(true)

    local chat_history = ui_root:addChild(ChatHistory({
        space = 8,
        anchors = {1, 0, 1, 1},
        padding = {-350, 50, 20, 100},
        pivot = {1, 0},
    }))
    chat_history:setChatBubbleStyle("user", chat_history:createChatBubbleStyle(
        UiUtils.UI_COLORS.LIGHT_PINK,
        6, 250, nil, nil,
        UiUtils.UI_COLORS.PRIMARY_TEXT,
        {6, 6, 6, 6}, "right"
    ))
    chat_history:setChatBubbleStyle("agent", chat_history:createChatBubbleStyle(
        UiUtils.UI_COLORS.SECONDARY_TEXT,
        6, 250, nil, nil,
        UiUtils.UI_COLORS.PRIMARY_TEXT,
        {6, 6, 6, 6}, "left"
    ))
    chat_history:setChatHistory({
        {"user", "中午吃啥啊？纠结半天了"},
        {"agent", "我也没谱！楼下新开的那家麻辣烫怎么样？听同事说味道还行"},
        {"user", "可以啊！辣度能选不？我吃不了太辣"},
        {"agent", "必须能！微辣、中辣都有，12 点楼下见？"},
        {"user", "妥了！到点我喊你"}
    })
end


local FPS = 0
function love.update(dt)
    -- 该方法应该总是在update的顶部使用
    -- 在浏览器里打开'127.0.0.1:8000'来查看控制台
    Lovebird.update(dt)

    UiManager:update(dt)

    FPS = 1/dt
end


local line_color1 = UiUtils.RGB(160, 160, 160, 0.1)
local line_color2 = UiUtils.RGB(200, 200, 200, 0.25)
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
    local str = string.format("FPS: %.2f", FPS)
    local font = Fonts:getFont("default", 14) ---@type love.Font
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