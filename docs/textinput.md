# TextInput

文本输入框，支持光标控制、文本选区、剪贴板、撤销/重做、自适应高度和单行模式。

**继承链：** `Widget` → `TextInput`

## 构造参数（datas）

```lua
{
    text = string,                -- 初始文本
    height_adaptive = boolean,    -- 是否自动调节高度以适配文本高度，默认 false
    min_height = number,          -- 自适应高度时的最小高度，默认 75
    single_line = boolean,        -- 单行模式（Enter 不换行、粘贴过滤换行），默认 false
    on_submit = function(),       -- 单行模式下按 Enter 的回调

    bg = Widget,                  -- 背景 Widget（自动保持尺寸一致）

    hint = string,                -- 占位提示文本
    hint_color = {r, g, b, a},    -- 占位提示颜色，默认来自 theme

    font_key = string,            -- 字体 key
    font_size = number,           -- 字号
    text_color = {r, g, b, a},    -- 文本颜色
    h_align = string,             -- 水平对齐："left" | "right" | "center" | "justify"
    v_align = string,             -- 垂直对齐："top" | "bottom" | "center"
    text_padding = {l, r, t, b},  -- 文本内边距，默认 {8, 8, 8, 8}
}
```

## 公有方法

### 文本操作

| 方法 | 说明 |
|------|------|
| `setText(text)` | 设置文本内容 |
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

### 光标操作

| 方法 | 说明 |
|------|------|
| `showCursor(show)` | 显示/隐藏光标 |
| `setCursorIndex(index)` | 设置光标在段落中的 UTF-8 字符索引 |
| `setCursorPosByScreenPos(screen_x, screen_y)` | 根据屏幕坐标设置光标位置 |
| `moveCursorLeft()` | 光标左移 |
| `moveCursorRight()` | 光标右移 |
| `moveCursorUp()` | 光标上移 |
| `moveCursorDown()` | 光标下移 |
| `moveCursorToHead()` | 光标移到行首 |
| `moveCursorToEnd()` | 光标移到行尾 |

### 选区操作

| 方法 | 说明 |
|------|------|
| `selectText(start_sec, start_idx, end_sec, end_idx)` | 设置选区 |
| `selectAll()` | 全选 |
| `copy()` | 复制选区到剪贴板 |
| `paste()` | 从剪贴板粘贴 |
| `lineBreak()` | 插入换行 |
| `backspace()` | 退格删除 |
| `delete()` | 前向删除 |

### 撤销/重做

| 方法 | 说明 |
|------|------|
| `undo()` | 撤销 |
| `redo()` | 重做 |

撤销栈最大容量 100，相同类型连续操作（如连续输入字符）会被合并为一组。停顿超过 0.3 秒自动提交当前组。

### 段落操作

| 方法 | 说明 |
|------|------|
| `appendNewSection()` | 追加新段落 |
| `insertNewSection(pos, section)` | 在指定位置插入段落 |
| `removeSection(pos)` | 移除段落 |
| `flushText()` | 将 sections 同步到内部 Text 组件 |
| `refreshHint()` | 刷新占位提示的显隐 |
| `refreshHeight()` | 刷新自适应高度 |

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

## 示例

```lua
local input = TextInput({
    anchor = {0, 0, 1, 0},
    h = 40,
    hint = "Type something...",
    single_line = true,
    on_submit = function()
        print("submitted:", input:getText())
    end,
})
```
