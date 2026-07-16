--------------------------------------------------
-- widget_meta.lua — Widget 元信息（多模块共用）
--
-- LEAF_TYPES: 子节点为内部实现的控件类型。
--   序列化时不递归子节点，编辑器命中检测不穿透，TreeView 不展开。
--------------------------------------------------

return {
    Text       = true,
    Button     = true,
    Image      = true,
    Checkbox   = true,
    TextInput  = true,
    SliderBar  = true,
    ProgressBar = true,
    Dropdown   = true,
    Scroll     = true,
    Spacer     = true,
    RadioButton = true,
    NineSlice  = true,
}
