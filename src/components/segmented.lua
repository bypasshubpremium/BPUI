return function(use, BPUI)
    local C = use("core")
    local new, txt, corner, pad, list, tw, hoverable, mkCard, titleBlock = C.new, C.txt, C.corner, C.pad, C.list, C.tw, C.hoverable, C.mkCard, C.titleBlock
    return function(win, page, o)
        local card = mkCard(win, page, o.Desc and 54 or 44, true)
        titleBlock(win, card, o.Title or "Segmented", o.Desc, 240)
        local opts = o.Options or o.Items or {}
        local sel = o.Default
        local has = false
        for _, v in ipairs(opts) do if v == sel then has = true break end end
        if not has then sel = opts[1] end
        local box = new("Frame", { Parent = card, BackgroundColor3 = win.Theme.Bg2, AutomaticSize = Enum.AutomaticSize.X,
            AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0), Size = UDim2.fromOffset(0, 30) })
        corner(box, 7)
        win:paint(box, "BackgroundColor3", "Bg2")
        pad(box, 3, 3, 3, 3)
        list(box, 4, Enum.FillDirection.Horizontal)
        C.bindRight(card, box, { rightInset = 240, normalHeight = o.Desc and 54 or 44, compactHeight = o.Desc and 92 or 82, minWidth = 520, controlHeight = 30 })
        local pills = {}
        local function skin(v, p)
            local on = v == sel
            tw(p.btn, 0.16, { BackgroundColor3 = on and win.Theme.Accent or win.Theme.Hover, BackgroundTransparency = on and 0 or 1 })
            tw(p.lbl, 0.16, { TextColor3 = on and win.Theme.OnAccent or win.Theme.Sub })
        end
        local function render() for v, p in pairs(pills) do skin(v, p) end end
        local function pick(v, fire)
            sel = v render()
            if fire then pcall(o.Callback, v) win:save() end
        end
        for _, v in ipairs(opts) do
            local on = v == sel
            local btn = new("TextButton", { Parent = box, Text = "", AutoButtonColor = false, AutomaticSize = Enum.AutomaticSize.X,
                Size = UDim2.fromOffset(0, 24), BackgroundColor3 = on and win.Theme.Accent or win.Theme.Hover, BackgroundTransparency = on and 0 or 1 })
            corner(btn, 6)
            pad(btn, 12, 12, 0, 0)
            local lbl = txt(btn, tostring(v), 13, on and win.Theme.OnAccent or win.Theme.Sub, Enum.Font.GothamMedium,
                { Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, TextXAlignment = Enum.TextXAlignment.Center })
            local p = { btn = btn, lbl = lbl }
            pills[v] = p
            hoverable(btn, function() if v ~= sel then tw(btn, 0.1, { BackgroundTransparency = 0.5 }) end end,
                function() if v ~= sel then tw(btn, 0.1, { BackgroundTransparency = 1 }) end end)
            btn.MouseButton1Click:Connect(function() if v ~= sel then pick(v, true) end end)
        end
        win:onTheme(function() box.BackgroundColor3 = win.Theme.Bg2 for v, p in pairs(pills) do
            local on = v == sel
            p.btn.BackgroundColor3 = on and win.Theme.Accent or win.Theme.Hover
            p.btn.BackgroundTransparency = on and 0 or 1
            p.lbl.TextColor3 = on and win.Theme.OnAccent or win.Theme.Sub
        end end)
        local obj = { kind = "segmented" }
        function obj:Set(v, fire)
            if pills[v] == nil then return end
            sel = v render()
            if fire ~= false then pcall(o.Callback, v) win:save() end
        end
        function obj:Get() return sel end
        obj.Instance = card
        function obj:Destroy() card:Destroy() end
        return obj
    end
end
