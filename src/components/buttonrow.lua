return function(use, BPUI)
    local C = use("core")
    local Icons = use("icons")
    local new, txt, corner, stroke, list, mkCard = C.new, C.txt, C.corner, C.stroke, C.list, C.mkCard
    return function(win, page, o)
        local hasH = o.Title ~= nil and o.Title ~= ""
        local card = mkCard(win, page, hasH and 62 or 44, true)
        if hasH then
            local h = txt(card, o.Title, 12, win.Theme.Sub, Enum.Font.GothamMedium,
                { Size = UDim2.new(1, -32, 0, 16), Position = UDim2.fromOffset(16, 9) })
            win:paint(h, "TextColor3", "Sub")
        end
        local holder = new("Frame", { Parent = card, BackgroundTransparency = 1, Size = UDim2.new(1, -32, 0, 30),
            AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 16, 1, -8) })
        local ll = list(holder, 8, Enum.FillDirection.Horizontal)
        local items = o.Items or {}
        local n = math.max(1, #items)
        local btns = {}
        for i, item in ipairs(items) do
            local v = item.Variant or "default"
            local bg = (v == "primary" and win.Theme.Accent) or (v == "danger" and win.Theme.Bad) or win.Theme.Hover
            local tc = (v == "primary" and win.Theme.OnAccent) or (v == "danger" and Color3.fromRGB(255, 255, 255)) or win.Theme.Text
            local btn = new("TextButton", { Parent = holder, BackgroundColor3 = bg, Text = "", AutoButtonColor = false,
                Size = UDim2.new(1 / n, -7, 1, 0), LayoutOrder = i, ClipsDescendants = true })
            corner(btn, 6)
            if v ~= "default" then C.gloss(btn, 0.86) end
            pcall(function() new("UIFlexItem", { Parent = btn, FlexMode = Enum.UIFlexMode.Fill }) end)
            local lbl = txt(btn, item.Title or "Button", 13, tc, Enum.Font.GothamBold,
                { Size = UDim2.new(1, 0, 1, 0), TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center, TextTruncate = Enum.TextTruncate.AtEnd })
            local ic, ikind
            if item.Icon then
                ic, ikind = Icons.make(btn, item.Icon, { size = UDim2.fromOffset(16, 16), anchor = Vector2.new(0, 0.5),
                    position = UDim2.new(0, 10, 0.5, 0), color = tc, textSize = 14 })
                lbl.TextXAlignment = Enum.TextXAlignment.Left
                lbl.Position = UDim2.fromOffset(32, 0)
                lbl.Size = UDim2.new(1, -40, 1, 0)
            end
            if v == "default" then
                local s = C.fluentStroke(btn, win.Theme.Stroke, 0.05)
                win:onTheme(function()
                    btn.BackgroundColor3 = win.Theme.Hover s.Color = win.Theme.Stroke
                    lbl.TextColor3 = win.Theme.Text
                    if ic then Icons.tint(ic, ikind, win.Theme.Text) end
                end)
            else
                win:onTheme(function()
                    btn.BackgroundColor3 = (v == "primary" and win.Theme.Accent) or win.Theme.Bad
                end)
            end
            C.ripple(btn, Color3.fromRGB(255, 255, 255))
            C.press(btn, { radius = 6 })
            C.hoverable(btn, function() C.tw(btn, 0.12, { BackgroundTransparency = 0.12 }) end,
                function() C.tw(btn, 0.12, { BackgroundTransparency = 0 }) end)
            btn.MouseButton1Click:Connect(function() pcall(item.Callback) end)
            btns[#btns + 1] = btn
        end
        local function relayout()
            local stacked = card.AbsoluteSize.X > 0 and card.AbsoluteSize.X < 420 and #btns > 2
            ll.FillDirection = stacked and Enum.FillDirection.Vertical or Enum.FillDirection.Horizontal
            local rowH = stacked and (#btns * 34 + math.max(0, #btns - 1) * 8) or 30
            card.Size = stacked and UDim2.new(1, 0, 0, (hasH and 32 or 8) + rowH + 16) or UDim2.new(1, 0, 0, hasH and 62 or 44)
            holder.Size = UDim2.new(1, -32, 0, rowH)
            for _, btn in ipairs(btns) do
                btn.Size = stacked and UDim2.new(1, 0, 0, 34) or UDim2.new(1 / n, -7, 1, 0)
            end
        end
        local rcn = card:GetPropertyChangedSignal("AbsoluteSize"):Connect(relayout)
        card.AncestryChanged:Connect(function(_, parent) if not parent then pcall(function() rcn:Disconnect() end) end end)
        task.defer(relayout)
        local obj = { kind = "buttonrow" }
        obj.Instance = card
        function obj:Destroy() card:Destroy() end
        return obj
    end
end
