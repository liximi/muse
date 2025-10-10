local ImageButton = require "ui.widgets.imagebutton"
local Panel = require "ui.widgets.panel"
local Tween = require "dependencies.tween"

--水平屏幕边缘停靠可收起面板
local CollapsiblePanel = Class(Panel, function(self, width, right)
    Panel.new(self, width, love.graphics.getHeight())
    self._name = "CpllapsibleHScreenEdgePanel"

    self.transform:setAnchors(0, 0, 0, 1)

    self.open = true
    self.right = false

    self.open_x = 0
    self.close_x = 0
    self.collapse_btn_x = 0

    self.left_arrow = love.graphics.newImage("assets/ui/TablerLayoutSidebarLeftCollapseFilled.png")
    self.right_arrow = love.graphics.newImage("assets/ui/TablerLayoutSidebarRightCollapseFilled.png")
    self.collapse_btn_icon = {
        open = self.left_arrow,
        close = self.right_arrow,
    }

    self:SetMode(right)
    self:setPosition(self.open_x, 0)

	self.tween = nil
    self.tween_btn = nil

    self.collapse_btn = self:addChild(ImageButton())
    self.collapse_btn:setStateDef("normal", {
        text = "",
        texture = self.collapse_btn_icon.close,
    })
    self.collapse_btn:setStateDef("pressed", {
        text = "",
        offset = {0, 2}
    })
    self.collapse_btn.transform:setSize(24, 24)
    self.collapse_btn:setPosition(self.collapse_btn_x , 5)
    function self.collapse_btn.onClick(_self)
        self:ToggleOpen()
    end

    self:SetBGColor(230, 230, 230)
end)

function CollapsiblePanel:ToggleOpen()
    self.open = not self.open
    -- if self.tween then
    --     self.tween:reset()
    -- end
	self.tween = Tween.new(0.3, self, {_x = self.open and self.open_x or self.close_x}, "outQuint")
    self.tween_btn = Tween.new(0.3, self.collapse_btn, {_x = self.open and self.collapse_btn_x or self.collapse_btn_x_close}, "outQuint")
    self.collapse_btn:setStateDef("normal", {
        text = "",
        texture = self.open and self.collapse_btn_icon.close or self.collapse_btn_icon.open,
    })
end

function CollapsiblePanel:SetMode(right)
    self.right = right == true
    local w = self.transform:getSize()
    if self.right then
        self.open_x = love.graphics.getWidth() - w
        self.close_x = love.graphics.getWidth()
        self.collapse_btn_x = 5
        self.collapse_btn_x_close = self.collapse_btn_x - 10 - 24
        self.collapse_btn_icon = {
            open = self.left_arrow,
            close = self.right_arrow,
        }
    else
        self.open_x = 0
        self.close_x = -w
        self.collapse_btn_x = w - 5 - 24
        self.collapse_btn_x_close = self.collapse_btn_x + 10 + 24
        self.collapse_btn_icon = {
            open = self.right_arrow,
            close = self.left_arrow,
        }
    end
end


function CollapsiblePanel:OnUpdate(dt)
    if self.tween_btn then
        if self.tween_btn:update(dt) then
            self.tween_btn = nil
        end
    end
    if self.tween then
        if self.tween:update(dt) then
            self.tween = nil
        end
    end
end


return CollapsiblePanel
