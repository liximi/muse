# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

这是一个基于 LÖVE (Love2D) 游戏引擎的 UI 框架，使用 Lua 编写。它实现了一套完整的桌面级 UI widget 系统，包括布局引擎、主题系统、文本输入、滚动列表等功能。

## 运行项目

```
# 在项目根目录下，使用 LÖVE 运行
love .

# 或者将项目文件夹拖到 love.exe 上
```

LÖVE 版本：11.5（当前最新稳定版），使用 **LuaJIT**（基于 Lua 5.1 + 扩展，不是标准 Lua 5.4）。
运行后在浏览器打开 `127.0.0.1:8000` 可以查看 Lovebird 远程调试控制台。

## 架构

### 类系统

`dependencies/classic.lua` 提供简化的 OOP。用法：

```lua
-- 定义类
local MyClass = Class(BaseClass, function(self, arg1, arg2)
    BaseClass.new(self, "name", arg1)
    -- 初始化
end)

-- 实例化（调用时自动 new）
local obj = MyClass(arg1, arg2)
```

`Class` 在 `main.lua:3` 中被全局化：`Class = require "dependencies.classic"`，之后所有模块直接使用。

### 核心系统

**UiManager** (`ui/ui_manager.lua`) — 单例，管理顶层 widget 层级。负责：
- 持有 widget 树的根节点列表（`self.hierarchy`）
- 将所有 LÖVE 事件（`update`, `draw`, `keypressed`, `mousemoved`, `mousepressed`, `mousereleased`, `wheelmoved`, `textinput`）分发给 widget 树
- 事件从 hierarchy 末尾向前遍历（后添加的 widget 先收到事件），通过 `handleEvent` 递归进入子节点
- Z 轴控制：`moveToTop` / `moveToBottom`

获取方式：`require "ui.ui_manager":GetInstance()`

**Widget** (`ui/widgets/widget.lua`) — 所有 UI 元素的基类。核心机制：
- 持有 `Transform` 实例处理布局
- 树形结构：`parent` / `children`，循环引用检测
- 生命周期钩子：`onUpdate(dt)`, `onDraw()`, `onPostDraw()`, `onEnabled()`, `onDisabled()`, `onFocus()`, `onRemoveFocus()`
- 事件处理：事件通过 `handleEvent(event_type, ...)` 传播，**子节点先处理，然后才是自身**。如果子节点的 handler 返回 `true`，事件被拦截不再继续传播
- 事件 handler 命名约定：LÖVE 事件名转 PascalCase 加 `on` 前缀，如 `KeyPressed` → `onKeyPressed`, `MouseMoved` → `onMouseMoved`
- 状态标志：`enabled`, `shown`, `focus`, `_valid`
- `regionDetection(px, py)` — 检测屏幕坐标是否在 widget 包围盒内（考虑旋转，不考虑透明区域）
- `enableDebug(true)` — 绘制包围盒（含 AABB 和旋转后的 bound）

**Transform** (`ui/transform.lua`) — 每个 widget 持有一个 Transform 实例，实现类似 Unity 的 anchor-based 布局：
- `anchor = {minx, miny, maxx, maxy}` — 锚点范围，0~1 百分比的父容器坐标
  - 如果 min == max，尺寸固定（由 `w`/`h` + `padding` 决定位置偏移）
  - 如果 min != max，尺寸自适应（由锚点范围减去 `padding` 决定尺寸）
- `pivot = {x, y}` — 支点，0~1 百分比的自尺寸坐标，旋转/缩放中心
- `padding = {left, right, top, bottom}` — 像素偏移
- `x`, `y` — pivot 相对锚点范围左上角的偏移（像素）
- `setPosition`/`setSize` 会反向影响 padding 值
- `setPadding`/`setAnchor` 会反向影响 x/y 或 w/h
- 全局坐标链：`getGlobalPosition()` → `getGlobalScale()` → `getGlobalScaledSize()` → `getGlobalBounds()` 递归通过父级计算

**Theme** (`ui/theme.lua`) — 默认主题定义，包含 panel、text、textinput、image、button、imagebutton 的默认样式。widget 构造函数接受 `theme` 参数覆盖默认主题；`datas` 中的字段优先级高于 theme。

**Fonts** (`ui/fonts.lua`) — 字体注册表，按 key + size 懒加载并缓存 `love.graphics.Font` 对象。

**Components** (`ui/components.lua`) — 可复用的行为组件，如 `addHoverState` 混入 hover 检测。

### Widget 继承体系

```
Widget (基类)
├── Panel — 纯色面板，可设背景色、描边、圆角
├── Text — 文本渲染，支持 coloredtext、自动换行、对齐
├── Image — 贴图渲染，支持 tint 着色、clamp 模式拉伸填充
├── NineSlice — 九宫格切图渲染
├── ButtonBase (继承 Widget)
│   ├── Button — 文字按钮，6 种状态样式（normal/hover/pressed/disabled/selected/selected_hover）
│   └── ImageButton — 图片按钮，与 Button 相同的状态机，附加纹理/tint 切换
├── TextInput — 文本输入框，光标控制、选区、换行、滚动
├── ScrollableList — 包含列表子元素的滚动容器
└── SliderBar — 垂直滑块（未完成）
```

## 依赖库

| 库 | 路径 | 用途 |
|---|---|---|
| classic | `dependencies/classic.lua` | OOP 类系统 |
| i18n | `dependencies/i18n/` | 本地化框架（当前仅 zh-cn） |
| Lovebird | `dependencies/lovebird/` | 远程调试控制台（HTTP :8000） |
| tween | `dependencies/tween.lua` | 补间动画（ScrollableList 在用） |

## 编码规范

以下规范从现有代码中归纳而来，编写新代码时应当遵循。

### 缩进

使用 **Tab** 缩进，不用空格。

### 命名

| 对象 | 风格 | 示例 |
|---|---|---|
| 局部变量、函数参数 | `snake_case` | `ui_root`, `left_panel`, `b_img`, `old_state`, `font_key`, `text_color` |
| 类内部字段（self.xxx） | `snake_case` | `self.bg_color`, `self.outline_width`, `self.text_color` |
| 类方法 | `camelCase` | `addWidget`, `getGlobalPosition`, `setCursorIndex`, `removeAllChildren`, `handleEvent` |
| 类名 | `PascalCase` | `Widget`, `Panel`, `TextInput`, `ButtonBase`, `UiManager`, `Transform` |
| 常量、枚举 | `UPPER_CASE` | `TWO_PI`, `UI_COLORS`, `BTN_STATES`, `TEXT_WRAP_MODE`, `FPS` |
| Lua 文件名 | `snake_case` | `ui_manager.lua`, `button_base.lua`, `scrollable_list.lua` |
| 私有成员、私有函数 | `_` 单下划线前缀 | `self._name`, `self._valid`, `self._debug`, `_updateLeftRight`, `_calcAABB` |
| 元属性、元方法 | `__` 双下划线前缀 | `self.__text`（Text 的内部 love.graphics.Text 对象）, `self.__quad`（Image 的 Quad 对象）, `self.__instance`（单例）, `__oldw`/`__oldh`（缓存的前一帧尺寸） |

当闭包内同时存在外层 `self` 和内层 widget 的 `self` 时，内层 widget 的回调参数命名为 `_self`，以便与外层 `self` 区分：

```lua
-- _self = 被操作的内层 widget, self = 闭包捕获的外层 widget
on_pressed = function(_self, x, y)
    self.drag = true
end
```

### 注释

- 单行注释：`-- 注释文本`（`--` 后跟空格）
- 多行文档注释：`--[[...]]`，用于 widget 的 datas 参数文档
- EmmyLua 类型注解：`---@param name type 说明`、`---@return type 说明`、`---@type type`
- 代码区块分隔：`--------------------------------------------------` 水平线 + 区块标题，例如 `-- Event Handlers`、`-- Update & Draw`
- 注释语言以中文为主

### Widget datas 文档块

每个 widget 文件顶部应有结构注释描述其构造函数 `datas` 接受的字段：

```lua
--[[datas: 此处不包括当前Widget继承的基类所支持的字段
    bg_color = {r, g, b, a}
    outline_width = number
    outline_color = {r, g, b, a}
    rounding_radius = number
]]
```

### 模块结构

每个 `.lua` 文件遵循以下结构：

```lua
-- 1. require 依赖
local Dep1 = require "path.to.dep1"
local Dep2 = require "path.to.dep2"

-- 2. 私有本地函数和数据
local function privateHelper()
end

-- 3. 类定义
local MyClass = Class(BaseClass, function(self, datas, theme)
    BaseClass.new(self, "ClassName", datas, theme)
    self.field = datas and datas.field or default_value
end)

-- 4. 公有方法（按功能分组，用分隔线隔开）
function MyClass:publicMethod()
end

-- 5. 事件处理器（onXxx 命名）
function MyClass:onEventName()
end

-- 6. return 模块
return MyClass
```

### 类定义

- 使用 `Class(BaseClass, function(self, datas, theme) ... end)`，来自 `dependencies/classic.lua`
- `datas` — 构造参数表（可选），`theme` — 主题表（可选）
- 构造中首先调用 `BaseClass.new(self, "name", datas, theme)`
- 默认值使用 Lua 惯用法：`datas and datas.field or default_value`
- widget 名称为 PascalCase 字符串，如 `"Panel"`, `"TextInput"`

### 方法定义

- 公有方法一律使用冒号语法：`function ClassName:methodName(args)`
- 私有辅助函数使用 `local function function_name(args)`
- 不要混用点语法定义方法

### 事件系统

- 事件处理器命名：`on` + PascalCase 事件名 — `onMousePressed`, `onKeyPressed`, `onUpdate`, `onDraw`, `onPostDraw`, `onFocus`, `onRemoveFocus`, `onSetState`, `onClick`, `onPressed`, `onSelected`, `onHovered`, `onSizeChanged`
- `handleEvent(event_type, ...)` 内部通过字符串拼接 `"on" .. event_type` 动态查找 handler
- 事件传播：子节点优先（倒序遍历 children），子节点返回 `true` 则拦截事件

### 全局变量

- `Class` 是唯一刻意设为全局的变量（在 `main.lua` 中 `Class = require "dependencies.classic"`）
- 其他所有 require 结果赋值给 `local` 变量
- 单例通过闭包持有私有 `__instance` 实现（见 `ui_manager.lua`）

### 字符串与比较

- 字符串拼接使用 `..` 操作符
- `nil` 检查使用 `~= nil` 或 `if not x then`
- 遍历数组使用 `ipairs`，遍历表使用 `pairs`
- 使用 Lua 标准库：`table.insert`, `table.remove`, `table.concat`, `string.format`, `string.sub`, `math.*`, `assert`, `unpack`
- UTF-8 字符处理使用 `utf8` 库（`utf8.len`, `utf8.offset`, `utf8.codes`, `utf8.char`）

