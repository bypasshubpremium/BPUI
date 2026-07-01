return function(use, BPUI)
    local C = use("core")
    local new, corner, stroke, tw, mkCard, titleBlock = C.new, C.corner, C.stroke, C.tw, C.mkCard, C.titleBlock
    local Maid, UIS = C.Maid, C.UIS

    return function(win, page, o)
        local cm = Maid.new() win.maid:give(function() cm:clean() end)
        local card = mkCard(win, page, o.Desc and 54 or 44, true)
        titleBlock(win, card, o.Title or "Color", o.Desc, 74)
        local col = o.Default or Color3.fromRGB(255, 255, 255)
        local h, s, v = col:ToHSV()
        local sw = new("TextButton", { Parent = card, BackgroundColor3 = col, AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(1, -52, 0.5, 0), Size = UDim2.fromOffset(38, 26), Text = "", AutoButtonColor = false })
        corner(sw, 6) win:paint(stroke(sw, win.Theme.Stroke, 1, 0.3), "Color", "Stroke")
        local obj = { kind = "color" }
        local open, panel = false, nil
        local svDot, hDot, svArea, hue
        local dragSV, dragH = false, false
        local function fire() col = Color3.fromHSV(h, s, v) sw.BackgroundColor3 = col pcall(o.Callback, col) end
        local function updSV(p)
            if not svArea then return end
            s = math.clamp((p.X - svArea.AbsolutePosition.X) / math.max(1, svArea.AbsoluteSize.X), 0, 1)
            v = 1 - math.clamp((p.Y - svArea.AbsolutePosition.Y) / math.max(1, svArea.AbsoluteSize.Y), 0, 1)
            svDot.Position = UDim2.fromScale(s, 1 - v) fire()
        end
        local function updH(p)
            if not hue then return end
            h = math.clamp((p.Y - hue.AbsolutePosition.Y) / math.max(1, hue.AbsoluteSize.Y), 0, 0.9999)
            hDot.Position = UDim2.fromScale(0.5, h) svArea.BackgroundColor3 = Color3.fromHSV(h, 1, 1) fire()
        end
        local function close()
            open = false
            if win._closePopup == close then win._closePopup = nil end
            if panel then local p = panel panel = nil tw(p, 0.12, { Size = UDim2.fromOffset(p.AbsoluteSize.X, 0), BackgroundTransparency = 1 })
                task.delay(0.14, function() p:Destroy() end) end
        end
        local function build()
            local ph = C.popupHolder(win)
            local px, py = C.placePopup(sw, 200, 152)
            panel = new("Frame", { Parent = ph, BackgroundColor3 = win.Theme.Bg2, ZIndex = 101, Size = UDim2.fromOffset(200, 0),
                ClipsDescendants = true, Position = UDim2.fromOffset(px, py) })
            corner(panel, 8) stroke(panel, win.Theme.Stroke, 1, 0.2)
            local inner = new("Frame", { Parent = panel, BackgroundTransparency = 1, Size = UDim2.new(1, -16, 1, -16), Position = UDim2.fromOffset(8, 8), ZIndex = 102 })
            svArea = new("ImageButton", { Parent = inner, Size = UDim2.fromOffset(150, 120), BackgroundColor3 = Color3.fromHSV(h, 1, 1), ZIndex = 102, AutoButtonColor = false })
            corner(svArea, 6)
            local g1 = new("Frame", { Parent = svArea, Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 102 })
            corner(g1, 6)
            new("UIGradient", { Parent = g1, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) }) })
            local g2 = new("Frame", { Parent = svArea, Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.new(0, 0, 0), ZIndex = 102 })
            corner(g2, 6)
            new("UIGradient", { Parent = g2, Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) }) })
            svDot = new("Frame", { Parent = svArea, Size = UDim2.fromOffset(8, 8), AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 103, Position = UDim2.fromScale(s, 1 - v) })
            corner(svDot, 4) stroke(svDot, Color3.new(0, 0, 0), 1, 0.2)
            hue = new("ImageButton", { Parent = inner, Size = UDim2.fromOffset(18, 120), Position = UDim2.fromOffset(158, 0), ZIndex = 102, AutoButtonColor = false })
            corner(hue, 6)
            new("UIGradient", { Parent = hue, Rotation = 90, Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)), ColorSequenceKeypoint.new(0.167, Color3.fromRGB(255, 255, 0)),
                ColorSequenceKeypoint.new(0.333, Color3.fromRGB(0, 255, 0)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
                ColorSequenceKeypoint.new(0.667, Color3.fromRGB(0, 0, 255)), ColorSequenceKeypoint.new(0.833, Color3.fromRGB(255, 0, 255)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)) }) })
            hDot = new("Frame", { Parent = hue, Size = UDim2.new(1, 0, 0, 3), AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0.5, h), BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 103 })
            corner(hDot, 1)
            svArea.InputBegan:Connect(function(i) if C.isPress(i) then dragSV = true updSV(i.Position) end end)
            hue.InputBegan:Connect(function(i) if C.isPress(i) then dragH = true updH(i.Position) end end)
            tw(panel, 0.14, { Size = UDim2.fromOffset(200, 152) })
        end
        cm:give(UIS.InputChanged:Connect(function(i) if open and C.isMove(i) then if dragSV then updSV(i.Position) elseif dragH then updH(i.Position) end end end))
        cm:give(UIS.InputEnded:Connect(function(i) if C.isPress(i) and (dragSV or dragH) then dragSV = false dragH = false win:save() end end))
        cm:give(UIS.InputBegan:Connect(function(i)
            if open and C.isPress(i) and panel then
                local mp = i.Position
                local p, sz = panel.AbsolutePosition, panel.AbsoluteSize
                local wp, ws = sw.AbsolutePosition, sw.AbsoluteSize
                local inPanel = mp.X >= p.X and mp.X <= p.X + sz.X and mp.Y >= p.Y and mp.Y <= p.Y + sz.Y
                local inSw = mp.X >= wp.X and mp.X <= wp.X + ws.X and mp.Y >= wp.Y and mp.Y <= wp.Y + ws.Y
                if not inPanel and not inSw then close() end
            end
        end))
        sw.MouseButton1Click:Connect(function() if open then close() else open = true win._closePopup = close build() end end)
        function obj:Set(c, f)
            col = c h, s, v = c:ToHSV() sw.BackgroundColor3 = c
            if open and svDot then svDot.Position = UDim2.fromScale(s, 1 - v) hDot.Position = UDim2.fromScale(0.5, h) svArea.BackgroundColor3 = Color3.fromHSV(h, 1, 1) end
            if f ~= false then pcall(o.Callback, c) win:save() end
        end
        function obj:Get() return col end
        obj.Instance = card
        function obj:Destroy() if panel then panel:Destroy() end cm:clean() card:Destroy() end
        return obj
    end
end
