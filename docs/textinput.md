# TextInput

文本输入框，支持光标控制、文本选区、剪贴板、撤销/重做、自适应高度、单行模式、原生滚动条和平滑滚动。

**继承链：** `Widget` → `TextInput`

## 构造参数（datas）

```lua
{
    text = string,                -- 初始文本
    height_adaptive = boolean,    -- 是否自动调节高度以适配文本高度，默认 false
    min_height = number,          -- 自适应高度时的最小高度，默认 75 或 datas.h
    single_line = boolean,        -- 单行模式（Enter 不换行、粘贴过滤换行符），默认 false
    on_submit = function(),       -- 单行模式下按 Enter 的回调

    bg = Widget,                  -- 背景 Widget（Panel），自动保持尺寸一致，获焦时边框加粗变蓝

    hint = string,                -- 占位提示文本（有内容时自动隐藏）
    hint_color = {r, g, b, a},    -- 占位提示颜色，默认来自 theme

    font_key = string,            -- 字体 key
    font_size = number,           -- 字号
    text_color = {r, g, b, a},    -- 文本颜色
    h_align = string,             -- 水平对齐："left" | "right" | "center" | "justify"
    v_align = string,             -- 垂直对齐："top" | "bottom" | "center"
    text_padding = {l, r, t, b},  -- 文本内边距，默认来自 theme（{8, 8, 8, 8}）
}
```

## 公有方法

### 文本

| 方法 | 说明 |
|------|------|
| `setText(text)` | 设置文本内容（覆盖） |
| `getText()` | 获取文本 |
| `setTextColor(color)` | 设置文本颜色 |
| `getTextColor()` | 获取文本颜色 |
| `setFont(font_key, size)` | 设置字体 |
| `getFont(return_key)` | 获取字体 |
| `setFontSize(size)` | 设置字号 |
| `getFontSize()` | 获取字号 |
| `setHAlign(align)` | 设置水平对齐 |
| `setVAlign(align)` | 设置垂直对齐 |
| `measure(max_w, max_h)` | 查询自然尺寸（含 padding 和 min_height） |
| `getMinimumSize()` | height_adaptive 时返回当前尺寸；否则返回 `(0, min(行高, min_height) + padding)` |

### 光标

| 方法 | 说明 |
|------|------|
| `showCursor(show)` | 显示/隐藏光标 |
| `setCursorIndex(index)` | 设置光标在段落中的 UTF-8 字符索引 |
| `setCursorPosByScreenPos(screen_x, screen_y)` | 根据屏幕坐标设置光标位置 |
| `moveCursorLeft()` / `moveCursorRight()` | 光标水平移动 |
| `moveCursorUp()` / `moveCursorDown()` | 光标垂直移动（跨段落和换行） |
| `moveCursorToHead()` / `moveCursorToEnd()` | 光标移到行首/行尾 |

### 选区

| 方法 | 说明 |
|------|------|
| `selectText(start_sec, start_idx, end_sec, end_idx)` | 设置选区 |
| `selectAll()` | 全选 |
| `copy()` | 复制选区到剪贴板 |
| `paste()` | 从剪贴板粘贴（多行按换行符分段插入） |
| `lineBreak()` | 插入换行 |
| `backspace()` | 退格删除 |
| `delete()` | 前向删除 |

### 撤销/重做

| 方法 | 说明 |
|------|------|
| `undo()` | 撤销 |
| `redo()` | 重做 |

撤销栈最大容量 100。相同类型的连续操作（连续输入、连续退格、连续删除）被合并为一组。光标移动/点击/回车等操作打破合并。停顿超过 0.3 秒自动提交当前组。

### 段落

| 方法 | 说明 |
|------|------|
| `appendNewSection()` | 追加新段落 |
| `insertNewSection(pos, section)` | 在指定位置插入段落 |
| `removeSection(pos)` | 移除段落 |
| `flushText()` | 将 sections 同步到内部 Text 组件 |
| `refreshHint()` | 刷新占位提示的显隐 |
| `refreshHeight()` | 刷新自适应高度（通知父容器重排） |

## 滚动机制

### 多行模式（默认）

- 内部维护 `_scroll_y` 平滑滚动偏移
- 每帧检测光标位置，光标超出可见区域时自动计算目标滚动位置
- 平滑逼近目标（每秒最多 5 行），避免突变
- 原生滚动条：6px 宽，在 `onPostDraw` 中绘制（轨道+比例滑块）
- 支持拖拽滑块和点击轨道跳转
- 鼠标滚轮：每次 3 行，仅在鼠标在区域内且有焦点时响应

### 单行模式

- `_scroll_x` 水平滚动偏移
- 获焦时跟踪光标位置，光标超出可见区域时自动调整
- 失焦时复位到文本开头

## 键盘快捷键

| 快捷键 | 操作 |
|--------|------|
| `Ctrl+A` | 全选 |
| `Ctrl+C` | 复制 |
| `Ctrl+V` | 粘贴 |
| `Ctrl+X` | 剪切 |
| `Ctrl+Z` | 撤销 |
| `Ctrl+Y` / `Ctrl+Shift+Z` | 重做 |
| `Shift+方向键` | 扩展选区 |
| `Home/End` | 行首/行尾 |
| `Enter` | 换行（多行模式）或触发 `on_submit`（单行模式） |

## 高度自适应

- `height_adaptive = true` 时，TextInput 高度由文本内容动态决定
- 高度计算公式：`max(min_height, text_h) + padding_top + padding_bottom`
- 高度变化时自动调用 `parent:queueSort()` 通知父容器重排（如果父容器支持）
- 构造时 transform 尺寸未就绪，首帧 `onUpdate` 补刷新

## 状态切换

- 获焦时：光标闪烁（1 秒周期，0.5 秒可见/0.5 秒隐藏），背景边框加粗变蓝
- 失焦时：光标隐藏，选区清除，滚动复位，背景边框恢复原样式
- 鼠标悬停时：光标变为 I-beam

## 示例

```lua
-- 单行输入框
local input = TextInput({
    anchor = {0, 0, 1, 0},
    h = 40,
    hint = "Type something...",
    single_line = true,
    on_submit = function()
        print("submitted:", input:getText())
    end,
})

-- 多行自适应高度
local textarea = TextInput({
    anchor = {0, 0, 1, 0},
    height_adaptive = true,
    min_height = 100,
    text_padding = {12, 12, 8, 8},
})

-- 带自定义背景
local styled = TextInput({
    bg = Panel({
        bg_color = Utils.RGB(40, 40, 50),
        rounding_radius = 6,
        outline_width = 1,
        outline_color = Utils.RGB(70, 70, 80),
    }),
    anchor = {0, 0, 1, 0},
    h = 120,
    text_padding = {12, 12, 12, 12},
})
```
