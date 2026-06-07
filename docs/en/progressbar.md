# ProgressBar

A progress bar component supporting horizontal and vertical orientation. An interactive mode can be enabled to let users drag to adjust progress.

**Inheritance chain:** `Widget` → `ProgressBar`

## Constructor Parameters (datas)

```lua
{
    value = number,               -- current progress, 0~1, default 0
    orientation = string,         -- orientation: "horizontal" (default) | "vertical"
    fill_color = {r, g, b, a},    -- fill color, defaults to theme.progressbar.fill_color
    bg_color = {r, g, b, a},      -- background color, defaults to theme.progressbar.bg_color
    rounding_radius = number,     -- corner radius, default 4

    -- Interactive mode
    interactive = boolean,           -- whether to allow manual adjustment, default false
    thumb_radius = number,           -- thumb dot radius (pixels), default auto-calculated (1.2× half of thin edge, min 5px)
    thumb_color = {r, g, b, a},      -- thumb color, defaults to fill_color
    thumb_outline_color = {r, g, b, a},  -- thumb outline color, default nil (no outline)
    thumb_outline_width = number,    -- thumb outline width, default 2
    on_value_changed = function(value),  -- value change callback (only in interactive mode)
}
```

## Public Methods

| Method | Description |
|--------|-------------|
| `setValue(v)` | Set progress value (0~1, auto-clamped); triggers `on_value_changed` in interactive mode |
| `setProgress(v)` | Alias for `setValue` |
| `getValue()` | Get current progress value |

## Interactive Mode

When `interactive = true`:

- **Click track** — progress jumps directly to the click position
- **Drag thumb** — value follows mouse in real time
- **Mouse hover on thumb** — cursor changes to a hand
- **Thumb appearance** — a circular drag handle is shown at the end of the filled bar, with customizable radius and color
- **Callback notification** — `on_value_changed(value)` is triggered on value changes

## Examples

```lua
-- Static progress bar
local static = ProgressBar({
    value = 0.6,
    anchor = {0, 0, 1, 0},
    h = 12,
})

-- Interactive progress bar (volume control)
local vol = ProgressBar({
    value = 0.8,
    interactive = true,
    anchor = {0, 0, 1, 0},
    h = 14,
    fill_color = Utils.RGB(80, 180, 100),
    thumb_color = Utils.RGB(140, 220, 160),
    thumb_outline_color = Utils.RGB(40, 80, 40),
    on_value_changed = function(val)
        setVolume(val)
    end,
})

-- Vertical interactive progress bar
local v = ProgressBar({
    orientation = "vertical",
    value = 0.5,
    interactive = true,
    anchor = {0, 0, 0, 1},
    w = 20,
    on_value_changed = function(val)
        print("value:", val)
    end,
})

-- Update progress
static:setValue(0.75)
```
