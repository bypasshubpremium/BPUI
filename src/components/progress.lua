return function(use, BPUI)
    local C = use("core")
    local new, txt, corner, tw, mkCard, titleBlock = C.new, C.txt, C.corner, C.tw, C.mkCard, C.titleBlock

    return function(win, page, o)
        local card = mkCard(win, page, 50, true)
        titleBlock(win, card, o.Title or "Progress", o.Desc, 90)
        local val = math.clamp(o.Default or 0, 0, 1)
        local pct = txt(card, math.floor(val * 100) .. "%", 13, win.Theme.Accent, C.MONO,
            { Size = UDim2.fromOffset(60, 18), Position = UDim2.new(1, -76, 0, 8), TextXAlignment = Enum.TextXAlignment.Right })
        win:paint(pct, "TextColor3", "Accent")
        local track = new("Frame", { Parent = card, Size = UDim2.new(1, -32, 0, 5), Position = UDim2.new(0, 16, 1, -15), BackgroundColor3 = win.Theme.Panel2 })
        corner(track, 3)
        win:paint(track, "BackgroundColor3", "Panel2")
        local fill = new("Frame", { Parent = track, Size = UDim2.fromScale(val, 1), BackgroundColor3 = win.Theme.Accent })
        corner(fill, 3)
        C.gloss(fill, 0.85)
        win:paint(fill, "BackgroundColor3", "Accent")
        local obj = { kind = "progress" }
        function obj:Set(v)
            val = math.clamp(v or 0, 0, 1)
            tw(fill, 0.25, { Size = UDim2.fromScale(val, 1) })
            pct.Text = math.floor(val * 100) .. "%"
        end
        function obj:Get() return val end
        obj.Instance = card
        function obj:Destroy() card:Destroy() end
        return obj
    end
end
