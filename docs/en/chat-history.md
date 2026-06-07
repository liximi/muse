# ChatBubble (Advanced Component)

A chat bubble component for displaying individual messages in a chat history. Supports left/right alignment and custom styling.

**Inheritance chain:** `Widget` → `ChatBubble`

## Constructor Parameters (datas)

```lua
{
    chatter_id = string,          -- speaker ID
    text = string,                -- message text
    bg_color = {r, g, b, a},     -- background color
    rounding_radius = number,     -- corner radius
    max_width = number,           -- maximum width (pixels)
    alignment = "left" | "right", -- alignment, default "left"
    font_key = string,            -- font key
    font_size = number,           -- font size
    text_color = {r, g, b, a},    -- text color
    text_padding = {l, r, t, b},  -- text padding
}
```

## Public Methods

| Method | Description |
|--------|-------------|
| `setText(text)` | Set message text (auto-calculates bubble size) |
| `getText()` | Get message text |
| `updateStyle(style)` | Update bubble style and re-layout |

---

# ChatHistory (Advanced Component)

A chat history list component that manages the display, appending, and style updating of ChatBubbles.

**Inheritance chain:** `Widget` → `ChatHistory`

## Constructor Parameters (datas)

```lua
{
    space = number,               -- spacing between bubbles (pixels)
}
```

## Public Methods

| Method | Description |
|--------|-------------|
| `setChatHistory(history)` | Set complete chat history: `{{"chatter_id", "content"}, ...}` |
| `appendHistory(history)` | Append records (supports single `{"id", "text"}` or array) |
| `setChatBubbleStyle(chatter_id, style)` | Set bubble style for a given chatter_id |
| `createChatBubbleStyle(bg_color, rounding_radius, max_width, font_key, font_size, text_color, text_padding, alignment)` | Create a bubble style table |
| `refresh()` | Completely rebuild the chat list |

## Architecture

- Internally uses `ListContainer` (vertical list) + `ScrollContainer` for scrolling
- Default max bubble width = container width × 0.8

## Example

```lua
local chat = ChatHistory({
    anchor = {0, 0, 1, 1},
    space = 6,
})

-- Set styles first, then set history
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
