return function(use, BPUI)
    local C = use("core")
    local Icons = use("icons")
    local new, txt, corner = C.new, C.txt, C.corner

    return function(win, page, o)
        o = o or {}
        local source = o.Icons or Icons.names
        local gridH = o.Height or 200
        local flat = page:GetAttribute("bpuiFlat") == true
        local card = new("Frame", { Parent = page, Size = UDim2.new(1, 0, 0, (o.Title and 28 or 6) + 38 + gridH + 12),
            BackgroundColor3 = flat and win.Theme.Hover or win.Theme.Panel, BackgroundTransparency = flat and 1 or 0,
            BorderSizePixel = 0, LayoutOrder = C.nextOrd(page), ClipsDescendants = true })
        corner(card, 8)
        win:paint(card, "BackgroundColor3", flat and "Hover" or "Panel")
        if not flat then
            local cs = C.fluentStroke(card, win.Theme.Stroke, 0)
            win:paint(cs, "Color", "Stroke")
        end

        local y = 10
        if o.Title then
            local tl = txt(card, o.Title, 14, win.Theme.Text, Enum.Font.GothamBold, { Size = UDim2.new(1, -28, 0, 20), Position = UDim2.fromOffset(14, 8) })
            win:paint(tl, "TextColor3", "Text")
            y = 32
        end

        local sb = new("Frame", { Parent = card, BackgroundColor3 = win.Theme.Panel2, Size = UDim2.new(1, -28, 0, 30), Position = UDim2.fromOffset(14, y) })
        corner(sb, 6)
        local sbs = C.stroke(sb, win.Theme.Stroke, 1, 0.5)
        win:paint(sb, "BackgroundColor3", "Panel2")
        Icons.make(sb, "search", { size = UDim2.fromOffset(16, 16), anchor = Vector2.new(0, 0.5), position = UDim2.new(0, 10, 0.5, 0), color = win.Theme.Dim })
        local tb = new("TextBox", { Parent = sb, BackgroundTransparency = 1, Size = UDim2.new(1, -36, 1, 0), Position = UDim2.fromOffset(32, 0),
            Font = C.uifont(Enum.Font.GothamMedium), TextSize = 13, TextColor3 = win.Theme.Text, PlaceholderText = o.Placeholder or "Search icons...",
            PlaceholderColor3 = win.Theme.Dim, Text = "", ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left })
        win:paint(tb, "TextColor3", "Text")
        tb.Focused:Connect(function() C.tw(sbs, 0.15, { Color = win.Theme.Accent, Transparency = 0 }) end)
        tb.FocusLost:Connect(function() C.tw(sbs, 0.15, { Color = win.Theme.Stroke, Transparency = 0.5 }) end)

        local scroll = new("ScrollingFrame", { Parent = card, BackgroundTransparency = 1, Position = UDim2.fromOffset(10, y + 38),
            Size = UDim2.new(1, -16, 0, gridH), CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollBarThickness = 3, ScrollBarImageColor3 = win.Theme.Accent, ScrollBarImageTransparency = 0.4, BorderSizePixel = 0 })
        win:paint(scroll, "ScrollBarImageColor3", "Accent")
        local grid = new("UIGridLayout", { Parent = scroll, CellSize = UDim2.fromOffset(72, 62), CellPadding = UDim2.fromOffset(6, 6),
            SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Left })
        C.pad(scroll, 4, 4, 4, 6)

        local function makeTile(name)
            local tile = new("TextButton", { Parent = scroll, BackgroundColor3 = win.Theme.Hover, BackgroundTransparency = 1,
                Text = "", AutoButtonColor = false })
            corner(tile, 7)
            local ico = Icons.make(tile, name, { size = UDim2.fromOffset(24, 24), anchor = Vector2.new(0.5, 0),
                position = UDim2.new(0.5, 0, 0, 9), color = win.Theme.Sub })
            local lbl = txt(tile, name, 10, win.Theme.Dim, Enum.Font.Gotham,
                { Size = UDim2.new(1, -6, 0, 14), Position = UDim2.new(0, 3, 1, -16), TextXAlignment = Enum.TextXAlignment.Center, TextTruncate = Enum.TextTruncate.AtEnd })
            C.hoverable(tile, function()
                C.tw(tile, 0.1, { BackgroundTransparency = 0.4 })
                Icons.tint(ico, "vector", win.Theme.Accent) lbl.TextColor3 = win.Theme.Text
            end, function()
                C.tw(tile, 0.12, { BackgroundTransparency = 1 })
                Icons.tint(ico, "vector", win.Theme.Sub) lbl.TextColor3 = win.Theme.Dim
            end)
            C.press(tile, { radius = 7 })
            tile.MouseButton1Click:Connect(function()
                if o.Copy ~= false then pcall(function() (setclipboard or set_clipboard)(name) end) end
                pcall(o.OnSelect, name)
            end)
        end

        local function fill(q)
            for _, ch in ipairs(scroll:GetChildren()) do if ch:IsA("TextButton") then ch:Destroy() end end
            q = (q or ""):lower()
            for _, name in ipairs(source) do
                if q == "" or tostring(name):lower():find(q, 1, true) then makeTile(name) end
            end
        end
        tb:GetPropertyChangedSignal("Text"):Connect(function() fill(tb.Text) end)
        fill("")
        win:onTheme(function() fill(tb.Text) end)

        local obj = { kind = "icongallery", Instance = card }
        function obj:Destroy() card:Destroy() end
        return obj
    end
end
