return function(use, BPUI)
    local C = use("core")
    local new, txt, corner, stroke, tw, mkCard, titleBlock = C.new, C.txt, C.corner, C.stroke, C.tw, C.mkCard, C.titleBlock

    return function(win, page, o)
        local card = mkCard(win, page, o.Desc and 54 or 44, true)
        titleBlock(win, card, o.Title or "Input", o.Desc, 200)
        local box = new("Frame", { Parent = card, BackgroundColor3 = win.Theme.Panel2, AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(1, -190, 0.5, 0), Size = UDim2.fromOffset(176, 30) })
        corner(box, 6)
        win:paint(box, "BackgroundColor3", "Panel2")
        local bs = stroke(box, win.Theme.Stroke, 1, 0.5)
        local tb = new("TextBox", { Parent = box, BackgroundTransparency = 1, Size = UDim2.new(1, -20, 1, 0),
            Position = UDim2.fromOffset(10, 0), Font = C.uifont(Enum.Font.GothamMedium), TextSize = 13, TextColor3 = win.Theme.Text,
            PlaceholderText = o.Placeholder or "...", PlaceholderColor3 = win.Theme.Dim, Text = o.Default or "",
            TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, TextTruncate = Enum.TextTruncate.AtEnd })
        C.bindRight(card, box, { rightInset = 200, normalHeight = o.Desc and 54 or 44, compactHeight = o.Desc and 92 or 82, minWidth = 430, controlHeight = 30 })
        win:paint(tb, "TextColor3", "Text")
        tb.Focused:Connect(function() tw(bs, 0.15, { Color = win.Theme.Accent, Transparency = 0 }) end)
        tb.FocusLost:Connect(function()
            tw(bs, 0.15, { Color = win.Theme.Stroke, Transparency = 0.5 })
            pcall(o.Callback, tb.Text) win:save()
            if o.Clear then tb.Text = "" end
        end)
        return { kind = "input", Instance = card,
            Set = function(_, s, fire) tb.Text = tostring(s) if fire ~= false then pcall(o.Callback, tb.Text) win:save() end end,
            Get = function() return tb.Text end, Destroy = function() card:Destroy() end }
    end
end
