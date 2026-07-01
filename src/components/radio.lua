return function(use, BPUI)
    local C = use("core")
    local new, txt, corner, stroke, tw, hoverable, mkCard, titleBlock = C.new, C.txt, C.corner, C.stroke, C.tw, C.hoverable, C.mkCard, C.titleBlock

    return function(win, page, o)
        local raw = o.Options or o.Items or {}
        local opts = {}
        for _, x in ipairs(raw) do
            if type(x) == "table" then opts[#opts + 1] = { title = tostring(x.Title or x.title or ""), desc = x.Desc or x.desc }
            else opts[#opts + 1] = { title = tostring(x) } end
        end
        local headerH = o.Desc and 40 or 30
        local rowY = {}
        local total = headerH
        for i, op in ipairs(opts) do
            local rh = (op.desc and op.desc ~= "") and 44 or 32
            rowY[i] = { y = total, h = rh }
            total = total + rh
        end
        local card = mkCard(win, page, total + 10, true)
        local hdr = txt(card, o.Title or "Choose", 14, win.Theme.Text, Enum.Font.GothamMedium,
            { Size = UDim2.new(1, -28, 0, 18), Position = UDim2.fromOffset(14, 8) })
        win:paint(hdr, "TextColor3", "Text")
        if o.Desc and o.Desc ~= "" then
            local dsc = txt(card, o.Desc, 12, win.Theme.Sub, Enum.Font.Gotham,
                { Size = UDim2.new(1, -28, 0, 14), Position = UDim2.fromOffset(14, 26) })
            win:paint(dsc, "TextColor3", "Sub")
        end
        local sel = o.Default
        local rows = {}
        local obj = { kind = "radio" }
        local function applyRow(i)
            local r = rows[i]
            local on = sel == opts[i].title
            r.dot.Visible = on
            r.ring.BackgroundColor3 = on and win.Theme.Panel or win.Theme.Panel2
            tw(r.ringS, 0.15, { Color = on and win.Theme.Accent or win.Theme.Stroke, Transparency = on and 0 or 0.5 })
        end
        local function render(fire)
            for i = 1, #rows do applyRow(i) end
            if fire then pcall(o.Callback, sel) end
        end
        for i, op in ipairs(opts) do
            local pos = rowY[i]
            local row = new("Frame", { Parent = card, BackgroundTransparency = 1, Size = UDim2.new(1, -20, 0, pos.h),
                Position = UDim2.fromOffset(14, pos.y) })
            local ring = new("Frame", { Parent = row, Size = UDim2.fromOffset(16, 16), AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(0, 0, 0.5, 0), BackgroundColor3 = win.Theme.Panel2 })
            corner(ring, 8)
            local ringS = stroke(ring, win.Theme.Stroke, 1, 0.5)
            local dot = new("Frame", { Parent = ring, Size = UDim2.fromOffset(8, 8), AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0.5, 0.5), BackgroundColor3 = win.Theme.Accent, Visible = false })
            corner(dot, 6)
            win:paint(dot, "BackgroundColor3", "Accent")
            local hasD = op.desc and op.desc ~= ""
            local tl = txt(row, op.title, 13, win.Theme.Text, Enum.Font.GothamMedium,
                { Size = UDim2.new(1, -28, 0, hasD and 16 or pos.h), Position = UDim2.fromOffset(26, hasD and 6 or 0),
                    TextYAlignment = hasD and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center, TextTruncate = Enum.TextTruncate.AtEnd })
            win:paint(tl, "TextColor3", "Text")
            if hasD then
                local dl = txt(row, op.desc, 11, win.Theme.Sub, Enum.Font.Gotham,
                    { Size = UDim2.new(1, -28, 0, 14), Position = UDim2.fromOffset(26, 24), TextTruncate = Enum.TextTruncate.AtEnd })
                win:paint(dl, "TextColor3", "Sub")
            end
            local btn = new("TextButton", { Parent = row, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Text = "", AutoButtonColor = false })
            hoverable(row, function() if sel ~= op.title then tw(ringS, 0.12, { Transparency = 0.2 }) end end,
                function() if sel ~= op.title then tw(ringS, 0.12, { Transparency = 0.5 }) end end)
            btn.MouseButton1Click:Connect(function() if sel ~= op.title then sel = op.title render(true) win:save() end end)
            rows[i] = { ring = ring, ringS = ringS, dot = dot }
        end
        win:onTheme(function() for i = 1, #rows do applyRow(i) end end)
        render(false)
        function obj:Set(v, fire)
            local ok = false
            for _, op in ipairs(opts) do if op.title == v then ok = true break end end
            if not ok then return end
            sel = v
            render(fire ~= false)
            if fire ~= false then win:save() end
        end
        function obj:Get() return sel end
        obj.Instance = card
        function obj:Destroy() card:Destroy() end
        return obj
    end
end
