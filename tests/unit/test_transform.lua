-- Transform 单元测试
-- 运行方式：love tests/unit

local Transform = require "ui.transform"
local Utils = require "ui.utils"

local passed, failed = 0, 0
local tests = {}

local function test(name, fn)
	table.insert(tests, {name = name, fn = fn})
end

local function assert_eq(actual, expected, msg)
	if actual ~= expected then
		error(string.format("%s: expected %s, got %s",
			msg or "assertion failed", tostring(expected), tostring(actual)))
	end
end

local function assert_near(actual, expected, epsilon, msg)
	epsilon = epsilon or 0.001
	if math.abs(actual - expected) > epsilon then
		error(string.format("%s: expected ~%s, got %s",
			msg or "assertion failed", tostring(expected), tostring(actual)))
	end
end

--------------------------------------------------
-- 点锚点 — 尺寸
--------------------------------------------------

test("点锚点 setSize 正确存储 w/h", function()
	local t = Transform()
	t:setSize(100, 200)
	assert_eq(t.w, 100, "w")
	assert_eq(t.h, 200, "h")
end)

test("点锚点 setSize 正确派生 left/right", function()
	local t = Transform()
	t:setSize(100, 200)
	assert_eq(t.left, 0, "left")
	assert_eq(t.right, -100, "right")
end)

test("点锚点 setSize 正确派生 top/bottom", function()
	local t = Transform()
	t:setSize(100, 200)
	assert_eq(t.top, 0, "top")
	assert_eq(t.bottom, -200, "bottom")
end)

--------------------------------------------------
-- 点锚点 — 位置
--------------------------------------------------

test("点锚点 setPosition 正确存储 x/y", function()
	local t = Transform()
	t:setPosition(50, 60)
	assert_eq(t.x, 50, "x")
	assert_eq(t.y, 60, "y")
end)

test("点锚点 setPosition 反向更新 padding", function()
	local t = Transform()
	t:setPosition(50, 60)
	assert_eq(t.left, 50, "left after setPosition")
	assert_eq(t.top, 60, "top after setPosition")
end)

--------------------------------------------------
-- 拉伸锚点 — 尺寸
--------------------------------------------------

test("拉伸锚点 anchor={0,0,1,1} 尺寸=父容器-padding", function()
	local t = Transform()
	t.parent = {w = 800, h = 600}
	t:setAnchor(0, 0, 1, 1)
	t:onUpdate(true)
	assert_eq(t.w, 800, "w full stretch")
	assert_eq(t.h, 600, "h full stretch")
end)

test("拉伸锚点 setPadding 联动尺寸更新", function()
	local t = Transform()
	t.parent = {w = 800, h = 600}
	t:setAnchor(0, 0, 1, 1)
	t:setPadding(10, 20, 30, 40)
	t:onUpdate(true)
	assert_eq(t.w, 770, "w with padding")
	assert_eq(t.h, 530, "h with padding")
end)

--------------------------------------------------
-- 点锚点 setPadding 不覆盖 w/h（回归测试）
--------------------------------------------------

test("点锚点 setPadding 不覆盖已设好的 w/h", function()
	local t = Transform()
	t:setSize(100, 200)
	t:setPadding(5, 5, 5, 5)
	t:onUpdate(true)
	assert_eq(t.w, 100, "w preserved")
	assert_eq(t.h, 200, "h preserved")
	assert_eq(t.x, 5, "x updated from padding")
	assert_eq(t.y, 5, "y updated from padding")
end)

--------------------------------------------------
-- 全局坐标链
--------------------------------------------------

test("无父级时 getGlobalPosition = 锚点*屏幕 + 自身偏移", function()
	local t = Transform()
	t:setPosition(100, 200)
	t:setSize(50, 60)
	local gx, gy = t:getGlobalPosition()
	assert_near(gx, 100, 1, "global x")
	assert_near(gy, 200, 1, "global y")
end)

test("嵌套后 getGlobalPosition 叠加父级偏移", function()
	local parent = Transform()
	parent:setPosition(100, 200)
	parent:setSize(300, 400)
	local child = Transform()
	child:setParent(parent)
	child:setPosition(10, 20)
	child:setSize(50, 60)
	local gx, gy = child:getGlobalPosition()
	assert_near(gx, 110, 1, "nested global x")
	assert_near(gy, 220, 1, "nested global y")
end)

test("父级 scale 影响子级 getGlobalScaledSize", function()
	local parent = Transform()
	parent:setScale(2, 3)
	local child = Transform()
	child:setParent(parent)
	child:setSize(50, 60)
	local sw, sh = child:getGlobalScaledSize()
	assert_near(sw, 100, 1, "scaled w")
	assert_near(sh, 180, 1, "scaled h")
end)

--------------------------------------------------
-- 旋转
--------------------------------------------------

test("setRotation + getGlobalRotation", function()
	local t = Transform()
	t:setRotation(math.pi / 2)
	local r = t:getGlobalRotation()
	assert_near(r, math.pi / 2, 0.01, "rotation stored")
end)

test("旋转后 AABB 高度增大", function()
	local t = Transform()
	t:setPivot(0.5, 0.5)
	t:setSize(100, 40)
	t:setRotation(math.pi / 4)
	local _, _, aw, ah = t:getGlobalAABB()
	-- 中心 pivot + 45度旋转，高度必增大
	assert_eq(ah > 40, true, "AABB height larger")
	-- AABB 面积应大于原始（证明旋转生效）
	assert_eq(aw * ah > 4000, true, "AABB area larger")
end)

--------------------------------------------------
-- 变更检测
--------------------------------------------------

--------------------------------------------------
-- Measure 协议
--------------------------------------------------

test("Widget:measure 默认返回 transform 尺寸", function()
	local Widget = require "ui.widgets.widget"
	local w = Widget({w = 120, h = 80})
	local m = w:measure(nil, nil)
	assert_eq(m.w, 120, "measure w")
	assert_eq(m.h, 80, "measure h")
end)

test("Widget:measure 返回表格式 {w, h}", function()
	local Widget = require "ui.widgets.widget"
	local w = Widget()
	local m = w:measure(200, 100)
	assert_eq(type(m), "table", "result is table")
	assert_eq(m.w, 0, "default w=0")
	assert_eq(m.h, 0, "default h=0")
end)

test("无变更时不重复计算", function()
	local t = Transform()
	t:setSize(100, 200)
	t:onUpdate(true)
	t._cache.test_marker = true
	t:onUpdate()
	assert_eq(t._cache.test_marker, true, "cache not cleared")
end)

test("setPosition 后变更检测触发重算", function()
	local t = Transform()
	t:setSize(100, 200)
	t:onUpdate(true)
	t:setPosition(50, 50)
	t:onUpdate()
	assert_eq(t._cache.x, 50, "cache refreshed after setPosition")
end)

--------------------------------------------------
-- 边界情况
--------------------------------------------------

test("负尺寸 w<0 不崩溃", function()
	local t = Transform()
	t:setSize(-100, 200)
	local x, y, w, h = t:getGlobalAABB()
	assert_eq(type(x), "number", "x is number")
	assert_eq(type(w), "number", "w is number")
end)

--------------------------------------------------
-- Text.measure / Image.measure / TextInput.measure
-- 注：需 LÖVE 字体系统，在 love tests/unit 环境下运行
--------------------------------------------------

test("Text:measure 无约束返回不换行尺寸", function()
	local ok, Text = pcall(require, "ui.widgets.text")
	if not ok then print("  SKIP  (font not available)") return end
	local t = Text({text = "Hello World", font_size = 14, w = 200})
	local m = t:measure(nil, nil)
	assert_eq(m.w > 0, true, "width > 0")
	assert_eq(m.h > 0, true, "height > 0")
	-- 不换行：只有一行
	local font = t:getFont()
	local expected_w = font:getWidth("Hello World")
	assert_near(m.w, expected_w, 1, "unwrapped width")
end)

test("Text:measure 给定宽度换行后高度增加", function()
	local ok, Text = pcall(require, "ui.widgets.text")
	if not ok then print("  SKIP  (font not available)") return end
	local t = Text({text = "Hello World This Is A Long Text", font_size = 14, w = 200})
	local m = t:measure(nil, nil)
	local single_h = m.h
	-- 约束到很窄的宽度，应该换行
	local m2 = t:measure(40, nil)
	assert_eq(m2.h > single_h, true, "wrapped height > single line")
end)

test("Image:measure 未设尺寸返回纹理原始尺寸", function()
	local ok, Image = pcall(require, "ui.widgets.image")
	if not ok then print("  SKIP  (font not available)") return end
	local canvas = love.graphics.newCanvas(64, 32)
	local img = Image({texture = canvas})
	-- 未设 w/h，应 fallback 到纹理尺寸
	local m = img:measure(nil, nil)
	assert_eq(m.w, 64, "texture width")
	assert_eq(m.h, 32, "texture height")
end)

test("Image:measure 已设尺寸返回 transform 尺寸", function()
	local ok, Image = pcall(require, "ui.widgets.image")
	if not ok then print("  SKIP  (font not available)") return end
	local canvas = love.graphics.newCanvas(64, 32)
	local img = Image({texture = canvas, w = 120, h = 80})
	-- 显式设了 w/h，应返回这些值而非纹理尺寸
	local m = img:measure(nil, nil)
	assert_eq(m.w, 120, "explicit w")
	assert_eq(m.h, 80, "explicit h")
end)

test("TextInput:measure 含 padding 和 min_height", function()
	local ok, TextInput = pcall(require, "ui.widgets.textinput")
	if not ok then print("  SKIP  (font not available)") return end
	local ti = TextInput({
		text = "Hello",
		font_size = 14,
		w = 200,
		text_padding = {10, 10, 5, 5},
		min_height = 100,
	})
	local m = ti:measure(nil, nil)
	local font = ti.text:getFont()
	local _, wrapped = font:getWrap("Hello", 200)
	local expected_h = math.max(100, #wrapped * font:getHeight() * font:getLineHeight() + 5 + 5)
	assert_near(m.h, expected_h, 1, "height with padding + min_height")
end)

--------------------------------------------------
-- 运行
--------------------------------------------------

local function run()
	print("")
	print("=== Transform Unit Tests ===")
	print("")
	for _, tt in ipairs(tests) do
		local ok, err = pcall(tt.fn)
		if ok then
			passed = passed + 1
			print(string.format("  PASS  %s", tt.name))
		else
			failed = failed + 1
			print(string.format("  FAIL  %s", tt.name))
			print(string.format("        %s", err))
		end
	end
	print("")
	print(string.format("=== %d passed, %d failed ===", passed, failed))
	print("")
	-- if love and love.event then
	-- 	love.event.quit()
	-- end
end

return { run = run, test = test }
