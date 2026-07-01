return function(use, BPUI)
    local C = use("core")
    local Icons = use("icons")
    local new, txt, mkCard = C.new, C.txt, C.mkCard
    return function(win, page, o)
        local card = mkCard(win, page, 64, true)
        local accent = o.Color or win.Theme.Accent
        local inset = 14
        local ic, ik
        if o.Icon then
            inset = 56
            ic, ik = Icons.make(card, o.Icon, { size = UDim2.fromOffset(26, 24), position = UDim2.fromOffset(16, 18), color = accent, textSize = 20 })
        end
        local title = txt(card, o.Title or "Stat", 12, win.Theme.Sub, Enum.Font.GothamMedium,
            { Size = UDim2.new(1, -(inset + 14), 0, 16), Position = UDim2.fromOffset(inset, 10), TextTruncate = Enum.TextTruncate.AtEnd })
        win:paint(title, "TextColor3", "Sub")
        local value = txt(card, tostring(o.Value == nil and "0" or o.Value), 22, win.Theme.Text, Enum.Font.GothamBold,
            { Size = UDim2.new(1, -(inset + 14), 0, 28), Position = UDim2.fromOffset(inset, 28), TextTruncate = Enum.TextTruncate.AtEnd })
        if o.Color then value.TextColor3 = o.Color else win:paint(value, "TextColor3", "Text") end
        if o.Icon and not o.Color then win:onTheme(function() Icons.tint(ic, ik, win.Theme.Accent) end) end
        local obj = { kind = "stat" }
        obj.Instance = card
        function obj:SetValue(v) value.Text = tostring(v) end
        function obj:SetTitle(s) title.Text = tostring(s) end
        function obj:Destroy() card:Destroy() end
        return obj
    end
end
