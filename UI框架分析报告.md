# UI 框架分析报告

## 一、性能考量

以下条目在 widget 数量较小时不会构成可观测的性能问题，但对于大规模 UI 场景（如包含数百个列表项的聊天记录、长列表等）值得关注。

### 1.1 容器每帧全量重新布局

`list_h_container.lua` 和 `list_v_container.lua` 在 `onUpdate(dt)` 中无条件调用 `layout()`，每帧遍历所有子元素重新计算位置和自身尺寸。即使没有任何子元素增删、尺寸变化，也会执行完整的 O(n) 布局重算。

```
-- list_h_container.lua:83-85
function List:onUpdate(dt)
    self:layout()  -- 每帧无条件执行
end
```

`layout()` 内部会修改 `self.transform` 的尺寸（`self.transform:setSize(self.list_total_width)`），连带触发 transform 的 `onUpdate` → `_updateWidthAndX` 对 padding 的反向计算。

**建议**：引入脏标记，仅在子元素增删或容器尺寸变化时才重新布局。

### 1.2 Text 组件频繁重建文本对象

`Text:updateTextLayout()` 每次调用都执行 `self.__text:clear()` 后跟 `self.__text:setf(...)`，重建整个 `love.graphics.Text` 对象。在 TextInput 中，每次按键（包括方向键移动光标）都会触发 `flushText()` → `text:setText()` → `updateTextLayout()`。对于较小的文本量这不是问题，但如果输入框包含数百行文本，频繁重建会带来可感知的开销。

**建议**：对高频变化的 TextInput 场景考虑增量更新文本而非整体重建。

### 1.3 无可见性裁剪

Widget 树的 `draw()` 和 `update()` 遍历是全量递归的，不做视口外裁剪。对于 ScrollContainer 这类只有部分内容可见的场景，`scroll_root` 下的子节点即使完全在裁剪区之外也会被遍历。LÖVE 的 `love.graphics.setScissor` 只裁剪 GPU 端像素输出，不跳过 Lua 层的 draw 调用。

---

## 二、功能特性完整度

### 2.1 缺失的基础 Widget

| 缺失控件 | 说明 |
|---|---|
| Checkbox / Toggle | 勾选框、开关控件 |
| RadioButton / RadioGroup | 单选按钮组 |
| Dropdown / ComboBox | 下拉选择框 |
| Tooltip | 鼠标悬停提示 |
| ProgressBar | 进度条 |
| TabView | 标签页切换 |
| Modal / Dialog | 模态对话框（带遮罩层） |

### 2.2 容器系统不完整

`box_h_container.lua` 和 `box_v_container.lua` 是空文件。现有的 list 容器按照子元素的自然尺寸排列，而注释中指出的 box 容器应当实现"固定容器尺寸、自动拉伸或压缩子元素"的行为（类似 Flexbox 的 stretch 模式），目前不存在。

### 2.3 TextInput 功能缺失

- **无文本选区**：光标只能定位，不能按住 Shift 或拖动鼠标选中一段文字
- **无复制/粘贴**：没有与系统剪贴板的交互（LÖVE 提供 `love.system.getClipboardText` / `setClipboardText`）
- **无撤销/重做**：没有操作历史栈

### 2.4 焦点管理系统缺失

UiManager 不维护当前焦点 widget 的记录。每个 widget 各自管理 `self.focus` 状态。导致无法实现 Tab 键在输入框之间切换焦点，无法通过 UiManager API 查询当前焦点 widget，点击 widget 外部区域不会自动移除焦点。TextInput 在自己内部处理了焦点切换逻辑，但缺乏统一机制。

### 2.5 主题系统未被充分利用

`Theme` 类虽已定义且文档说明可以继承定制，但实际代码中没有任何地方创建过 Theme 的子类。所有样式差异都通过在 `datas` 中逐个覆盖字段来实现。

### 2.6 动画/过渡

补间动画依赖 `dependencies/tween.lua`，使用方式不完全一致——`ScrollContainer` 和 `CollapsiblePanel` 都使用 `Tween.newFunctionalTween`，但缺乏统一的 UI 过渡动画策略，面板展开/折叠等过渡都需要手动管理 tween 对象。

---

## 三、算法 Bug

### 3.1 颜色值双重转换（严重）

`ChatBubble:updateStyle()` 中对 `setTextColor` 的调用存在颜色空间转换的 bug。

```lua
-- chat_history.lua:76
self.text:setTextColor(unpack(style.text_color or self.text.theme.text.text_color))
```

`Text:setTextColor` 的实现：

```lua
-- text.lua:112-118
function Text:setTextColor(r, g, b, a)
    if type(r) == "table" then
        self.text_color = r
    else
        self.text_color = Utils.RGB(r, g, b, a)
    end
end
```

`style.text_color` 来自 `UiUtils.UI_COLORS.PRIMARY_TEXT`，它已经是 0~1 范围的值（`Utils.RGB(189, 189, 189)` → `{189/255, 189/255, 189/255, 1}`）。

`unpack()` 将表展开为独立数值传入，此时 `type(r)` 为 `"number"`，进入 `else` 分支，再次调用 `Utils.RGB()`：

```
Utils.RGB(189/255, 189/255, 189/255, 1)
→ {(189/255)/255, (189/255)/255, (189/255)/255, 1}
→ {0.0029, 0.0029, 0.0029, 1}
```

颜色被二次除以 255，实际渲染结果接近纯黑。此 bug 在动态更新气泡样式或修改聊天内容时触发（`updateChatBubble` → `updateStyle`）。

**根本原因**：`setTextColor` 同时接受"已转换的 table（0~1）"和"原始数值（0~255）"两种形式，但调用方无法从签名区分应该传哪种。主题系统中所有颜色存储的是已转换值，而 `setTextColor` 的数字参数路径假设输入是 0~255 原始值。

**修复方向**：将 `chat_history.lua:76` 的 `unpack()` 改为直接传表——`self.text:setTextColor(style.text_color or self.text.theme.text.text_color)`，使 `type(r) == "table"` 分支生效。或统一 `setTextColor` 的接口，只接受一种颜色格式。

### 3.2 cursor_blinking 使用模块级变量

```lua
-- textinput.lua:9-10
local cursor_blinking, cursor_blinking_timer = true, 0
```

这些变量是 `textinput.lua` 模块级的 `local`，所有 TextInput 实例共享同一个闪烁计时器。如果一个页面上存在两个 TextInput，它们的 `onUpdate` 都会对同一个 `cursor_blinking_timer` 累加 `dt`，闪烁频率会翻倍。此外，调用 `setCursorIndex` 会重置 `cursor_blinking_timer = 0`，影响另一个实例的闪烁周期。

在实际使用中同时存在多个 TextInput 的场景较少，但这是潜在问题。

---

## 四、算法优化

### 4.1 容器布局的增量更新

当前 list 容器的 `layout()` 每次都从零开始遍历所有子元素设置位置。对于 `insert` 追加单个元素的场景，可以只计算新元素的位置；对于删除场景，可以只调整后续元素的位置偏移。

### 4.2 Transform 更新合并

Transform 的 `onUpdate` 被 widget 的 `update(dt)` 每帧调用，即使数值未变也执行所有计算。可以在 `onUpdate` 中增加变更检测，仅在锚点/尺寸实际变化时才执行 `_updateLeftRight` / `_updateWidthAndX` 等函数。

### 4.3 ButtonBase mouseMoved 区域检测优化

```lua
-- button_base.lua:68-76
function ButtonBase:onMouseMoved(x, y, dx, dy)
    if self:regionDetection(x, y) then
```

`regionDetection` 在每次鼠标移动时调用，其中对旋转非零的 widget 执行三角函数运算。对于绝大多数旋转为 0 的 widget，可以先做快速 AABB 检测再降级到旋转检测，避免不必要的三角函数调用。

---

## 五、类设计

### 5.1 SliderBar 水平/垂直版本代码重复

`sliderbar_v.lua` 和 `sliderbar_h.lua` 共约 350 行代码，其中 ~90% 逻辑一致，仅在轴向上不同（x ↔ y, w ↔ h, left/right ↔ up/down）。两者的核心逻辑完全相同，仅变量名不同。任何 bug 修复或功能增强都需要在两个文件中同步进行。

**建议**：合并为一个 `SliderBar` 类，通过 `orientation` 参数区分方向。

### 5.2 List 容器水平/垂直版本代码重复

`list_h_container.lua` 和 `list_v_container.lua` 同理，差异仅在于 width/height 和 x/y 的处理。建议同样合并。

### 5.3 Widget 基类的 Transform 代理层

`Widget` 将 Transform 的所有 setter/getter（`setPosition`、`getPosition`、`getGlobalPosition`、`getGlobalScale` 等十几个方法）直接代理转发给 `self.transform`。这种做法提供了便捷的 `widget:getGlobalPosition()` 访问路径（而非 `widget.transform:getGlobalPosition()`），代价是增加了基类接口面积。这是一种有意识的便捷性设计选择，但需注意代理方法与其委托对象之间的耦合——如果 Transform 新增或变更方法，Widget 也需要跟随修改。

### 5.4 继承层次和相关问题

当前：`Widget → ButtonBase → Button / ImageButton`

`ButtonBase` 的状态机逻辑（六态切换、hover/press/click）实际上不仅适用于按钮。`TextInput` 通过 `addHoverState`（`components.lua`）独立实现了 hover 检测。`SliderBar` 的 block 子组件使用了 `Button` 来获得点击和拖拽行为——这导致"滑块是一个按钮"的语义扭曲，也使得 `Button` 的某些方法（如 `setSelected`）对滑块没有意义但依然暴露。

更合理的设计是将交互状态机（normal/hover/pressed/disabled 等）从 ButtonBase 中抽离为可组合的行为组件，让 Button、SliderBar block、ImageButton 等按需组合。

### 5.5 容器和内容 Widget 的层级

`Widget` 同时承担纯布局容器和视觉元素的角色。`ScrollContainer` 需要额外的 `scroll_root` 子 Widget 作为内容挂载点和偏移控制器。这种嵌套在滚动容器中是不可避免的（需要独立的坐标系来管理偏移），但确实增加了树的深度。

---

## 六、接口设计

### 6.1 `newButtonStateStyle` 使用位置参数

```lua
-- utils.lua:85
function Utils.newButtonStateStyle(text, text_color, font_size, bg_color,
    outline_width, outline_color, offset, scale, rounding_radius)
```

9 个位置参数，实际使用中大部分取默认值 nil：

```lua
normal = UiUtils.newButtonStateStyle("Normal"),
```

这种场景更适用传表方式，可读性更好。

### 6.2 Widget 构造参数不一致

| Widget | 构造参数 |
|---|---|
| Widget | `(name, datas, theme)` |
| Panel | `(datas, theme)` — 内部自动设 name |
| Button / ImageButton | `(datas, theme)` — 内部自动设 name |
| ChatHistory / CollapsiblePanel | `(datas, theme)` |

子类 widget 已统一为 `(datas, theme)` 模式，但基类 `Widget` 仍保留 `(name, datas, theme)` 签名。这意味着 `Widget("btns_root", {anchor = ...})` 可以直接传入自定义 name，而子类将 name 硬编码为固定字符串。这不是错误，但表明基类和子类在使用方式上有微妙的差异——如果未来有 widget 需要在构造时自定义 name，当前子类模式不支持。

### 6.3 `main.lua` 中导入了未使用的变量

```lua
-- main.lua:18
local Scroll = require "ui.widgets.containers.scroll_container"
```

`Scroll` 变量在 main.lua 中未被直接引用——`ChatHistory` 内部独立 require 了该模块。这个 require 只起到了确保模块加载的副作用。

### 6.4 类名拼写

```lua
-- collapsible_h_screen_edge_panel.lua:8
self._name = "CpllapsibleHScreenEdgePanel"
```

`Cpllapsible` 少了一个 `o`，应为 `Collapsible`。

### 6.5 方法名拼写

```lua
-- sliderbar_v.lua:92 & sliderbar_h.lua:92
function SliderBar:setBlockLengthtPercent(percent)
```

`Lengtht` 多了一个 `t`，应为 `Length`。两处同步存在，是对外暴露的公有方法。

### 6.6 setter 方法名未传达实际计算量

`ChatBubble:setText(text)` 的名字暗示它是一个简单的文本赋值，但实际做了：计算文本换行宽度 → 调整 root 的 transform 尺寸 → 调整自身的 transform 高度 → 最终设置文本。这是一个全量布局重建操作。

`TextInput:setCursorIndex(index)` 同样，不仅设置一个数字字段，还会遍历所有段落计算光标的像素坐标并缓存。

方法名没有传达这类"重型 setter"的计算副作用。调用者可能在循环中反复调用这些方法而没有意识到每步都在做 O(n) 的重计算。建议要么将计算部分拆分（`setText` + 独立的 `relayout`），要么在方法名上提示成本（如 `setTextAndRelayout`）。

---

## 七、架构设计问题

以下问题不涉及代码细节，而是框架的顶层设计假设及其连锁影响。

### 7.1 布局系统单向性：缺少 measure 阶段

当前布局模型是纯粹的父 → 子传递：父容器通过 anchor + padding 决定子元素的坐标和尺寸。子元素无法向父容器声明需求尺寸。

`TextInput` 的 `height_adaptive` 是这个问题的直接体现——它通过 `refreshHeight()` 手动修改自身 `transform.h`，绕过锚点计算，实现"根据文本内容自动调整高度"。但这是局部的、一层的 hack。如果 TextInput 外面还有一层容器，那层容器不知道 TextInput 变高了，不会调整自己的布局。如果它外面再套一个 panel，panel 也不知情。

在更完整的约束布局模型中，布局分为两个阶段：
1. **Measure**：子元素声明最小/首选尺寸（文本量了才知道要多高）
2. **Layout**：父元素根据子元素的声明和自己的策略分配空间

框架跳过了 measure，直接用锚点 + padding 的单向计算。在固定布局场景中足够，但在内容驱动的场景（聊天气泡根据消息长度自适应、表单根据标签文本自适应）中就暴露了不足——每个需要自适应的地方都得写类似 `height_adaptive` 的特例代码。

### 7.2 UiManager 全局单例：缺少 UI 上下文隔离

```lua
local UiManager = require "ui.ui_manager":GetInstance()
```

单例意味着整个进程中只有一个 UI 根、一套 widget 层级、一个默认主题。直接后果：

- **焦点作用域缺失**：如果存在两个逻辑上独立的 UI 区域（如游戏内 UI + 调试面板），它们共享同一个模糊的"焦点"概念。TextInput 各自管理 `self.focus`，但没有"哪个区域当前拥有焦点"的概念。
- **子树级默认主题不可行**：Widget 构造函数通过 `UiManager:getDefaultTheme()` 获取默认主题。如果想为某个子树设置不同的默认主题，只能逐个 widget 传参数，无法在子树根部设置一次就自动继承。
- **多视口**：无法在一个进程中为多个渲染目标创建独立的 UI 上下文。

### 7.3 渲染顺序完全绑定树结构

Widget 的绘制顺序由树遍历的自然顺序决定：父 → 子（按 children 数组顺序）。`moveToTop` / `moveToBottom` 通过调整 children 数组位置改变同级元素之间的顺序，但跨层级调整不可能。

实际需求中常见场景：对话框的遮罩层需要覆盖整个 UI；Tooltip 需要在所有 UI 之上渲染。当前做法只能将这些"顶层"元素手动挂在根节点下，破坏自然的树结构组织——逻辑上属于某个按钮的 Tooltip，在树结构上却必须脱离那个按钮，挂在根节点。

### 7.4 生命周期与输入事件共用 onXxx 命名空间，但执行机制不同

Widget 暴露了一组 `on<Something>` 方法供重写：`onUpdate`、`onDraw`、`onMousePressed`、`onKeyPressed`、`onFocus`、`onSetState` 等。它们被放在同一个命名空间下，但底层执行路径完全不同：

- `onUpdate`/`onDraw` 是无条件全量调用的生命周期方法（Widget.update/draw 直接遍历 children）
- `onMousePressed`/`onKeyPressed` 是通过 `handleEvent` 动态路由的输入事件，子节点可以返回 `true` 拦截传播
- `onSetState` 是按钮状态机主动调用的内部通知，不来源于外部输入

对 Widget 开发者而言，这个区分不明显。在 `onUpdate` 中返回 `true` 不会阻止 update 传播——因为 update 路径不检查返回值。但在 `onMousePressed` 中返回 `true` 会阻止兄弟节点收到该事件。同一命名约定下的不同行为差异，容易导致误用。

### 7.5 Class 全局化：框架与应用未解耦

```lua
-- main.lua:3
Class = require "dependencies.classic"
```

`ui/` 下所有模块直接引用全局变量 `Class`，不 require、不导入。这意味着：
- 框架模块依赖由应用层（main.lua）设置的全局变量，二者存在隐式的加载顺序依赖——必须先执行 `Class = require "dependencies.classic"`，才能 require 任何 `ui/` 下的模块
- 无法独立加载和测试单个模块：即使 `Transform` 完全不依赖 `Class`，加载 `transform.lua` 本身没问题，但加载任何 widget 模块都依赖全局 `Class` 已经就位
- 如果另一个 LÖVE 项目想引入这个 UI 框架，必须同样设置全局 `Class`，或者修改所有框架模块的引用方式

---

## 八、其他发现

### 8.1 无自动化测试

整个项目没有任何单元测试或集成测试。所有验证依赖 `main.lua` 中的手动构造 UI 和目视检查。对于布局引擎（Transform）这种纯计算、无渲染依赖的模块，缺乏自动化测试意味着重构和回归验证的难度较高。

### 8.2 LÖVE/Lua 版本语境

项目运行于 LÖVE 11.5（当前最新稳定版），使用 **LuaJIT**（基于 Lua 5.1 + 扩展），而非 Lua 5.4。这带来的具体影响：

- LuaJIT 的 `ffi` 模块可用于高性能 C 数据结构互操作，但目前项目中未使用
- Lua 5.1 不支持 `goto` 语句（Lua 5.2+ 才引入），`text.lua` 中的 `::continue::` 在 LuaJIT 环境下是有效的——LuaJIT 有自己的扩展
- 字符串拼接和表操作在 LuaJIT 下性能远超标准 Lua，意味着报告 1.1 ~ 1.3 中的性能考量的实际影响比初版估计的还要低
- `love.graphics.Text` 在 LÖVE 11.x 中不支持修改已创建的文本内容，只能 `clear()` + `setf()` 重建，这限制了报告 1.2 的优化方向
