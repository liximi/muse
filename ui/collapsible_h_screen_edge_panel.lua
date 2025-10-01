local Lf = require "dependencies.loveframes"
local Tween = require "dependencies.tween"
local Widget = require "ui.widgets.widget"
local Panel = require "ui.widgets.panel"

--水平屏幕边缘停靠可收起面板
local CpllapsiblePanel = Class(Panel, function(self, width, right)
    Panel.new(self, width, love.graphics.getHeight())
    self._name = "CpllapsibleHScreenEdgePanel"

    self.open = true
	self.width = width
    self.right = false

    self.open_x = 0
    self.close_x = 0
    self.collapse_btn_x = 0

    self.collapse_btn_icon = {
        open = "assets/ui/TablerLayoutSidebarLeftCollapseFilled.png",
        close = "assets/ui/TablerLayoutSidebarRightCollapseFilled.png",
    }

    self:SetMode(right)
    self:SetPosition(self.open_x, 0)

	self.tween = nil

    self.collapse_btn = Lf.Create("imagebutton", self)
    self.collapse_btn:SetImage(self.collapse_btn_icon.close)
    self.collapse_btn:SetText("")
    self.collapse_btn.scalex = 1 / 28
    self.collapse_btn.scaley = 1 / 28
    local img_w = self.collapse_btn:GetImageWidth() / 28
    self.collapse_btn:SetPos(self.collapse_btn_x + (self.right and 0 or -img_w) , 5)

    function self.collapse_btn.OnClick(_self, x, y)
        self:ToggleOpen()
    end
end)

function CpllapsiblePanel:ToggleOpen()
    self.open = not self.open
    if self.tween then
        self.tween:reset()
    end
	self.tween = Tween.new(0.3, self, {_x = self.open and self.open_x or self.close_x}, "outQuint")
	self.collapse_btn:SetImage(self.open and self.collapse_btn_icon.close or self.collapse_btn_icon.open)
end

function CpllapsiblePanel:SetMode(right)
    self.right = right == true
    if self.right then
        self.open_x = love.graphics.getWidth() - self.width
        self.close_x = love.graphics.getWidth() - 27
        self.collapse_btn_x = 5
        self.collapse_btn_icon = {
            open = "assets/ui/TablerLayoutSidebarLeftCollapseFilled.png",
            close = "assets/ui/TablerLayoutSidebarRightCollapseFilled.png",
        }
    else
        self.open_x = 0
        self.close_x = -self.width + 27
        self.collapse_btn_x = self.width - 5
        self.collapse_btn_icon = {
            close = "assets/ui/TablerLayoutSidebarLeftCollapseFilled.png",
            open = "assets/ui/TablerLayoutSidebarRightCollapseFilled.png",
        }
    end
end


function CpllapsiblePanel:OnUpdate(dt)
    self:SetSize(self.width, love.graphics.getHeight())
    if self.tween then
        if self.tween:update(dt) then
            self.tween = nil
        end
    end
end


return CpllapsiblePanel
