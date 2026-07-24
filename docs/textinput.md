# TextInput

文本输入控件。支持多行编辑、单行模式、文本选区、剪贴板操作、撤销/重做、光标闪烁、滚动条等。

**继承链：** `Widget` → `TextInput`

## 构造参数（datas）

```lua
{
    text = string,              -- 初始文本
    single_line = boolean,      -- 单行模式，Enter 触发 on_submit 而非换行，默认 false
    height_adaptive = boolean,  -- 高度随文本内容自动撑高，默认 false
    min_height = number,        -- 自适应高度时的最小高度，默认 75
    hint = string,              -- 占位提示文字（内容为空时显示）
    hint_color = {r, g, b, a},  -- 提示文字颜色
    on_submit = function,       -- 单行模式下按 Enter 的回调
    bg = Widget,                -- 背景控件（如 Panel），自动保持与输入框同尺寸
    text_padding = {left, right, top, bottom},  -- 文字内边距
    font_key = string,          -- 字体键
    font_size = number,         -- 字号
    text_color = {r, g, b, a},  -- 文字颜色
    h_align = "left" | "center" | "right" | "justify",
    v_align = "top" | "center" | "bottom",
}
```

## 工作原理

### 多行模式（默认）

内部使用按 `\n` 分段的 sections 数组管理文本。文本按 `transform.w` 宽度自动换行。内部垂直滚动通过调整内嵌 Text 子控件的 `padding.top/bottom` 偏移文本内容实现，配合 `onDraw` 中的 scissor 裁剪。

### 单行模式

`single_line = true` 时：Enter 触发 `on_submit`，粘贴的换行符被替换为空格，内部水平滚动替换垂直滚动。

### 高度自适应

`height_adaptive = true` 时，`refreshHeight()` 每帧根据文本实际高度调整输入框高度，不低于 `min_height`。

### 光标与选区

光标基于 UTF-8 字符索引（不是字节索引）。拖拽鼠标创建选区。`_sel_start`/`_sel_end` 记录选区起止的 `{section, index}`。

### 撤销/重做

基于快照的撤销栈（最大 100 条）。连续的同类操作（输入/退格/删除）在短暂停顿后合并为一条撤销记录。Ctrl+Z 撤销，Ctrl+Y 或 Ctrl+Shift+Z 重做。

### 滚动条

多行模式下，内容溢出时在右侧绘制原生滚动条（6px 宽轨道 + 比例滑块），支持滑块拖拽和轨道点击跳转。

## 公有方法

| 方法 | 说明 |
|------|------|
| `setText(text)` | 设置文本内容，覆盖当前文本 |
| `getText()` | 获取文本内容 |
| `setTextColor({r, g, b, a})` | 设置文字颜色 |
| `setFont(font_key, size)` | 设置字体 |
| `setFontSize(size)` | 设置字号 |
| `setHAlign(align)` | 设置水平对齐 |
| `setVAlign(align)` | 设置垂直对齐 |
| `selectAll()` | 全选文本 |
| `copy()` | 复制选区到剪贴板 |
| `paste()` | 从剪贴板粘贴 |
| `undo()` / `redo()` | 撤销/重做 |
| `getMinimumSize()` | 最小尺寸：高度 = 行高 + padding，宽度 = 0 |

## 示例

```lua
-- 多行文本输入
local input = TextInput({
    w = 300,
    h = 120,
    hint = "Type something...",
    bg = Panel({ bg_color = {0.1, 0.1, 0.12, 1}, rounding_radius = 4 }),
})

-- 单行搜索框
local search = TextInput({
    w = 200,
    h = 32,
    single_line = true,
    hint = "Search...",
    on_submit = function()
        print("Search:", search:getText())
    end,
})
```

## 最佳实践

- **推荐**：单行搜索/输入场景使用 `single_line = true` + `on_submit`。
- **推荐**：通过 `bg` 参数设置背景 Panel，框架自动处理焦点边框切换。
- **不推荐**：在 `height_adaptive = true` 的同时设置 `v_size_flags = FILL`——两者冲突。
