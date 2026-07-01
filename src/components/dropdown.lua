return function(use, BPUI)
    local C = use("core")
    local new, txt, corner, stroke, pad, list, tw, hoverable = C.new, C.txt, C.corner, C.stroke, C.pad, C.list, C.tw, C.hoverable
    local Maid, UIS, mkCard, titleBlock = C.Maid, C.UIS, C.mkCard, C.titleBlock

    return function(win, page, o)
        local cm = Maid.new() win.maid:give(function() cm:clean() end)
        local card = mkCard(win, page, o.Desc and 54 or 44, true)
        titleBlock(win, card, o.Title or "Dropdown", o.Desc, 196)
        local items = o.Items or o.Options or {}
        local multi = o.Multi and true or false
        local useSearch = o.Search or (#items > 8)
        local function memberset() local m = {} for _, x in ipairs(items) do m[x] = true end return m end
        local selected = multi and {} or nil
        if multi and type(o.Default) == "table" then local m = memberset() for _, v in ipairs(o.Default) do if m[v] then selected[v] = true end end
        elseif not multi then selected = o.Default end
        local chip = new("Frame", { Parent = card, BackgroundColor3 = win.Theme.Panel2, AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(1, -180, 0.5, 0), Size = UDim2.fromOffset(166, 30) })
        corner(chip, 6)
        win:paint(chip, "BackgroundColor3", "Panel2")
        win:paint(stroke(chip, win.Theme.Stroke, 1, 0.5), "Color", "Stroke")
        local label = txt(chip, "", 13, win.Theme.Text, Enum.Font.GothamMedium,
            { Size = UDim2.new(1, -34, 1, 0), Position = UDim2.fromOffset(10, 0), TextTruncate = Enum.TextTruncate.AtEnd })
        win:paint(label, "TextColor3", "Text")
        local caret = txt(chip, "▾", 14, win.Theme.Sub, Enum.Font.GothamBold,
            { Size = UDim2.fromOffset(18, 18), Position = UDim2.new(1, -24, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), TextXAlignment = Enum.TextXAlignment.Center })
        win:paint(caret, "TextColor3", "Sub")
        C.bindRight(card, chip, { rightInset = 196, normalHeight = o.Desc and 54 or 44, compactHeight = o.Desc and 92 or 82, minWidth = 430, controlHeight = 30 })
        local function summary()
            if multi then
                local t = {}
                for _, v in ipairs(items) do if selected[v] then t[#t + 1] = tostring(v) end end
                return #t == 0 and "None" or (#t <= 2 and table.concat(t, ", ") or (#t .. " selected"))
            end
            return selected ~= nil and tostring(selected) or "..."
        end
        label.Text = summary()
        local obj = { kind = multi and "multidropdown" or "dropdown" }
        local open, menu, scroll, menuW = false, nil, nil, nil
        local function closeMenu()
            open = false
            if win._closePopup == closeMenu then win._closePopup = nil end
            if menu then local m = menu menu = nil tw(m, 0.12, { Size = UDim2.fromOffset(m.AbsoluteSize.X, 0), BackgroundTransparency = 1 })
                task.delay(0.14, function() m:Destroy() end) end
            tw(caret, 0.15, { Rotation = 0 })
        end
        local function fillItems(query)
            for _, ch in ipairs(scroll:GetChildren()) do if ch:IsA("TextButton") then ch:Destroy() end end
            query = (query or ""):lower()
            local matched = 0
            for _, v in ipairs(items) do
                if query == "" or tostring(v):lower():find(query, 1, true) then
                    matched += 1
                    local sel = multi and selected[v] or (selected == v)
                    local it = new("TextButton", { Parent = scroll, BackgroundColor3 = win.Theme.Panel, Text = "", AutoButtonColor = false,
                        Size = UDim2.new(1, 0, 0, 28), ZIndex = 102, BackgroundTransparency = sel and 0 or 1 })
                    corner(it, 6)
                    local il = txt(it, tostring(v), 13, sel and win.Theme.Accent or win.Theme.Sub, Enum.Font.GothamMedium,
                        { Size = UDim2.new(1, -16, 1, 0), Position = UDim2.fromOffset(10, 0), ZIndex = 102 })
                    hoverable(it, function() if not (multi and selected[v]) and selected ~= v then tw(it, 0.1, { BackgroundTransparency = 0.4 }) end end,
                        function() if not (multi and selected[v]) and selected ~= v then tw(it, 0.1, { BackgroundTransparency = 1 }) end end)
                    it.MouseButton1Click:Connect(function()
                        if multi then
                            selected[v] = (not selected[v]) and true or nil
                            label.Text = summary()
                            local on = selected[v] == true
                            il.TextColor3 = on and win.Theme.Accent or win.Theme.Sub
                            tw(it, 0.1, { BackgroundTransparency = on and 0 or 1 })
                            local out = {} for _, x in ipairs(items) do if selected[x] then out[#out + 1] = x end end
                            pcall(o.Callback, out) win:save()
                        else
                            selected = v label.Text = summary() pcall(o.Callback, v) win:save() closeMenu()
                        end
                    end)
                end
            end
            if menu and menuW then
                local r = math.clamp(matched, 1, 7)
                tw(menu, 0.1, { Size = UDim2.fromOffset(menuW, r * 30 + 8 + (useSearch and 34 or 0)) })
            end
        end
        local function buildMenu()
            local ph = C.popupHolder(win)
            local rows = math.min(#items, 7)
            local h = rows * 30 + 8 + (useSearch and 34 or 0)
            local w = math.max(chip.AbsoluteSize.X, 166)
            menuW = w
            local px, py = C.placePopup(chip, w, h)
            menu = new("Frame", { Parent = ph, BackgroundColor3 = win.Theme.Bg2, ZIndex = 101,
                Size = UDim2.fromOffset(w, 0), ClipsDescendants = true, Position = UDim2.fromOffset(px, py) })
            corner(menu, 8)
            stroke(menu, win.Theme.Stroke, 1, 0.2)
            local listY = 4
            if useSearch then
                local sb = new("Frame", { Parent = menu, BackgroundColor3 = win.Theme.Panel, Size = UDim2.new(1, -8, 0, 26), Position = UDim2.fromOffset(4, 4), ZIndex = 102 })
                corner(sb, 6)
                local stb = new("TextBox", { Parent = sb, BackgroundTransparency = 1, Size = UDim2.new(1, -16, 1, 0), Position = UDim2.fromOffset(8, 0),
                    Font = C.uifont(Enum.Font.Gotham), TextSize = 12, TextColor3 = win.Theme.Text, PlaceholderText = "Search...", PlaceholderColor3 = win.Theme.Dim,
                    Text = "", ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 103 })
                stb:GetPropertyChangedSignal("Text"):Connect(function() if scroll then fillItems(stb.Text) end end)
                listY = 34
            end
            scroll = new("ScrollingFrame", { Parent = menu, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, -listY), Position = UDim2.fromOffset(0, listY),
                CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 3, ZIndex = 102,
                ScrollBarImageColor3 = win.Theme.Accent, BorderSizePixel = 0 })
            pad(scroll, 4, 4, 4, 4) list(scroll, 2)
            fillItems("")
            tw(menu, 0.14, { Size = UDim2.fromOffset(w, h) })
        end
        local btn = new("TextButton", { Parent = chip, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Text = "", AutoButtonColor = false })
        btn.MouseButton1Click:Connect(function()
            if open then closeMenu() else open = true win._closePopup = closeMenu tw(caret, 0.15, { Rotation = 180 }) buildMenu() end
        end)
        cm:give(UIS.InputBegan:Connect(function(i)
            if open and C.isPress(i) and menu then
                local mp = i.Position
                local p, s = menu.AbsolutePosition, menu.AbsoluteSize
                local cp, cs = chip.AbsolutePosition, chip.AbsoluteSize
                local inMenu = mp.X >= p.X and mp.X <= p.X + s.X and mp.Y >= p.Y and mp.Y <= p.Y + s.Y
                local inChip = mp.X >= cp.X and mp.X <= cp.X + cs.X and mp.Y >= cp.Y and mp.Y <= cp.Y + cs.Y
                if not inMenu and not inChip then closeMenu() end
            end
        end))
        function obj:Set(v, fire)
            if multi then
                local m = memberset() selected = {}
                if type(v) == "table" then for _, x in ipairs(v) do if m[x] then selected[x] = true end end end
            else
                local m = memberset()
                if v ~= nil and not m[v] then v = nil end
                selected = v
            end
            label.Text = summary()
            if fire ~= false then
                if multi then local out = {} for _, x in ipairs(items) do if selected[x] then out[#out + 1] = x end end pcall(o.Callback, out)
                else pcall(o.Callback, v) end
                win:save()
            end
        end
        function obj:Get()
            if multi then local out = {} for _, x in ipairs(items) do if selected[x] then out[#out + 1] = x end end return out end
            return selected
        end
        obj.Instance = card
        function obj:Refresh(newItems, keep)
            items = newItems or {}
            useSearch = o.Search or (#items > 8)
            if not keep then if multi then selected = {} else selected = nil end end
            label.Text = summary()
            if open then closeMenu() end
        end
        function obj:Destroy() if menu then menu:Destroy() end cm:clean() card:Destroy() end
        return obj
    end
end
