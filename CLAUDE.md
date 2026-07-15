# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

**Muse** — 基于 LÖVE (Love2D) 游戏引擎的 UI 框架，使用 Lua 编写。它实现了一套完整的桌面级 UI widget 系统，包括布局引擎、主题系统、文本输入、滚动列表等功能。

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
- 渲染层缓存：`draw()` 缓存在 `_layers_cache`/`_sorted_layers`，仅在 `addWidget`/`removeWidget`/`show`/`hide` 或手动 `invalidateRenderCache()` 时重建
- 生命周期：`addWidget`/`removeWidget` 通过 `_setAttached(true/false)` 递归触发子树的 `onAttached`/`onDetached`
- Widget 计数：`_widget_count` 在 create/destroy 时增减，用于性能诊断
- Tab 键焦点切换：`_handleTabFocus` 收集所有 `focusable` widget 循环切换

获取方式：`require "ui.ui_manager":GetInstance()`

**Widget** (`ui/widgets/widget.lua`) — 所有 UI 元素的基类。核心机制：
- 持有 `Transform` 实例处理布局
- 树形结构：`parent` / `children`，循环引用检测
- 生命周期钩子：
  - **更新**: `onUpdate(dt)`
  - **绘制**: `onDraw()`, `onPostDraw()`
  - **状态**: `onEnabled()`, `onDisabled()`, `onFocus()`, `onRemoveFocus()`
  - **活动树加入/离开**: `onAttached()`, `onDetached()`（由 UiManager 通过 `_setAttached` 递归调用，子类可覆写以管理全局资源）
- 事件处理：事件通过 `handleEvent(event_type, ...)` 传播，**子节点先处理，然后才是自身**。如果子节点的 handler 返回 `true`，事件被拦截不再继续传播
- 事件 handler 命名约定：LÖVE 事件名转 PascalCase 加 `on` 前缀，如 `KeyPressed` → `onKeyPressed`, `MouseMoved` → `onMouseMoved`
- 状态标志：`enabled`, `shown`, `focus`, `_valid`, `_attached`（是否在 UiManager 活动树中）
- Canvas 缓存 API：`enableCanvasCache()` / `invalidateCanvasCache()` — 适用于纯静态子树（注意：会破坏交互事件，谨慎使用）
- `regionDetection(px, py)` — 检测屏幕坐标是否在 widget 包围盒内（考虑旋转，不考虑透明区域）
- `removeAllChildren()` — 摘除子节点，不销毁（TabView 切 tab 等需复用场景）
- `clearChildren()` — 摘除并销毁子节点，释放 GPU 资源（场景切换等不再需要场景）
- `enableDebug(true)` — 绘制包围盒（含 AABB 和旋转后的 bound）。**返回 self**，支持链式调用

**Transform** (`ui/transform.lua`) — 每个 widget 持有一个 Transform 实例（Class OOP，方法挂在 metatable 共享），实现类似 Unity UGUI 的 anchor-based 布局：
- `anchor = {minx, miny, maxx, maxy}` — 锚点范围，0~1 百分比的父容器坐标
- `pivot = {x, y}` — 支点，0~1 百分比的自尺寸坐标，旋转/缩放中心
- `padding = {left, right, top, bottom}` — **唯一的真相源**（像素偏移），所有 setter 最终写入这里
- `x`, `y`, `w`, `h` — 缓存字段，由 `_recalcLayout()` 从 padding + anchor + pivot 派生
- 所有 setter（`setPosition`/`setSize`/`setPadding`/`setPivot`/`setAnchor`）立即调用 `_recalcLayout` 同步缓存
- `onUpdate` 检查 10 个真相字段（padding × 4 + anchor × 4 + pivot × 2 + parent_w/h），dirty 时重算
- 全局坐标链：`getGlobalPosition()` → `getGlobalScale()` → `getGlobalScaledSize()` → `getGlobalBounds()` 递归通过父级计算
- `Widget:getCullAABB()` — 供可见性裁剪使用的虚方法，子类（如 Text）可覆写以提供精确包围盒

**Theme** (`ui/theme.lua`) — 默认主题定义，包含 panel、text、textinput、image、button、imagebutton 的默认样式。widget 构造函数接受 `theme` 参数覆盖默认主题；`datas` 中的字段优先级高于 theme。

**Fonts** (`ui/fonts.lua`) — 字体注册表，按 key + size 懒加载并缓存 `love.graphics.Font` 对象。

**Components** (`ui/components.lua`) — 可复用的行为组件，如 `addHoverState` 混入 hover 检测。

### 枚举常量（`ui/utils.lua`）

所有字符串枚举集中在 `Utils` 表中，避免魔法字符串拼写错误：

| 常量表 | 可选值 | 使用位置 |
|---|---|---|
| `Utils.ORIENTATION` | `VERTICAL`, `HORIZONTAL` | List, Box, SliderBar, ProgressBar |
| `Utils.H_ALIGN` | `LEFT`, `CENTER`, `RIGHT`, `JUSTIFY` | Text, TextInput |
| `Utils.V_ALIGN` | `TOP`, `CENTER`, `BOTTOM` | Text, TextInput |
| `Utils.CROSS_ALIGN` | `STRETCH`, `START`, `CENTER`, `END` | Box |
| `Utils.CHECKBOX_STYLE` | `CHECKBOX`, `TOGGLE` | Checkbox |
| `Utils.BTN_STATES` | `NORMAL`, `PRESSED`, `DISABLED`, `SELECTED`, `HOVER`, `SELECTED_HOVER` | ButtonBase |
| `Utils.TEXT_WRAP_MODE` | `OFF`, `DEFAULT` | Text, TextInput |

使用 `Utils.validateEnum(value, enum, default, label)` 校验输入，非法值时打印警告并回退为默认值。

### Widget 继承体系

```
Widget (基类)
├── Panel — 纯色面板，可设背景色、描边、圆角
├── Text — 文本渲染，支持 coloredtext、自动换行、对齐
├── Image — 贴图渲染，支持 tint 着色、clamp 模式拉伸填充
├── NineSlice — 九宫格切图渲染
├── ProgressBar — 进度条，支持水平/垂直方向
├── Modal — 模态框，全屏遮罩+居中内容，Escape/点击外部关闭
├── TabView — 标签页视图，顶部 Button 栏+下方内容面板
├── RadioGroup — 单选按钮组，管理互斥行为
├── ButtonBase (继承 Widget)
│   ├── Button — 文字按钮，6 种状态样式
│   ├── ImageButton — 图片按钮，附加纹理/tint 切换
│   └── Checkbox — 复选框，继承六态 FSM，toggle 切换
│       └── RadioButton — 单选框，覆写 onDraw 渲染圆形
├── TextInput — 文本输入框，光标控制、选区、剪贴板、撤销/重做
├── Scroll — 滚动容器，含 scissor 裁剪 + 可选滑条
├── SliderBar — 滑块，支持水平/垂直，AXIS 抽象
├── List — 列表容器，支持水平/垂直，脏标记布局 + updateItems diff 复用
├── Box — Flexbox 式布局容器，flex_grow/shrink 分配
├── Dropdown — 下拉选择，popup 通过 onAttached/onDetached 自动管理
```

### Transform 锚点模式与真相源

Transform 的布局系统基于 **padding 作为唯一真相源**（类似于 Unity UGUI 的 offsetMin/offsetMax）：

```
字段分层：
  配置层：anchor_min, anchor_max（锚点范围，0~1 父容器百分比）
         pivot（支点，0~1 自身百分比）
  真相源：left, right, top, bottom（像素偏移，所有 setter 最终写入这里）
  缓存层：x, y, w, h（由 _recalcLayout 从真相源派生，只读）
```

核心公式（点锚点和拉伸锚点共用，不再分支）：
```lua
w = parent_w * (anchor_max_x - anchor_min_x) - left - right
h = parent_h * (anchor_max_y - anchor_min_y) - top - bottom
x = left + w * pivot_x
y = top  + h * pivot_y
```

点锚点（min == max）时 `anchor_w == 0`，公式自然退化为 `w = -left - right`，
`_recalcLayout` 仅在 `anchor_w > 0` 时才重算尺寸，否则保留 `setSize` 设定的值。

setter 规则：每个 setter 对同一轴同时更新两端 padding，保持"改 A 时 B 不变"：
- `setPosition(x)` → 同时更新 left 和 right，保持 w 不变
- `setSize(w)`    → 同时更新 left 和 right，保持 x 不变
- `setPivot(px)`  → 同时更新 left 和 right，保持 x 和 w 都不变
- `setPadding(l,r,t,b)` → 直接写真相源
- `setAnchor(...)` → 写配置层，触发重算

Widget 构造中 datas 的处理顺序：`pivot → anchor → position → padding → size`，
后调用的 setter 覆盖前者的 padding 值，符合"position 定位 + size 定尺寸"的直觉。

### 测试场景组织

测试 UI 代码放在 `tests/ui/` 下，每个文件返回 `{name = "名称", create = function(parent)}` 表。`main.lua` 左侧为可滚动组件列表（Scroll + Button），右侧为 `display_area`（Widget 容器），点击按钮调用 `selectTest(i)` 切换到对应测试脚本。

### 闭包前向引用

当按钮的 `on_click` 闭包需要引用**稍后才创建的** widget（如 Modal 的关闭按钮引用 modal 自身），在闭包之前声明 `local modal`（不赋值），闭包捕获该变量，后续赋值才会生效。否则变量会成为全局变量或被 IDE 报告未定义。

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

## 变更记录

### 2026-07-15 — 事件返回值 + raycast_target 射线检测
- **feat** (`c268eb0`): UiManager 事件方法（KeyPressed/MousePressed/...）返回 `true`/`false` 标记是否被 UI 消费
- **feat** (`e2c1dd8`): Widget 新增 `raycast_target` 属性（Unity 式射线检测开关），可视控件默认 `true`
  - `handleEvent` 对鼠标事件有 fallback：无显式 handler 但 `raycast_target && regionDetection` 时也返回 `true`
  - 解决了"Panel 没有 onMousePressed 但视觉上遮住了鼠标"导致外部分发判断不准的问题

### 2026-07-14 — Transform 重构 + 列表机制
- **refactor** (`866af28`, `9b54f42`): Transform 统一真相源为 padding，消灭双模式分支
  - 4 个 `_update*` 函数 → 1 个 `_recalcLayout`，点锚点和拉伸锚点共用一个公式
  - `setPosition`/`setSize`/`setPivot` 对同轴同时更新两端 padding，保持不变量
  - `_recalcLayout` 仅在 `anchor_w > 0` 时重算尺寸，构造期 parent_w=0 时产生负尺寸的 bug 已消除
- **feat** (`10cf024`): List 新增 `updateItems(newData, keyFn, createFn, updateFn)` — diff 复用机制
- **fix** (`7d9ee8f`): Text 新增 `getCullAABB()` 虚方法覆写，使用文本实际尺寸做 Scroll 裁剪
- **fix** (`d901504`): Scroll AABB 裁剪加入容差，仅完全不可见元素才跳过子树

### 2026-06-06 — 回合 1
- **refactor** (`b7dcfd2`): 提取算法中的魔术数字为 `UPPER_CASE` 伪常量，涵盖 checkbox/sliderbar/scroll_container/widget/theme/textinput/text/button/tabview/image/chat_history 共 11 个文件
- **fix** (`b5b4ffa`): SliderBar 圆角在 `setBlockLengthPercent` 时同步更新；main.lua 性能显示改为每秒刷新
  - `_updateBlockRounding()` 用 `self.transform[a.alter_size]`（薄边维度）计算圆角，`onSizeChanged` 和 `setBlockLengthPercent` 两处调用
  - 根因：窗口 resize→文字重排→`setBlockLengthPercent` 改变 block 尺寸，但 `onSizeChanged` 不触发（SliderBar 自身尺寸未变），圆角停留在旧值导致椭圆变形

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

## 常见陷阱与潜规则

### Transform / 布局

- **`setSize` 对拉伸锚点不会保持 x 不变**：拉伸锚点下 x 由 `left + w * px` 推导，改 `w` 会连带移动 pivot。需要位置不变时用 `setPosition` 配合 `setSize`
- **构造期 `parent_w == 0`**：Widget 构造时父控件尺寸未就绪，`setPadding` 不会算出有效尺寸（`_recalcLayout` 有 `aw > 0` 守卫），依赖 `measure()` 返回正确值的布局应放在首帧 `onUpdate` 中
- **`pivot` 非零时 `getGlobalBounds()` 返回的是左上角坐标**，不是 pivot 坐标。`regionDetection` 已正确处理这一点，但手写碰撞检测需要注意
- **Text 的 `transform.w/h` 默认为 0**：Text 把尺寸存在 `love.graphics.Text` 对象里，不写入 transform。`getGlobalAABB()` 走 Transform 本地函数读 `self.w/h`（＝0），Text 通过覆写 `Widget:getCullAABB()` 规避了裁剪问题，但 debug 框（`drawBound`）对 Text 仍会画出零面积框

### List / 动态列表

- **不要每帧调 `setItems`**：`setItems` 内部 `removeAllChildren + addChild`，每帧重建会销毁旧控件。按钮的 `pressed` 状态、TextInput 的焦点/光标/选区都会丢失。应使用 `updateItems(data, keyFn, createFn, updateFn)` 做 diff 复用
- **`measure(nil, nil)` 不代表"无约束"**：List 和 Box 的 layout 都传 `nil` 给 `measure()`，但实际子控件往往受父容器宽度约束（拉伸锚点）。需要自身宽度的 widget（TextInput、带换行的 Text）应在 `measure` 内部 fallback 到 `self.transform.w`

### TextInput

- **`single_line` 只管 Enter 和粘贴，不管换行模式**：需显式调 `self.text:setWrapMode(Utils.TEXT_WRAP_MODE.OFF)` 才能真正阻止文字折行
- **`height_adaptive` 的 `min_height` 应用顺序**：`max(min_height, text_h) + padding`，不是 `max(min_height, text_h + padding)`。`measure()` 必须和 `refreshHeight()` 用同一公式，否则 ListV 布局和实际渲染高度不一致
- **失焦不会自动清选区**：`onRemoveFocus` 里需手动调 `_clearSelection()`，否则失焦后蓝色高亮残留
- **getWrap 缓存**：`_getSectionWrap(i)` 缓存每段落的换行结果，`flushText` 时失效。避免每次光标移动都重算全文换行

### Scroll

- **内容必须通过 `setItem()` 设置**：直接 `addChild` 到 Scroll 本体不会进 `scroll_root`，裁剪和滚动都失效
- **`_clip_rect` 比 scissor 略大（1px 容差）**：防止浮点精度导致边缘元素被整棵子树跳过

### 通用

- **`Widget:enableDebug()` 返回 `self`**，`Widget({...}):enableDebug(true)` 支持链式调用
- **事件传播是"子节点优先，兄弟间从后往前"**：后 `addChild` 的先收到事件。`handleEvent` 返回 `true` 才拦截，返回 `nil` 会继续传播
- **`parent_should_update=false` 时跳过整棵子树**：隐藏/禁用祖先不再递归子节点的 transform 检测和 onUpdate。子节点自身禁用的仍传播给活跃孙节点
- **`removeAllChildren` vs `clearChildren`**：前者只摘除不销毁（TabView 复用），后者调 `destroy()` 递归释放 GPU
- **Widget 生命周期**：`onAttached`/`onDetached` 在 Widget 进入/离开 UiManager 活动树时触发。Dropdown 用此管理 popup；Tooltip 是无父节点的独立 widget，构造时直接自注册
- **`regionDetection` 对 Text 使用 `Widget:getGlobalScaledSize()`（虚方法）**：Text 覆写返回文本实际尺寸，所以鼠标碰撞检测正常。但 Transform 本地的 `getGlobalBounds()` 对 Text 仍然返回 `w=0`，不要在用 debug 框判断 Text 尺寸时被误导
- **`UiManager` 事件方法返回 `bool`**：外部可据此判断事件是否被 UI 消费（`true`=被处理/遮挡，`false`=穿透到空白）。`MousePressed` 的 `clearFocus` 不计入返回值
- **FPS 与 Widget 数量正相关**：每个 widget 每帧执行 transform 脏检测 + draw call。预期 ~300fps@50 widgets。大批量时考虑虚拟滚动或减少可见 widget

