return function(use, BPUI)
    local C = use("core")
    local Icons = use("icons")
    local new, txt, tw, corner, mkCard, titleBlock = C.new, C.txt, C.tw, C.corner, C.mkCard, C.titleBlock

    return function(win, page, o)
        local card = mkCard(win, page, o.Desc and 54 or 44)
        local titleLbl = titleBlock(win, card, o.Title or "Button", o.Desc, o.Icon and 56 or 50)
        if o.Icon then
            local ic, kind = Icons.make(card, o.Icon, { size = UDim2.fromOffset(20, 20), anchor = Vector2.new(0, 0.5),
                position = UDim2.new(1, -34, 0.5, 0), color = win.Theme.Sub, textSize = 16 })
            win:onTheme(function() Icons.tint(ic, kind, win.Theme.Sub) end)
        else
            local arrow = txt(card, "›", 22, win.Theme.Sub, Enum.Font.GothamBold,
                { Size = UDim2.fromOffset(20, 20), AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(1, -28, 0.5, 0), TextXAlignment = Enum.TextXAlignment.Center })
            win:paint(arrow, "TextColor3", "Sub")
        end
        local btn = new("TextButton", { Parent = card, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Text = "", AutoButtonColor = false })
        corner(btn, 9)
        C.ripple(btn, win.Theme.Accent)
        C.press(btn, { radius = 8 })
        btn.MouseButton1Click:Connect(function() pcall(o.Callback) end)
        return { kind = "button", Instance = card, SetTitle = function(_, s) titleLbl.Text = s end, Destroy = function() card:Destroy() end }
    end
end
