return function(use, BPUI)
    local C = use("core")
    local Icons = use("icons")
    local Tab = use("tab")
    local new, txt, corner = C.new, C.txt, C.corner

    return function(win, o)
        o = o or {}
        local side = (o.Side == "left") and "left" or "right"
        local width = C.safePopupWidth(math.min(o.Width or 300, 460), 24, 240)
        local shell = win.shell
        local topH = 52

        local function closedPos() return side == "right" and UDim2.new(1, width, 0, topH) or UDim2.new(0, -width, 0, topH) end
        local function openPos() return side == "right" and UDim2.new(1, 0, 0, topH) or UDim2.new(0, 0, 0, topH) end

        local dim = new("Frame", { Parent = shell, BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1,
            Position = UDim2.fromOffset(0, topH), Size = UDim2.new(1, 0, 1, -topH), ZIndex = 30, Visible = false, Active = true, BorderSizePixel = 0 })

        local panel = new("CanvasGroup", { Parent = shell, BackgroundColor3 = win.Theme.Bg2,
            Size = UDim2.new(0, width, 1, -topH), ZIndex = 31, GroupTransparency = 0, Position = closedPos(),
            AnchorPoint = side == "right" and Vector2.new(1, 0) or Vector2.new(0, 0), BorderSizePixel = 0 })
        win:paint(panel, "BackgroundColor3", "Bg2")

        local edge = new("Frame", { Parent = panel, Size = UDim2.new(0, 1, 1, 0), BackgroundColor3 = win.Theme.Stroke, BackgroundTransparency = 0.25,
            BorderSizePixel = 0, AnchorPoint = side == "right" and Vector2.new(0, 0) or Vector2.new(1, 0),
            Position = side == "right" and UDim2.new(0, 0, 0, 0) or UDim2.new(1, 0, 0, 0), ZIndex = 5 })
        win:paint(edge, "BackgroundColor3", "Stroke")

        local header = new("Frame", { Parent = panel, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 46) })
        local tx = 16
        if o.Icon then
            local ic, ik = Icons.make(header, o.Icon, { size = UDim2.fromOffset(20, 20), anchor = Vector2.new(0, 0.5),
                position = UDim2.new(0, 16, 0.5, 0), color = win.Theme.Accent })
            win:onTheme(function() Icons.tint(ic, ik, win.Theme.Accent) end)
            tx = 46
        end
        local tl = txt(header, o.Title or "Panel", 15, win.Theme.Text, Enum.Font.GothamBold,
            { Size = UDim2.new(1, -(tx + 44), 1, 0), Position = UDim2.fromOffset(tx, 0), TextYAlignment = Enum.TextYAlignment.Center, TextTruncate = Enum.TextTruncate.AtEnd })
        win:paint(tl, "TextColor3", "Text")
        local close = new("TextButton", { Parent = header, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0),
            Size = UDim2.fromOffset(28, 28), BackgroundColor3 = win.Theme.Panel, BackgroundTransparency = 1, Text = "", AutoButtonColor = false })
        corner(close, 7)
        win:paint(close, "BackgroundColor3", "Panel")
        local cIco, cKind = Icons.make(close, "close", { size = UDim2.fromOffset(16, 16), anchor = Vector2.new(0.5, 0.5), position = UDim2.fromScale(0.5, 0.5), color = win.Theme.Sub })
        win:onTheme(function() Icons.tint(cIco, cKind, win.Theme.Sub) end)
        local hdiv = new("Frame", { Parent = panel, Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 0, 46),
            BackgroundColor3 = win.Theme.Stroke, BackgroundTransparency = 0.45, BorderSizePixel = 0 })
        win:paint(hdiv, "BackgroundColor3", "Stroke")

        local page = new("ScrollingFrame", { Parent = panel, BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 47),
            Size = UDim2.new(1, 0, 1, -47), CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 3,
            ScrollBarImageColor3 = win.Theme.Accent, ScrollBarImageTransparency = 0.5, BorderSizePixel = 0 })
        C.pad(page, 14, 12, 14, 16) C.list(page, 10)
        win:paint(page, "ScrollBarImageColor3", "Accent")

        local open = false
        local function setOpen(v)
            if v == open then return end
            open = v
            if v then
                if win._closeFlyout and win._closeFlyout ~= setOpen then pcall(win._closeFlyout) end
                win._closeFlyout = function() setOpen(false) end
                dim.Visible = true
                C.tw(dim, 0.2, { BackgroundTransparency = 0.45 })
                C.tw(panel, 0.28, { Position = openPos() })
            else
                if win._closeFlyout == nil or open == false then win._closeFlyout = nil end
                C.tw(dim, 0.18, { BackgroundTransparency = 1 })
                C.tw(panel, 0.22, { Position = closedPos() })
                task.delay(0.24, function() if not open then dim.Visible = false end end)
            end
        end
        C.hoverable(close, function() C.tw(close, 0.12, { BackgroundTransparency = 0 }) Icons.tint(cIco, cKind, win.Theme.Bad) end,
            function() C.tw(close, 0.12, { BackgroundTransparency = 1 }) Icons.tint(cIco, cKind, win.Theme.Sub) end)
        C.press(close, { radius = 7 })
        close.MouseButton1Click:Connect(function() setOpen(false) end)
        dim.InputBegan:Connect(function(i) if C.isPress(i) and o.DismissOnClickOutside ~= false then setOpen(false) end end)

        local tabObj = { name = o.Title, page = page }
        local sub = setmetatable({ win = win, page = page, tab = tabObj }, Tab)
        sub.Open = function() setOpen(true) end
        sub.Close = function() setOpen(false) end
        sub.Toggle = function() setOpen(not open) end
        sub.IsOpen = function() return open end
        sub.SetOpen = function(_, v) setOpen(v and true or false) end
        sub.Instance = panel
        sub.Destroy = function()
            if win._closeFlyout and open then win._closeFlyout = nil end
            pcall(function() panel:Destroy() end) pcall(function() dim:Destroy() end)
        end
        return sub
    end
end
