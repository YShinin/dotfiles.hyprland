--- @since 25.5.31

local DEFAULT_OPTIONS = {
    -- Can't reference Header.RIGHT etc. here (it hangs) so parent and align are strings
    -- 2000 puts it to the right of the indicator, and leaves some room between
    position = { parent = "Header", align = "RIGHT", order = 2000 },
    format = "both",
    bar = true,
    warning_threshold = 90,
    -- Используем безопасный доступ к th, если вдруг тема не загружена или ключей нет
    style_label = (th and th.status and th.status.progress_label) or {},
    style_normal = (th and th.status and th.status.progress_normal) or {},
    style_warning = (th and th.status and th.status.progress_error) or {}
}

---Deep copy and merge two tables
local function merge(into, from)
    into = into or {}
    from = from or {}
    local result = {}
    for k, v in pairs(into) do
        if type(v) == "table" then result[k] = merge({}, v) else result[k] = v end
    end
    for k, v in pairs(from) do
        if type(v) == "table" then result[k] = merge(result[k], v) else result[k] = v end
    end
    return result
end

---Merge label and bar styles safely
local function build_styles(style_label, style_bar)
    -- Защита от nil
    style_label = style_label or {}
    style_bar = style_bar or {}

    -- 1. Создаем стиль для ПРАВОЙ части (пустое место)
    local style_right = ui.Style()
    
    -- Вычисляем цвета
    local right_fg = style_label.fg or style_bar.fg
    local right_bg = style_bar.bg

    -- ИСПРАВЛЕНИЕ: Используем pcall, чтобы не крашить Yazi, если цвет невалиден
    if right_fg then pcall(function() style_right:fg(right_fg) end) end
    if right_bg then pcall(function() style_right:bg(right_bg) end) end

    -- Безопасное применение стилей текста
    if style_label.bold then pcall(function() style_right:bold() end) end
    if style_label.italic then pcall(function() style_right:italic() end) end

    -- 2. Создаем стиль для ЛЕВОЙ части (заполненное место)
    local style_left = ui.Style():patch(style_right)

    -- Инверсия или наследование цветов для левой части
    -- Текст слева: цвет метки ИЛИ цвет фона бара (для контраста)
    local left_fg = style_label.fg or style_bar.bg
    -- Фон слева: цвет текста бара (инверсия)
    local left_bg = style_bar.fg

    -- ИСПРАВЛЕНИЕ: Тоже используем pcall для левой части
    if left_fg then pcall(function() style_left:fg(left_fg) end) end
    if left_bg then pcall(function() style_left:bg(left_bg) end) end

    return style_left, style_right
end

---Format text based on options
local function format_text(source, usage, format)
    local text = ""
    if format == "both" then
        text = string.format(" %s: %d%% ", source, usage)
    elseif format == "name" then
        text = string.format(" %s ", source)
    elseif format == "usage" then
        text = string.format(" %d%% ", usage)
    end
    return text
end

---Set new plugin state and redraw
local set_state = ya.sync(function(st, source, usage, text_left, text_right)
    st.source = source
    st.usage = usage
    st.text_left = text_left
    st.text_right = text_right
    local render = ui.render or ya.render
    render()
end)

---Get plugin state needed by entry
local get_state = ya.sync(function(st)
    return {
        format = st.format,
        bar = st.bar,
        source = st.source,
        usage = st.usage
    }
end)

-- Called from init.lua
local function setup(st, opts)
    opts = merge(DEFAULT_OPTIONS, opts)

    -- Safe checks
    opts.style_label = opts.style_label or {}
    if opts.style_label.fg == "" then opts.style_label.fg = nil end
    if opts.warning_threshold and opts.warning_threshold < 0 then opts.warning_threshold = nil end

    -- Parent handling
    if opts.position.parent == "Header" then
        opts.position.parent = Header
    elseif opts.position.parent == "Status" then
        opts.position.parent = Status
    else
        opts.position.parent = nil
    end

    st.format = opts.format
    st.bar = opts.bar
    st.warning_threshold = opts.warning_threshold

    -- Build styles safely
    local style_normal_left, style_normal_right = build_styles(opts.style_label, opts.style_normal)
    local style_warning_left, style_warning_right = build_styles(opts.style_label, opts.style_warning)

    -- Add component
    if opts.position.parent then
        opts.position.parent:children_add(function(self)
            if not st.usage then return end

            if not st.warning_threshold or st.usage < st.warning_threshold then
                return ui.Line {
                    ui.Span(st.text_left or ""):style(style_normal_left),
                    ui.Span(st.text_right or ""):style(style_normal_right)
                }
            else
                return ui.Line {
                    ui.Span(st.text_left or ""):style(style_warning_left),
                    ui.Span(st.text_right or ""):style(style_warning_right)
                }
            end
        end, opts.position.order, opts.position.parent[opts.position.align])
    end

    local function callback()
        ya.emit("plugin", {
            st._id,
            ya.quote(tostring(cx.active.current.cwd), true)
        })
    end

    ps.sub("cd", callback)
    ps.sub("tab", callback)
    ps.sub("delete", callback)
end

local function entry(_, job)
    local cwd = job.args[1]
    local output = Command("df"):arg({ "--output=source,pcent", tostring(cwd) }):output()

    if not output.status.success then
        set_state("", nil, "", "")
        return
    end

    local source, usage = output.stdout:match(".*%s(%S+)%s+(%S+)")

    if usage == "-" then
        set_state("", nil, "", "")
        return
    end

    usage = tonumber(string.sub(usage, 1, #usage - 1))
    local st = get_state()

    if source == st.source and usage == st.usage then return end

    local text_left = ""
    local text_right = format_text(source, usage, st.format)

    if st.bar then
        local text_len = string.len(text_right)
        local bar_len = usage < 100 and math.ceil((text_len - 1) / 100 * usage) or text_len
        text_left = string.sub(text_right, 1, bar_len)
        text_right = string.sub(text_right, bar_len + 1, text_len)
    end

    set_state(source, usage, text_left, text_right)
end

return { setup = setup, entry = entry }
