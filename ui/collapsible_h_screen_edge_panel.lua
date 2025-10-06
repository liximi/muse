local ImageButton = require "ui.widgets.imagebutton"
local Panel = require "ui.widgets.panel"
local Tween = require "dependencies.tween"

--水平屏幕边缘停靠可收起面板
local CollapsiblePanel = Class(Panel, function(self, width, right)
    Panel.new(self, width, love.graphics.getHeight())
    self._name = "CpllapsibleHScreenEdgePanel"

    self.open = true
	self.width = width
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
    self:SetPosition(self.open_x, 0)

	self.tween = nil

    self.collapse_btn = self:AddChild(ImageButton())
    self.collapse_btn:SetStateDef("normal", {
        text = "",
        texture = self.collapse_btn_icon.close,
    })
    self.collapse_btn:SetStateDef("pressed", {
        text = "",
        offset = {0, 2}
    })
    self.collapse_btn:SetSize(24, 24)
    self.collapse_btn:SetPosition(self.collapse_btn_x + (self.right and 0 or -self.collapse_btn:GetScaledSize()) , 5)
    function self.collapse_btn.OnClick(_self)
        self:ToggleOpen()
    end

    self:SetBGColor(200, 200, 200)
end)

function CollapsiblePanel:ToggleOpen()
    self.open = not self.open
    if self.tween then
        self.tween:reset()
    end
	self.tween = Tween.new(0.3, self, {_x = self.open and self.open_x or self.close_x}, "outQuint")
    self.collapse_btn:SetStateDef("normal", {
        text = "",
        texture = self.open and self.collapse_btn_icon.close or self.collapse_btn_icon.open,
    })
end

function CollapsiblePanel:SetMode(right)
    self.right = right == true
    if self.right then
        self.open_x = love.graphics.getWidth() - self.width
        self.close_x = love.graphics.getWidth() - 27
        self.collapse_btn_x = 5
        self.collapse_btn_icon = {
            open = self.left_arrow,
            close = self.right_arrow,
        }
    else
        self.open_x = 0
        self.close_x = -self.width + 27
        self.collapse_btn_x = self.width - 5
        self.collapse_btn_icon = {
            open = self.right_arrow,
            close = self.left_arrow,
        }
    end
end


function CollapsiblePanel:OnUpdate(dt)
    self:SetSize(self.width, love.graphics.getHeight())
    if self.tween then
        if self.tween:update(dt) then
            self.tween = nil
        end
    end
end


return CollapsiblePanel
