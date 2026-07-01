return function(use, BPUI)
    local C = use("core")
    local Icons = use("icons")
    local new, txt, corner = C.new, C.txt, C.corner

    return function(win, page, o)
        o = o or {}
        local card = new("Frame", { Parent = page, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1, BorderSizePixel = 0, LayoutOrder = C.nextOrd(page), ClipsDescendants = true })
        corner(card, 8)
        C.list(card, 0)

        local hasD = o.Desc ~= nil and o.Desc ~= ""
        local header = new("TextButton", { Parent = card, Size = UDim2.new(1, 0, 0, hasD and 54 or 44), BackgroundColor3 = win.Theme.Hover, BackgroundTransparency = 1,
            Text = "", AutoButtonColor = false, LayoutOrder = 0 })
        corner(header, 8)
        win:paint(header, "BackgroundColor3", "Hover")
        local tx = 16
        if o.Icon then
            local ic, ik = Icons.make(header, o.Icon, { size = UDim2.fromOffset(20, 20), anchor = Vector2.new(0, 0.5),
                position = UDim2.new(0, 16, 0.5, 0), color = win.Theme.Accent, textSize = 16 })
            win:onTheme(function() Icons.tint(ic, ik, win.Theme.Accent) end)
            tx = 46
        end
        local tl = txt(header, o.Title or "Section", 14, win.Theme.Text, Enum.Font.GothamBold,
            { Size = UDim2.new(1, -(tx + 44), 0, hasD and 18 or 44), Position = UDim2.fromOffset(tx, hasD and 9 or 0),
                TextYAlignment = hasD and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center, TextTruncate = Enum.TextTruncate.AtEnd })
        win:paint(tl, "TextColor3", "Text")
        if hasD then
            local dl = txt(header, o.Desc, 12, win.Theme.Sub, Enum.Font.Gotham,
                { Size = UDim2.new(1, -(tx + 44), 0, 16), Position = UDim2.fromOffset(tx, 29), TextTruncate = Enum.TextTruncate.AtEnd })
            win:paint(dl, "TextColor3", "Sub")
        end
        local chev = Icons.make(header, "chevrondown", { size = UDim2.fromOffset(18, 18), anchor = Vector2.new(0, 0.5),
            position = UDim2.new(1, -32, 0.5, 0), color = win.Theme.Sub })
        win:onTheme(function() Icons.tint(chev, "vector", win.Theme.Sub) end)
        C.press(header, { radius = 8 })
        C.hoverable(header, function() C.tw(header, 0.12, { BackgroundTransparency = 0.82 }) Icons.tint(chev, "vector", win.Theme.Text) end,
            function() C.tw(header, 0.14, { BackgroundTransparency = 1 }) Icons.tint(chev, "vector", win.Theme.Sub) end)

        local body = new("Frame", { Parent = card, Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1, ClipsDescendants = true, LayoutOrder = 1 })
        local inner = new("Frame", { Parent = body, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1 })
        inner:SetAttribute("bpuiFlat", true)
        C.pad(inner, 8, 8, 2, 8)
        local ll = C.list(inner, 3)

        local open = o.Open and true or false
        local function contentH() return ll.AbsoluteContentSize.Y + 10 end
        local function refresh(animate)
            local target = open and contentH() or 0
            if animate then
                C.tw(body, 0.24, { Size = UDim2.new(1, 0, 0, target) })
                C.tw(chev, 0.22, { Rotation = open and 180 or 0 })
            else
                body.Size = UDim2.new(1, 0, 0, target)
                chev.Rotation = open and 180 or 0
            end
        end
        ll:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            if open then body.Size = UDim2.new(1, 0, 0, contentH()) end
        end)
        header.MouseButton1Click:Connect(function() open = not open refresh(true) end)
        task.defer(function() refresh(false) end)

        local obj = { kind = "accordion", content = inner, Instance = card }
        obj.Open = function() if not open then open = true refresh(true) end end
        obj.Close = function() if open then open = false refresh(true) end end
        obj.Toggle = function() open = not open refresh(true) end
        obj.IsOpen = function() return open end
        obj.Set = function(_, s) tl.Text = tostring(s) end
        obj.Destroy = function() card:Destroy() end
        return obj
    end
end
