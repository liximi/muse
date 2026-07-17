--------------------------------------------------
-- color_picker.lua — HSV 选色器
-- 点击色块弹出：SV 方形渐变 + 拖拽十字准星 + 色相条
--------------------------------------------------

local Widget = require "ui.widgets.widget"
local Panel = require "ui.widgets.panel"
local Text = require "ui.widgets.text"
local UiManager = require "ui.ui_manager"
local Utils = require "ui.utils"

local uc = Utils.UI_COLORS

local SV_SIZE = 140
local HUE_W = 16
local ALPHA_H = 16
local HANDLE_R = 5
local HANDLE_R2 = HANDLE_R * HANDLE_R

--------------------------------------------------
-- HSV ↔ RGB 转换
--------------------------------------------------
local function hsv2rgb(h, s, v)
	if s <= 0 then return v, v, v end
	h = (h % 1) * 6
	local i = math.floor(h)
	local f = h - i
	local p = v * (1 - s)
	local q = v * (1 - f * s)
	local t = v * (1 - (1 - f) * s)
	if i == 0 then return v, t, p
	elseif i == 1 then return q, v, p
	elseif i == 2 then return p, v, t
	elseif i == 3 then return p, q, v
	elseif i == 4 then return t, p, v
	else return v, p, q end
end

local function rgb2hsv(r, g, b)
	local mx = math.max(r, g, b)
	local mn = math.min(r, g, b)
	local d = mx - mn
	local h = 0
	if d > 0 then
		if mx == r then h = ((g - b) / d) % 6
		elseif mx == g then h = (b - r) / d + 2
		else h = (r - g) / d + 4 end
		h = h / 6
	end
	local s = mx > 0 and (d / mx) or 0
	return h % 1, s, mx
end

--------------------------------------------------
-- 渐变 Canvas 缓存
--------------------------------------------------
local _svCache = {}  -- [hue_int] = canvas
local _hueCanvas = nil

local function makeSVCanvas(hue)
	local key = math.floor(hue * 100)
	if _svCache[key] then return _svCache[key] end

	local canvas = love.graphics.newCanvas(SV_SIZE, SV_SIZE)
	local prev = love.graphics.getCanvas()
	love.graphics.setCanvas(canvas)
	love.graphics.clear(0, 0, 0, 0)
	for y = 0, SV_SIZE - 1 do
		for x = 0, SV_SIZE - 1 do
			local s = x / (SV_SIZE - 1)
			local v = 1 - y / (SV_SIZE - 1)
			local r, g, b = hsv2rgb(hue, s, v)
			love.graphics.setColor(r, g, b)
			love.graphics.points(x, y)
		end
	end
	love.graphics.setCanvas(prev)
	_svCache[key] = canvas
	return canvas
end

local function makeHueCanvas()
	if _hueCanvas then return _hueCanvas end
	local canvas = love.graphics.newCanvas(HUE_W, SV_SIZE)
	local prev = love.graphics.getCanvas()
	love.graphics.setCanvas(canvas)
	love.graphics.clear(0, 0, 0, 0)
	for y = 0, SV_SIZE - 1 do
		local h = 1 - y / (SV_SIZE - 1)
		local r, g, b = hsv2rgb(h, 1, 1)
		love.graphics.setColor(r, g, b)
		love.graphics.line(0, y, HUE_W, y)
	end
	love.graphics.setCanvas(prev)
	_hueCanvas = canvas
	return canvas
end

--------------------------------------------------
-- 创建选色器
--------------------------------------------------

--- 显示选色器弹出层，返回 popup widget（调用方负责管理生命周期）
--- @param swatch_widget 触发色块（用于定位弹出位置）
--- @param getter function → {r,g,b,a}
--- @param setter function({r,g,b,a})
--- @param onChangeHook function() 撤销快照钩子
local function showPicker(swatch_widget, getter, setter, onChangeHook)
	-- 开选色器前拍快照
	if onChangeHook then onChangeHook() end

	local current = getter()
	local cr, cg, cb, ca = current[1] or 0.5, current[2] or 0.5, current[3] or 0.5, current[4] or 1
	local h, s, v = rgb2hsv(cr, cg, cb)

	-- 弹出层（全屏 overlay）
	local popup = Widget({
		anchor = {0, 0, 1, 1},
		padding = {0, 0, 0, 0},
		raycast_target = true,
	})
	popup.render_layer = Utils.RENDER_LAYERS.DROPDOWN

	-- 面板位置（在触发色块附近）
	local sx, sy = swatch_widget.transform:getGlobalPosition()
	local _, sh = swatch_widget.transform:getGlobalScaledSize()
	local panel_w = SV_SIZE + HUE_W + 4 + 24
	local panel_h = SV_SIZE + ALPHA_H + 40
	local px = math.min(sx, love.graphics.getWidth() - panel_w - 8)
	local py = math.min(sy + sh + 4, love.graphics.getHeight() - panel_h - 8)

	local panel = popup:addChild(Panel({
		bg_color = {0.14, 0.14, 0.17, 1},
		outline_width = 1,
		outline_color = uc.LINE,
		rounding_radius = 6,
		anchor = {0, 0, 0, 0},
		padding = {px, 0, py, 0},
		w = panel_w,
		h = panel_h,
	}))

	-- === SV 方形 ===
	local sv_img = popup:addChild(Widget({
		anchor = {0, 0, 0, 0},
		padding = {px + 8, 0, py + 8, 0},
		w = SV_SIZE,
		h = SV_SIZE,
	}))
	sv_img._picker_hue = h
	sv_img._sv_tex = makeSVCanvas(h)

	function sv_img.onDraw(self)
		local sx_, sy_ = self.transform:getGlobalPosition()
		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.draw(self._sv_tex, sx_, sy_)
		-- 十字准星
		local hx = sx_ + s * SV_SIZE
		local hy = sy_ + (1 - v) * SV_SIZE
		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.circle("line", hx, hy, HANDLE_R)
		love.graphics.setColor(0, 0, 0, 1)
		love.graphics.circle("line", hx, hy, HANDLE_R + 1)
		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.circle("line", hx, hy, HANDLE_R - 1)
	end

	-- 拖拽准星
	local sv_drag = false
	function sv_img.onMousePressed(self, mx, my, btn)
		if btn == 1 then sv_drag = true; self:_updateSV(mx, my); return true end
		return false
	end
	function sv_img.onMouseMoved(self, mx, my, dx, dy)
		if sv_drag then self:_updateSV(mx, my); return true end
		return false
	end
	function sv_img.onMouseReleased(self, mx, my, btn)
		sv_drag = false; return true
	end

	function sv_img._updateSV(self, mx, my)
		local sx_, sy_ = self.transform:getGlobalPosition()
		s = math.max(0, math.min(1, (mx - sx_) / SV_SIZE))
		v = math.max(0, math.min(1, 1 - (my - sy_) / SV_SIZE))
		_updateColor()
	end

	-- === 色相条 ===
	local hue_img = popup:addChild(Widget({
		anchor = {0, 0, 0, 0},
		padding = {px + 8 + SV_SIZE + 4, 0, py + 8, 0},
		w = HUE_W,
		h = SV_SIZE,
	}))
	hue_img._hue_tex = makeHueCanvas()

	function hue_img.onDraw(self)
		local sx_, sy_ = self.transform:getGlobalPosition()
		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.draw(self._hue_tex, sx_, sy_)
		-- 色相指示线
		local hy = sy_ + (1 - h) * SV_SIZE
		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.rectangle("fill", sx_ - 2, hy - 1, HUE_W + 4, 3)
		love.graphics.setColor(0, 0, 0, 1)
		love.graphics.rectangle("line", sx_ - 2, hy - 1, HUE_W + 4, 3)
	end

	local hue_drag = false
	function hue_img.onMousePressed(self, mx, my, btn)
		if btn == 1 then hue_drag = true; self:_updateHue(mx, my); return true end
		return false
	end
	function hue_img.onMouseMoved(self, mx, my, dx, dy)
		if hue_drag then self:_updateHue(mx, my); return true end
		return false
	end
	function hue_img.onMouseReleased(self, mx, my, btn)
		hue_drag = false; return true
	end

	function hue_img._updateHue(self, mx, my)
		local _, sy_ = self.transform:getGlobalPosition()
		h = 1 - math.max(0, math.min(1, (my - sy_) / SV_SIZE))
		-- 重新生成 SV 渐变
		sv_img._sv_tex = makeSVCanvas(h)
		_updateColor()
	end

	-- === Alpha 条 ===
	local alpha_img = popup:addChild(Widget({
		anchor = {0, 0, 0, 0},
		padding = {px + 8, 0, py + 8 + SV_SIZE + 4, 0},
		w = SV_SIZE + HUE_W + 4,
		h = ALPHA_H,
	}))

	function alpha_img.onDraw(self)
		local ax, ay = self.transform:getGlobalPosition()
		local aw = self.transform.w
		local ah = self.transform.h
		-- 渐变：透明 → 当前色
		local r, g, b = hsv2rgb(h, s, v)
		-- 棋盘格背景
		for bx = 0, aw - 1, 4 do
			for by = 0, ah - 1, 4 do
				local is_white = ((bx / 4) + (by / 4)) % 2 == 0
				love.graphics.setColor(is_white and 0.6 or 0.4, is_white and 0.6 or 0.4, is_white and 0.6 or 0.4)
				love.graphics.rectangle("fill", ax + bx, ay + by, 4, 4)
			end
		end
		-- 颜色 overlay
		for x = 0, aw - 1 do
			local a = x / (aw - 1)
			love.graphics.setColor(r, g, b, a)
			love.graphics.line(ax + x, ay, ax + x, ay + ah)
		end
		-- 指示线
		local ax_pos = ax + ca * aw
		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.line(ax_pos, ay - 2, ax_pos, ay + ah + 2)
		love.graphics.setColor(0, 0, 0, 0.6)
		love.graphics.line(ax_pos - 1, ay - 2, ax_pos - 1, ay + ah + 2)
		love.graphics.line(ax_pos + 1, ay - 2, ax_pos + 1, ay + ah + 2)
	end

	local alpha_drag = false
	function alpha_img.onMousePressed(self, mx, my, btn)
		if btn == 1 then alpha_drag = true; self:_updateAlpha(mx); return true end
		return false
	end
	function alpha_img.onMouseMoved(self, mx, my, dx, dy)
		if alpha_drag then self:_updateAlpha(mx); return true end
		return false
	end
	function alpha_img.onMouseReleased(self, mx, my, btn)
		alpha_drag = false; return true
	end

	function alpha_img._updateAlpha(self, mx)
		local ax, _ = self.transform:getGlobalPosition()
		local aw = self.transform.w
		ca = math.max(0, math.min(1, (mx - ax) / aw))
		_updateColor()
	end

	-- === 底部预览 + hex ===
	local bottom_y = py + 8 + SV_SIZE + 4 + ALPHA_H + 4
	local preview_swatch = popup:addChild(Panel({
		bg_color = {cr, cg, cb, ca},
		outline_width = 1,
		outline_color = uc.LINE,
		rounding_radius = 3,
		anchor = {0, 0, 0, 0},
		padding = {px + 8, 0, bottom_y, 0},
		w = 24,
		h = 24,
	}))

	local hex_label = popup:addChild(Text({
		text = "#FFFFFF",
		font_size = 11,
		text_color = uc.PRIMARY_TEXT,
		anchor = {0, 0, 0, 0},
		padding = {px + 8 + 24 + 6, 0, bottom_y + 4, 0},
	}))

	-- === 内部更新 ===
	local function _updateColor()
		local r, g, b = hsv2rgb(h, s, v)
		cr, cg, cb = r, g, b
		preview_swatch.bg_color = {r, g, b, ca}
		local rh = math.floor(r * 255 + 0.5)
		local gh = math.floor(g * 255 + 0.5)
		local bh = math.floor(b * 255 + 0.5)
		hex_label:setText(string.format("#%02X%02X%02X  α=%.0f%%", rh, gh, bh, ca * 100))
		-- 实时预览到目标 widget
		setter({r, g, b, ca})
	end

	-- 初始化显示
	_updateColor()

	-- === 关闭逻辑 ===
	popup._picker_closed = false
	local function close()
		if popup._picker_closed then return end
		popup._picker_closed = true
		-- 最终确认颜色
		setter({cr, cg, cb, ca})
		popup:hide()
		-- 延迟销毁（下一帧）
		popup._destroy = true
	end

	function popup.onMousePressed(self, mx, my, btn)
		-- 点击面板外部关闭
		if not panel:regionDetection(mx, my) then
			close()
			return true
		end
		return false
	end

	-- 更新循环处理销毁
	local _orig_update = popup.onUpdate
	function popup.onUpdate(self, dt)
		if self._destroy then
			UiManager:GetInstance():removeWidget(self)
			return
		end
	end

	UiManager:GetInstance():addWidget(popup)
	return popup
end

return { showPicker = showPicker }
