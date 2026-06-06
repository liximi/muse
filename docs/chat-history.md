# ChatBubble（高级组件）

聊天气泡组件，用于聊天历史中的单条消息显示。支持左/右对齐和自定义样式。

**继承链：** `Widget` → `ChatBubble`

## 构造参数（datas）

```lua
{
    chatter_id = string,          -- 发言者 ID
    text = string,                -- 消息文本
    bg_color = {r, g, b, a},     -- 背景色
    rounding_radius = number,     -- 圆角半径
    max_width = number,           -- 最大宽度（像素）
    alignment = "left" | "right", -- 对齐方式，默认 "left"
    font_key = string,            -- 字体 key
    font_size = number,           -- 字号
    text_color = {r, g, b, a},    -- 文本颜色
    text_padding = {l, r, t, b},  -- 文本内边距
}
```

## 公有方法

| 方法 | 说明 |
|------|------|
| `setText(text)` | 设置消息文本（自动计算气泡尺寸） |
| `getText()` | 获取消息文本 |
| `updateStyle(style)` | 更新气泡样式并重新布局 |

---

# ChatHistory（高级组件）

聊天历史列表组件，管理 ChatBubble 的显示、追加和样式更新。

**继承链：** `Widget` → `ChatHistory`

## 构造参数（datas）

```lua
{
    space = number,               -- 气泡间隔（像素）
}
```

## 公有方法

| 方法 | 说明 |
|------|------|
| `setChatHistory(history)` | 设置完整聊天记录：`{{"chatter_id", "content"}, ...}` |
| `appendHistory(history)` | 追加记录（支持单条 `{"id", "text"}` 或数组） |
| `setChatBubbleStyle(chatter_id, style)` | 为指定 chatter_id 设置气泡样式 |
| `createChatBubbleStyle(bg_color, rounding_radius, max_width, font_key, font_size, text_color, text_padding, alignment)` | 创建气泡样式表 |
| `refresh()` | 完全重建聊天列表 |

## 架构

- 内部使用 `ListContainer`（垂直列表）+ `ScrollContainer` 实现滚动
- 气泡最大宽度默认 = 容器宽度 × 0.8

## 示例

```lua
local chat = ChatHistory({
    anchor = {0, 0, 1, 1},
    space = 6,
})

-- 先设置样式，再设置历史
chat:setChatBubbleStyle("user", chat:createChatBubbleStyle(
    Utils.RGB(60, 100, 180), 8, nil, "default", 14,
    Utils.UI_COLORS.WHITE, {8, 8, 6, 6}, "right"
))
chat:setChatBubbleStyle("bot", chat:createChatBubbleStyle(
    Utils.RGB(50, 50, 60), 8, nil, "default", 14,
    Utils.UI_COLORS.PRIMARY_TEXT, {8, 8, 6, 6}, "left"
))

chat:setChatHistory({
    {"bot", "Hello! How can I help you?"},
    {"user", "Hi, I have a question."},
})
```
