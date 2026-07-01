return function(use, BPUI)
    local C = use("core")
    local new, txt, tw, corner, stroke, mkCard, titleBlock = C.new, C.txt, C.tw, C.corner, C.stroke, C.mkCard, C.titleBlock
    local Maid, UIS = C.Maid, C.UIS

    return function(win, page, o)
        local hasKey = o.Keybind ~= nil
        local card = mkCard(win, page, o.Desc and 54 or 44, true)
        titleBlock(win, card, o.Title or "Toggle", o.Desc, hasKey and 162 or 74)
        local state = o.Default and true or false
        local groupW = hasKey and 136 or 40
        local group = new("Frame", { Parent = card, BackgroundTransparency = 1, AnchorPoint = Vector2.new(0, 0.5),
            Position = hasKey and UDim2.new(1, -150, 0.5, 0) or UDim2.new(1, -54, 0.5, 0),
            Size = UDim2.fromOffset(groupW, 30) })
        local track = new("Frame", { Parent = group, Size = UDim2.fromOffset(40, 21), AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(1, -40, 0.5, 0), BackgroundColor3 = win.Theme.Accent, BackgroundTransparency = state and 0 or 1 })
        corner(track, 11)
        C.gloss(track, 0.86)
        local ts = stroke(track, win.Theme.Sub, 1, state and 1 or 0.3)
        local knob = new("Frame", { Parent = track, Size = UDim2.fromOffset(13, 13), AnchorPoint = Vector2.new(0, 0.5),
            Position = state and UDim2.new(1, -17, 0.5, 0) or UDim2.new(0, 4, 0.5, 0), BackgroundColor3 = state and win.Theme.OnAccent or win.Theme.Sub })
        corner(knob, 7)
        local btn = new("TextButton", { Parent = group, BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(1, -20, 0.5, 0), Size = UDim2.fromOffset(62, 38), Text = "", AutoButtonColor = false })
        C.hoverable(track, function() C.tw(track, 0.12, { BackgroundTransparency = state and 0 or 0.92 }) end,
            function() C.tw(track, 0.12, { BackgroundTransparency = state and 0 or 1 }) end)
        local obj = { kind = "toggle" }
        local cm
        local function render(fire)
            tw(track, 0.16, { BackgroundColor3 = win.Theme.Accent, BackgroundTransparency = state and 0 or 1 })
            tw(knob, 0.16, { Position = state and UDim2.new(1, -17, 0.5, 0) or UDim2.new(0, 4, 0.5, 0), BackgroundColor3 = state and win.Theme.OnAccent or win.Theme.Sub })
            tw(ts, 0.16, { Transparency = state and 1 or 0.3 })
            if fire then pcall(o.Callback, state) end
        end
        win:onTheme(function() track.BackgroundColor3 = win.Theme.Accent ts.Color = win.Theme.Sub knob.BackgroundColor3 = state and win.Theme.OnAccent or win.Theme.Sub end)
        btn.MouseButton1Click:Connect(function() state = not state render(true) win:save() end)
        if hasKey then
            C.bindRight(card, group, { rightInset = 162, normalHeight = o.Desc and 54 or 44, compactHeight = o.Desc and 92 or 82, minWidth = 430, controlHeight = 30 })
            cm = Maid.new() win.maid:give(function() cm:clean() end)
            local kcur = (o.Keybind ~= true and o.Keybind) or "None"
            local kb = new("TextButton", { Parent = group, BackgroundColor3 = win.Theme.Panel2, AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.fromOffset(84, 26), Text = "", AutoButtonColor = false })
            corner(kb, 6)
            win:paint(kb, "BackgroundColor3", "Panel2")
            local kbs = stroke(kb, win.Theme.Stroke, 1, 0.5)
            local klb = txt(kb, tostring(kcur), 12, win.Theme.Sub, Enum.Font.GothamMedium, { Size = UDim2.new(1, 0, 1, 0), TextXAlignment = Enum.TextXAlignment.Center })
            local cap, just = false, false
            win:onTheme(function() if not cap then kbs.Color = win.Theme.Stroke end end)
            kb.MouseButton1Click:Connect(function() cap = true klb.Text = "..." tw(kbs, 0.15, { Color = win.Theme.Accent, Transparency = 0 }) end)
            cm:give(UIS.InputBegan:Connect(function(i, gpe)
                if cap then
                    cap = false just = true
                    tw(kbs, 0.15, { Color = win.Theme.Stroke, Transparency = 0.5 })
                    local nm = C.keyFromInput(i)
                    if i.KeyCode == Enum.KeyCode.Escape or i.KeyCode == Enum.KeyCode.Backspace then nm = "None" end
                    kcur = nm or "None" klb.Text = kcur win:save()
                    task.defer(function() just = false end)
                    return
                end
                if gpe or just or obj._enabled == false then return end
                if C.keyMatches(i, kcur) then state = not state render(true) win:save() end
            end))
            obj.GetKey = function() return kcur end
            obj.SetKey = function(_, k) kcur = k or "None" klb.Text = kcur end
        end
        function obj:Set(v, fire) state = v and true or false render(fire ~= false) if fire ~= false then win:save() end end
        function obj:Get() return state end
        obj.Instance = card
        function obj:Destroy() if cm then cm:clean() end card:Destroy() end
        return obj
    end
end
