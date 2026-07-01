return function(use, BPUI)
    local C = use("core")
    local new, txt, corner, mkCard, titleBlock = C.new, C.txt, C.corner, C.mkCard, C.titleBlock

    local function fmtNum(v, suffix)
        suffix = suffix or ""
        if math.abs(v - math.floor(v + 0.5)) < 1e-6 then return tostring(math.floor(v + 0.5)) .. suffix end
        return string.format("%g", v) .. suffix
    end

    return function(win, page, o)
        local card = mkCard(win, page, o.Desc and 54 or 44, true)
        titleBlock(win, card, o.Title or "Stepper", o.Desc, 150)
        local mn, mx = o.Min or 0, o.Max or 100
        local step = o.Step or 1 if step == 0 then step = 1 end
        local suffix = o.Suffix or ""
        local function snap(v)
            v = math.clamp(v, mn, mx)
            v = mn + math.floor((v - mn) / step + 0.5) * step
            return math.clamp(v, mn, mx)
        end
        local val = snap(o.Default or mn)
        local group = new("Frame", { Parent = card, BackgroundColor3 = win.Theme.Bg2, AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(1, -140, 0.5, 0), Size = UDim2.fromOffset(126, 30) })
        corner(group, 6)
        win:paint(group, "BackgroundColor3", "Bg2")
        local minus = new("TextButton", { Parent = group, BackgroundTransparency = 1, Size = UDim2.fromOffset(28, 30),
            Position = UDim2.new(0, 0, 0, 0), Text = "−", TextColor3 = win.Theme.Sub, Font = Enum.Font.GothamBold, TextSize = 18, AutoButtonColor = false })
        win:paint(minus, "TextColor3", "Sub")
        local plus = new("TextButton", { Parent = group, BackgroundTransparency = 1, Size = UDim2.fromOffset(28, 30),
            Position = UDim2.new(1, -28, 0, 0), Text = "+", TextColor3 = win.Theme.Sub, Font = Enum.Font.GothamBold, TextSize = 18, AutoButtonColor = false })
        win:paint(plus, "TextColor3", "Sub")
        local valLbl = txt(group, fmtNum(val, suffix), 13, win.Theme.Text, C.MONO,
            { Size = UDim2.new(1, -56, 1, 0), Position = UDim2.new(0, 28, 0, 0), TextXAlignment = Enum.TextXAlignment.Center })
        win:paint(valLbl, "TextColor3", "Text")
        C.bindRight(card, group, { rightInset = 150, normalHeight = o.Desc and 54 or 44, compactHeight = o.Desc and 92 or 82, minWidth = 380, controlHeight = 30, fill = false })
        C.hoverable(minus, function() minus.TextColor3 = win.Theme.Text end, function() minus.TextColor3 = win.Theme.Sub end)
        C.hoverable(plus, function() plus.TextColor3 = win.Theme.Text end, function() plus.TextColor3 = win.Theme.Sub end)
        local obj = { kind = "stepper" }
        local function apply(v, fire)
            val = snap(v)
            valLbl.Text = fmtNum(val, suffix)
            if fire then pcall(o.Callback, val) end
        end
        minus.MouseButton1Click:Connect(function() apply(val - step, true) win:save() end)
        plus.MouseButton1Click:Connect(function() apply(val + step, true) win:save() end)
        function obj:Set(v, fire) apply(v, fire ~= false) if fire ~= false then win:save() end end
        function obj:Get() return val end
        obj.Instance = card
        function obj:Destroy() card:Destroy() end
        return obj
    end
end
