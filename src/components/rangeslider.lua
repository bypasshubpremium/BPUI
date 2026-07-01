return function(use, BPUI)
    local C = use("core")
    local new, txt, corner, mkCard, titleBlock = C.new, C.txt, C.corner, C.mkCard, C.titleBlock
    local Maid, UIS = C.Maid, C.UIS

    local function fmt(v, suffix)
        suffix = suffix or ""
        if math.abs(v - math.floor(v + 0.5)) < 1e-6 then return tostring(math.floor(v + 0.5)) .. suffix end
        return string.format("%g", v) .. suffix
    end

    return function(win, page, o)
        local cm = Maid.new() win.maid:give(function() cm:clean() end)
        local card = mkCard(win, page, o.Desc and 72 or 56, true)
        titleBlock(win, card, o.Title or "Range", o.Desc, 130)
        local mn, mx = o.Min or 0, o.Max or 100
        local step = o.Step or 1 if step == 0 then step = 1 end
        local rng = (mx - mn) if rng == 0 then rng = 1 end
        local suffix = o.Suffix or ""
        local function snap(v)
            v = math.clamp(v, mn, mx)
            v = mn + math.floor((v - mn) / step + 0.5) * step
            return math.clamp(v, mn, mx)
        end
        local lo = snap(o.DefaultMin or mn)
        local hi = snap(o.DefaultMax or mx)
        if lo > hi then lo, hi = hi, lo end

        local yTop = o.Desc and 26 or 8
        local valLbl = txt(card, "", 13, win.Theme.Accent, C.MONO,
            { Size = UDim2.fromOffset(120, 18), Position = UDim2.new(1, -134, 0, yTop), TextXAlignment = Enum.TextXAlignment.Right })
        win:paint(valLbl, "TextColor3", "Accent")

        local track = new("Frame", { Parent = card, Size = UDim2.new(1, -28, 0, 6), Position = UDim2.new(0, 14, 1, -16), BackgroundColor3 = win.Theme.Panel2 })
        corner(track, 3)
        win:paint(track, "BackgroundColor3", "Panel2")
        local fill = new("Frame", { Parent = track, BackgroundColor3 = win.Theme.Accent })
        corner(fill, 3)
        C.gloss(fill, 0.85)
        win:paint(fill, "BackgroundColor3", "Accent")

        local function mkKnob()
            local k = new("Frame", { Parent = track, Size = UDim2.fromOffset(16, 16), AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255), ZIndex = 3 })
            corner(k, 8)
            win:paint(C.stroke(k, win.Theme.Stroke, 1, 0.4), "Color", "Stroke")
            local d = new("Frame", { Parent = k, Size = UDim2.fromOffset(8, 8), AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0.5, 0.5), BackgroundColor3 = win.Theme.Accent, ZIndex = 4 })
            corner(d, 4)
            win:paint(d, "BackgroundColor3", "Accent")
            return k, d
        end
        local loK, loD = mkKnob()
        local hiK, hiD = mkKnob()
        C.hoverable(card, function() C.tw(loD, 0.12, { Size = UDim2.fromOffset(10, 10) }) C.tw(hiD, 0.12, { Size = UDim2.fromOffset(10, 10) }) end,
            function() C.tw(loD, 0.12, { Size = UDim2.fromOffset(8, 8) }) C.tw(hiD, 0.12, { Size = UDim2.fromOffset(8, 8) }) end)

        local obj = { kind = "range" }
        local function render(fire)
            local a, b = (lo - mn) / rng, (hi - mn) / rng
            fill.Position = UDim2.new(a, 0, 0, 0)
            fill.Size = UDim2.new(b - a, 0, 1, 0)
            loK.Position = UDim2.new(a, 0, 0.5, 0)
            hiK.Position = UDim2.new(b, 0, 0.5, 0)
            valLbl.Text = fmt(lo, suffix) .. " – " .. fmt(hi, suffix)
            if fire then pcall(o.Callback, lo, hi) end
        end
        render(false)

        local dragging = nil
        local hit = new("TextButton", { Parent = card, BackgroundTransparency = 1, Text = "", AutoButtonColor = false,
            Size = UDim2.new(1, 0, 0, 24), Position = UDim2.new(0, 0, 1, -23) })
        local function fracAt(px)
            if track.AbsoluteSize.X <= 0 then return 0 end
            return math.clamp((px - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        end
        local function moveTo(px)
            local f = fracAt(px)
            local v = snap(mn + f * rng)
            if dragging == "lo" then lo = math.min(v, hi)
            elseif dragging == "hi" then hi = math.max(v, lo) end
            render(true)
        end
        hit.InputBegan:Connect(function(i)
            if not C.isPress(i) then return end
            local f = fracAt(i.Position.X)
            local la, ha = (lo - mn) / rng, (hi - mn) / rng
            if math.abs(f - la) < math.abs(f - ha) then dragging = "lo"
            elseif math.abs(f - la) > math.abs(f - ha) then dragging = "hi"
            else dragging = (f >= ha) and "hi" or "lo" end
            moveTo(i.Position.X)
        end)
        cm:give(UIS.InputChanged:Connect(function(i) if dragging and C.isMove(i) then moveTo(i.Position.X) end end))
        cm:give(UIS.InputEnded:Connect(function(i) if C.isPress(i) and dragging then dragging = nil win:save() end end))

        function obj:Set(a, b, c)
            local nlo, nhi, fire
            if type(a) == "table" then nlo = a.Min or a[1]; nhi = a.Max or a[2]; fire = b
            else nlo = a; nhi = b; fire = c end
            lo = snap(nlo or lo) hi = snap(nhi or hi)
            if lo > hi then lo, hi = hi, lo end
            render(fire ~= false)
            if fire ~= false then win:save() end
        end
        function obj:Get() return { Min = lo, Max = hi } end
        obj.Instance = card
        function obj:Destroy() cm:clean() card:Destroy() end
        return obj
    end
end
