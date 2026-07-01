return function(use, BPUI)
    local C = use("core")
    local new, txt, corner, mkCard, titleBlock = C.new, C.txt, C.corner, C.mkCard, C.titleBlock
    local Maid, UIS = C.Maid, C.UIS

    local function fmtNum(v, suffix)
        suffix = suffix or ""
        if math.abs(v - math.floor(v + 0.5)) < 1e-6 then return tostring(math.floor(v + 0.5)) .. suffix end
        return string.format("%g", v) .. suffix
    end

    return function(win, page, o)
        local cm = Maid.new() win.maid:give(function() cm:clean() end)
        local card = mkCard(win, page, o.Desc and 72 or 56, true)
        titleBlock(win, card, o.Title or "Slider", o.Desc, 90)
        local mn, mx = o.Min or 0, o.Max or 100
        local step = o.Step or 1 if step == 0 then step = 1 end
        local rng = (mx - mn) if rng == 0 then rng = 1 end
        local val = math.clamp(o.Default or mn, mn, mx)
        local suffix = o.Suffix or ""
        local yTop = o.Desc and 26 or 8
        local valLbl = txt(card, fmtNum(val, suffix), 13, win.Theme.Accent, C.MONO,
            { Size = UDim2.fromOffset(80, 18), Position = UDim2.new(1, -94, 0, yTop), TextXAlignment = Enum.TextXAlignment.Right })
        win:paint(valLbl, "TextColor3", "Accent")
        local track = new("Frame", { Parent = card, Size = UDim2.new(1, -28, 0, 6), Position = UDim2.new(0, 14, 1, -16), BackgroundColor3 = win.Theme.Panel2 })
        corner(track, 3)
        win:paint(track, "BackgroundColor3", "Panel2")
        local fill = new("Frame", { Parent = track, Size = UDim2.fromScale((val - mn) / rng, 1), BackgroundColor3 = win.Theme.Accent })
        corner(fill, 3)
        C.gloss(fill, 0.85)
        win:paint(fill, "BackgroundColor3", "Accent")
        local knob = new("Frame", { Parent = track, Size = UDim2.fromOffset(16, 16), AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new((val - mn) / rng, 0, 0.5, 0), BackgroundColor3 = Color3.fromRGB(255, 255, 255), ZIndex = 3 })
        corner(knob, 8)
        win:paint(C.stroke(knob, win.Theme.Stroke, 1, 0.4), "Color", "Stroke")
        local kdot = new("Frame", { Parent = knob, Size = UDim2.fromOffset(8, 8), AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5), BackgroundColor3 = win.Theme.Accent, ZIndex = 4 })
        corner(kdot, 4)
        win:paint(kdot, "BackgroundColor3", "Accent")
        C.hoverable(card, function() C.tw(kdot, 0.12, { Size = UDim2.fromOffset(10, 10) }) end,
            function() C.tw(kdot, 0.12, { Size = UDim2.fromOffset(8, 8) }) end)
        local obj = { kind = "slider" }
        local function apply(v, fire)
            v = math.clamp(v, mn, mx)
            v = mn + math.floor((v - mn) / step + 0.5) * step
            v = math.clamp(v, mn, mx)
            val = v
            local a = (v - mn) / rng
            fill.Size = UDim2.fromScale(a, 1)
            knob.Position = UDim2.new(a, 0, 0.5, 0)
            valLbl.Text = fmtNum(v, suffix)
            if fire then pcall(o.Callback, v) end
        end
        local dragging = false
        local hit = new("TextButton", { Parent = card, BackgroundTransparency = 1, Text = "", AutoButtonColor = false,
            Size = UDim2.new(1, 0, 0, 22), Position = UDim2.new(0, 0, 1, -22) })
        local function fromX(px)
            if track.AbsoluteSize.X <= 0 then return end
            local a = math.clamp((px - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            apply(mn + a * rng, true)
        end
        hit.InputBegan:Connect(function(i) if C.isPress(i) then dragging = true fromX(i.Position.X) end end)
        cm:give(UIS.InputChanged:Connect(function(i) if dragging and C.isMove(i) then fromX(i.Position.X) end end))
        cm:give(UIS.InputEnded:Connect(function(i) if C.isPress(i) and dragging then dragging = false win:save() end end))
        function obj:Set(v, fire) apply(v, fire ~= false) if fire ~= false then win:save() end end
        function obj:Get() return val end
        obj.Instance = card
        function obj:Destroy() cm:clean() card:Destroy() end
        return obj
    end
end
