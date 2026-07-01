return function(use, BPUI)
    local C = use("core")
    local new, txt, corner, stroke, tw, mkCard, titleBlock = C.new, C.txt, C.corner, C.stroke, C.tw, C.mkCard, C.titleBlock
    local Maid, UIS = C.Maid, C.UIS

    return function(win, page, o)
        local cm = Maid.new() win.maid:give(function() cm:clean() end)
        local card = mkCard(win, page, o.Desc and 54 or 44, true)
        titleBlock(win, card, o.Title or "Keybind", o.Desc, 130)
        local cur = o.Default or "None"
        local box = new("TextButton", { Parent = card, BackgroundColor3 = win.Theme.Panel2, AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(1, -120, 0.5, 0), Size = UDim2.fromOffset(106, 30), Text = "", AutoButtonColor = false })
        corner(box, 6)
        win:paint(box, "BackgroundColor3", "Panel2")
        local bs = stroke(box, win.Theme.Stroke, 1, 0.5)
        local kl = txt(box, tostring(cur), 13, win.Theme.Sub, Enum.Font.GothamMedium,
            { Size = UDim2.new(1, 0, 1, 0), TextXAlignment = Enum.TextXAlignment.Center })
        win:paint(kl, "TextColor3", "Sub")
        C.bindRight(card, box, { rightInset = 130, normalHeight = o.Desc and 54 or 44, compactHeight = o.Desc and 92 or 82, minWidth = 360, controlHeight = 30, fill = false })
        local capturing, justBound = false, false
        local obj = { kind = "keybind" }
        box.MouseButton1Click:Connect(function()
            capturing = true kl.Text = "..." tw(bs, 0.15, { Color = win.Theme.Accent, Transparency = 0 })
        end)
        cm:give(UIS.InputBegan:Connect(function(i, gpe)
            if capturing then
                capturing = false justBound = true
                tw(bs, 0.15, { Color = win.Theme.Stroke, Transparency = 0.5 })
                local nm = C.keyFromInput(i)
                if i.KeyCode == Enum.KeyCode.Escape or i.KeyCode == Enum.KeyCode.Backspace then nm = "None" end
                cur = nm or "None" kl.Text = cur win:save()
                pcall(o.ChangedCallback, cur)
                task.defer(function() justBound = false end)
                return
            end
            if gpe or justBound or cur == "None" or obj._enabled == false then return end
            if C.keyMatches(i, cur) then pcall(o.Callback, cur) end
        end))
        function obj:Set(v, fire) cur = v or "None" kl.Text = cur if fire ~= false then pcall(o.ChangedCallback, cur) win:save() end end
        function obj:Get() return cur end
        obj.Instance = card
        function obj:Destroy() cm:clean() card:Destroy() end
        return obj
    end
end
