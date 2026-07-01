return function(use, BPUI)
    local C = {}

    local Players = game:GetService("Players")
    local UIS = game:GetService("UserInputService")
    local TS = game:GetService("TweenService")
    local RunService = game:GetService("RunService")
    local HttpService = game:GetService("HttpService")
    local GuiService = game:GetService("GuiService")
    local Lighting = game:GetService("Lighting")
    local lp = Players.LocalPlayer

    C.Players, C.UIS, C.TS, C.RunService, C.HttpService, C.GuiService, C.Lighting, C.lp =
        Players, UIS, TS, RunService, HttpService, GuiService, Lighting, lp
    C.IS_TOUCH = UIS.TouchEnabled
    C.HAS_MOUSE = UIS.MouseEnabled

    function C.viewport()
        local cam = workspace.CurrentCamera
        return (cam and cam.ViewportSize) or Vector2.new(1280, 720)
    end
    local function udimOffset(v, axis, fallback)
        if typeof(v) == "UDim2" then
            local u = axis == "Y" and v.Y or v.X
            if u.Offset and u.Offset > 0 then return u.Offset end
        end
        return fallback
    end
    function C.insetTop()
        local ok, i = pcall(function() return GuiService:GetGuiInset() end)
        return (ok and i and i.Y) or 36
    end
    function C.safeWindowSize(size, minSize)
        local vp = C.viewport()
        local top = C.insetTop()
        local maxW = math.max(280, vp.X - 16)
        local maxH = math.max(260, vp.Y - top - 16)
        local minW = math.min(udimOffset(minSize, "X", 360), maxW)
        local minH = math.min(udimOffset(minSize, "Y", 280), maxH)
        local w = math.clamp(udimOffset(size, "X", 720), minW, maxW)
        local h = math.clamp(udimOffset(size, "Y", 470), minH, maxH)
        return w, h
    end
    function C.safePopupWidth(w, pad, minW)
        local vp = C.viewport()
        local maxW = math.max(120, vp.X - (pad or 32))
        local low = math.min(minW or 220, maxW)
        return math.clamp(w or maxW, low, maxW)
    end
    function C.host()
        local ok, h = pcall(function() return gethui and gethui() end)
        if ok and typeof(h) == "Instance" then return h end
        local ok2, cg = pcall(function() return game:GetService("CoreGui") end)
        if ok2 and cg then return cg end
        local plr = lp or Players.LocalPlayer
        if not plr then Players:GetPropertyChangedSignal("LocalPlayer"):Wait() plr = Players.LocalPlayer end
        return plr:WaitForChild("PlayerGui")
    end
    function C.protect(g)
        pcall(function()
            if syn and syn.protect_gui then syn.protect_gui(g)
            elseif protectgui then protectgui(g)
            elseif gethui then g.Parent = gethui() end
        end)
    end
    C.hasFS = (writefile and readfile and isfile and makefolder and isfolder) and true or false
    C.customAsset = getcustomasset or getsynasset or (syn and syn.getcustomasset)

    function C.new(class, props, kids)
        local o = Instance.new(class)
        if props then for k, v in pairs(props) do if k ~= "Parent" then o[k] = v end end end
        if kids then for _, c in ipairs(kids) do c.Parent = o end end
        if props and props.Parent then o.Parent = props.Parent end
        return o
    end
    local new = C.new
    function C.corner(o, r) return new("UICorner", { Parent = o, CornerRadius = UDim.new(0, r or 8) }) end
    function C.stroke(o, col, th, tr)
        return new("UIStroke", { Parent = o, Color = col, Thickness = th or 1, Transparency = tr or 0,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
    end
    function C.fluentStroke(o, col, tr)
        local s = new("UIStroke", { Parent = o, Color = col, Thickness = 1, Transparency = tr or 0,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
        new("UIGradient", { Parent = s, Rotation = 90, Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(0.5, 0.5), NumberSequenceKeypoint.new(1, 0.7) }) })
        return s
    end
    function C.pad(o, l, r, t, b)
        return new("UIPadding", { Parent = o, PaddingLeft = UDim.new(0, l or 0), PaddingRight = UDim.new(0, r or 0),
            PaddingTop = UDim.new(0, t or 0), PaddingBottom = UDim.new(0, b or 0) })
    end
    function C.list(o, gap, dir, align)
        return new("UIListLayout", { Parent = o, Padding = UDim.new(0, gap or 0),
            FillDirection = dir or Enum.FillDirection.Vertical, SortOrder = Enum.SortOrder.LayoutOrder,
            HorizontalAlignment = align or Enum.HorizontalAlignment.Left, VerticalAlignment = Enum.VerticalAlignment.Top })
    end
    function C.gradient(o, rot, ...)
        local stops = { ... }
        local kp = {}
        for i, col in ipairs(stops) do kp[i] = ColorSequenceKeypoint.new((i - 1) / math.max(1, #stops - 1), col) end
        return new("UIGradient", { Parent = o, Rotation = rot or 0, Color = ColorSequence.new(kp) })
    end
    C._tw = setmetatable({}, { __mode = "k" })
    function C.tw(o, t, props, style, dir)
        if not (o and props) then return end
        local bucket = C._tw[o]
        if not bucket then
            bucket = {}
            C._tw[o] = bucket
        end
        for prop in pairs(props) do
            local old = bucket[prop]
            if old then pcall(function() old:Cancel() end) end
        end
        local g = TS:Create(o, TweenInfo.new(t or 0.18, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), props)
        for prop in pairs(props) do bucket[prop] = g end
        g.Completed:Connect(function()
            for prop in pairs(props) do if bucket[prop] == g then bucket[prop] = nil end end
            if next(bucket) == nil then C._tw[o] = nil end
        end)
        g:Play()
        return g
    end
    function C.spring(o, t, props)
        local g = TS:Create(o, TweenInfo.new(t or 0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), props)
        g:Play() return g
    end
    function C.lighten(col, a) return col:Lerp(Color3.new(1, 1, 1), a or 0.12) end
    function C.darken(col, a) return col:Lerp(Color3.new(0, 0, 0), a or 0.12) end
    local function tryFont(n) local ok, f = pcall(function() return Enum.Font[n] end) return ok and f or nil end
    C.fontMap = {}
    do
        local BS, BSM, BSB = tryFont("BuilderSans"), tryFont("BuilderSansMedium"), tryFont("BuilderSansBold")
        if BS then C.fontMap[Enum.Font.Gotham] = BS end
        if BSM then C.fontMap[Enum.Font.GothamMedium] = BSM end
        if BSB then C.fontMap[Enum.Font.GothamBold] = BSB C.fontMap[Enum.Font.GothamBlack] = BSB end
    end
    C.MONO = tryFont("RobotoMono") or tryFont("Code") or Enum.Font.GothamBold
    function C.uifont(font) return C.fontMap[font] or font end
    function C.txt(parent, s, size, col, font, props)
        props = props or {}
        local o = new("TextLabel", props)
        o.Parent = parent o.BackgroundTransparency = 1 o.Text = s o.TextSize = size or 14
        o.TextColor3 = col o.Font = C.fontMap[font] or font or Enum.Font.Gotham
        if props.TextXAlignment == nil then o.TextXAlignment = Enum.TextXAlignment.Left end
        return o
    end
    function C.isPress(i)
        return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch
    end
    function C.isMove(i)
        return i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch
    end
    function C.hoverable(o, onIn, onOut)
        o.MouseEnter:Connect(onIn)
        o.MouseLeave:Connect(onOut)
        if C.IS_TOUCH then
            o.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch then onIn() end end)
            o.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch then onOut() end end)
        end
    end
    function C.ripple(btn, col)
        btn.InputBegan:Connect(function(i)
            if not C.isPress(i) then return end
            local holder = btn
            if not btn.ClipsDescendants then btn.ClipsDescendants = true end
            local sz = math.max(btn.AbsoluteSize.X, btn.AbsoluteSize.Y) * 1.6
            local rx = i.Position.X - btn.AbsolutePosition.X
            local ry = i.Position.Y - btn.AbsolutePosition.Y
            local circ = new("Frame", { Parent = holder, BackgroundColor3 = col or Color3.new(1, 1, 1),
                BackgroundTransparency = 0.78, AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = (btn.ZIndex or 1) + 1,
                Position = UDim2.fromOffset(rx, ry), Size = UDim2.fromOffset(0, 0) })
            new("UICorner", { Parent = circ, CornerRadius = UDim.new(1, 0) })
            C.tw(circ, 0.45, { Size = UDim2.fromOffset(sz, sz), BackgroundTransparency = 1 })
            task.delay(0.5, function() circ:Destroy() end)
        end)
    end
    function C.press(o, opts)
        opts = opts or {}
        local ov = new("Frame", { Parent = o, BackgroundColor3 = opts.color or Color3.new(0, 0, 0), BorderSizePixel = 0,
            BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = (o.ZIndex or 1) + 6, Active = false })
        if opts.radius then C.corner(ov, opts.radius) end
        local lvl = opts.level or 0.86
        local function down(i) if C.isPress(i) then C.tw(ov, 0.05, { BackgroundTransparency = lvl }) end end
        local function up(i) if C.isPress(i) then C.tw(ov, 0.2, { BackgroundTransparency = 1 }) end end
        o.InputBegan:Connect(down)
        o.InputEnded:Connect(up)
        o.MouseLeave:Connect(function() C.tw(ov, 0.2, { BackgroundTransparency = 1 }) end)
        return ov
    end
    function C.shadow(parent, transparency, spread)
        spread = spread or 30
        return new("ImageLabel", { Parent = parent, BackgroundTransparency = 1, Image = "rbxassetid://6014261993",
            ScaleType = Enum.ScaleType.Slice, SliceCenter = Rect.new(49, 49, 450, 450), ImageColor3 = Color3.new(0, 0, 0),
            ImageTransparency = transparency or 0.4, Size = UDim2.new(1, spread * 2, 1, spread * 2),
            Position = UDim2.fromOffset(-spread, -spread), ZIndex = 0 })
    end
    function C.glow(parent, color, transparency, spread)
        spread = spread or 22
        return new("ImageLabel", { Parent = parent, BackgroundTransparency = 1, Image = "rbxassetid://6014261993",
            ScaleType = Enum.ScaleType.Slice, SliceCenter = Rect.new(49, 49, 450, 450), ImageColor3 = color or Color3.new(1, 1, 1),
            ImageTransparency = transparency or 0.72, Size = UDim2.new(1, spread * 2, 1, spread * 2),
            Position = UDim2.fromOffset(-spread, -spread), ZIndex = 0 })
    end
    function C.gloss(o, bot)
        bot = bot or 0.87
        return new("UIGradient", { Parent = o, Rotation = 90, Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
            ColorSequenceKeypoint.new(0.5, Color3.new((1 + bot) / 2, (1 + bot) / 2, (1 + bot) / 2)),
            ColorSequenceKeypoint.new(1, Color3.new(bot, bot, bot)) }) })
    end
    function C.softGlow(parent, color, transparency, spread)
        spread = spread or 10
        return new("ImageLabel", { Parent = parent, BackgroundTransparency = 1, Image = "rbxassetid://6014261993",
            ScaleType = Enum.ScaleType.Slice, SliceCenter = Rect.new(49, 49, 450, 450), ImageColor3 = color or Color3.new(1, 1, 1),
            ImageTransparency = transparency or 0.6, Size = UDim2.new(1, spread * 2, 1, spread * 2),
            Position = UDim2.fromOffset(-spread, -spread), ZIndex = 0, BorderSizePixel = 0 })
    end
    function C.sheen(o, col, period)
        local g = new("UIGradient", { Parent = o, Rotation = 18,
            Color = ColorSequence.new(col or Color3.new(1, 1, 1)),
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.45, 1),
                NumberSequenceKeypoint.new(0.5, 0.9), NumberSequenceKeypoint.new(0.55, 1),
                NumberSequenceKeypoint.new(1, 1) }),
            Offset = Vector2.new(-1.2, 0) })
        local tween = TS:Create(g, TweenInfo.new(period or 5.5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1, false, 2.5),
            { Offset = Vector2.new(1.2, 0) })
        tween:Play()
        return g, tween
    end
    function C.tooltip(win, inst, text)
        if not text or text == "" or not C.HAS_MOUSE then return end
        local tip
        local function hide() if tip then tip:Destroy() tip = nil end end
        inst.MouseEnter:Connect(function()
            hide()
            local ph = C.popupHolder(win)
            tip = new("Frame", { Parent = ph, BackgroundColor3 = win.Theme.Bg2, ZIndex = 140,
                Size = UDim2.fromOffset(0, 26), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1 })
            C.corner(tip, 6)
            C.stroke(tip, win.Theme.Stroke, 1, 0.2)
            C.pad(tip, 9, 9, 0, 0)
            C.txt(tip, text, 12, win.Theme.Text, Enum.Font.GothamMedium,
                { Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 141 })
            task.defer(function()
                if not tip or not tip.Parent then return end
                local vp = C.viewport()
                local w = tip.AbsoluteSize.X
                local ax = inst.AbsolutePosition.X + inst.AbsoluteSize.X / 2 - w / 2
                local ay = inst.AbsolutePosition.Y - 32
                ax = math.clamp(ax, 8, math.max(8, vp.X - w - 8))
                if ay < C.insetTop() then ay = inst.AbsolutePosition.Y + inst.AbsoluteSize.Y + 6 end
                tip.Position = UDim2.fromOffset(ax, ay)
                C.tw(tip, 0.12, { BackgroundTransparency = 0 })
            end)
        end)
        inst.MouseLeave:Connect(hide)
        inst.AncestryChanged:Connect(function(_, parent) if not parent then hide() end end)
    end

    C.keyName = {
        [Enum.UserInputType.MouseButton1] = "MouseLeft",
        [Enum.UserInputType.MouseButton2] = "MouseRight",
        [Enum.UserInputType.MouseButton3] = "MouseMiddle",
    }
    function C.keyFromInput(i)
        if i.KeyCode and i.KeyCode ~= Enum.KeyCode.Unknown then return i.KeyCode.Name end
        return C.keyName[i.UserInputType]
    end
    function C.keyMatches(i, name)
        if name == "None" or not name then return false end
        return (i.KeyCode ~= Enum.KeyCode.Unknown and i.KeyCode.Name == name) or C.keyName[i.UserInputType] == name
    end

    function C.nextOrd(page)
        local n = page:GetAttribute("ord") or 0
        page:SetAttribute("ord", n + 1)
        return n
    end
    function C.accentBar(win, f, x)
        local bar = new("Frame", { Parent = f, Size = UDim2.new(0, 3, 0, 0), AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, x or 0, 0.5, 0), BackgroundColor3 = win.Theme.Accent, BackgroundTransparency = 1,
            BorderSizePixel = 0, ZIndex = 4 })
        C.corner(bar, 2)
        win:paint(bar, "BackgroundColor3", "Accent")
        return bar
    end
    function C.mkCard(win, page, h, static)
        local flat = page:GetAttribute("bpuiFlat") == true
        local ord = C.nextOrd(page)
        local f = new("Frame", { Parent = page, Size = UDim2.new(1, 0, 0, h or 46), BackgroundColor3 = win.Theme.Panel,
            LayoutOrder = ord, BorderSizePixel = 0 })
        if flat then
            C.corner(f, 8)
            f.BackgroundColor3 = win.Theme.Hover
            f.BackgroundTransparency = 1
            f:SetAttribute("bpuiBaseT", 1)
            win:paint(f, "BackgroundColor3", "Hover")
            if not static then
                local bar = C.accentBar(win, f, 5)
                C.hoverable(f, function()
                    C.tw(f, 0.16, { BackgroundTransparency = 0.85 })
                    C.tw(bar, 0.18, { Size = UDim2.new(0, 3, 0, math.max(14, f.AbsoluteSize.Y - 16)), BackgroundTransparency = 0 })
                end, function()
                    C.tw(f, 0.18, { BackgroundTransparency = 1 })
                    C.tw(bar, 0.2, { Size = UDim2.new(0, 3, 0, 0), BackgroundTransparency = 1 })
                end)
            end
            return f
        end
        C.corner(f, 8)
        f.BackgroundTransparency = 0
        f:SetAttribute("bpuiBaseT", 0)
        local s = C.fluentStroke(f, win.Theme.Stroke, 0)
        win:paint(f, "BackgroundColor3", "Panel")
        win:paint(s, "Color", "Stroke")
        if not static then
            local bar = C.accentBar(win, f, 0)
            C.hoverable(f, function()
                C.tw(f, 0.16, { BackgroundColor3 = win.Theme.Panel2 })
                C.tw(s, 0.16, { Color = win.Theme.Accent, Transparency = 0.35 })
                C.tw(bar, 0.18, { Size = UDim2.new(0, 3, 0, math.max(16, f.AbsoluteSize.Y - 14)), BackgroundTransparency = 0 })
            end, function()
                C.tw(f, 0.18, { BackgroundColor3 = win.Theme.Panel })
                C.tw(s, 0.18, { Color = win.Theme.Stroke, Transparency = 0 })
                C.tw(bar, 0.2, { Size = UDim2.new(0, 3, 0, 0), BackgroundTransparency = 1 })
            end)
        end
        return f
    end
    function C.titleBlock(win, card, title, desc, rightInset)
        local hasD = desc ~= nil and desc ~= ""
        local holder = new("Frame", { Parent = card, BackgroundTransparency = 1,
            Name = "BPUI_Title", Size = UDim2.new(1, -(rightInset or 120), 1, 0), Position = UDim2.fromOffset(16, 0) })
        holder:SetAttribute("bpuiRightInset", rightInset or 120)
        local t = C.txt(holder, title, 14, win.Theme.Text, Enum.Font.GothamMedium,
            { Size = UDim2.new(1, 0, 1, 0), TextYAlignment = Enum.TextYAlignment.Center, TextTruncate = Enum.TextTruncate.AtEnd })
        win:paint(t, "TextColor3", "Text")
        if hasD then
            t.Size = UDim2.new(1, 0, 0, 18) t.Position = UDim2.fromOffset(0, 6) t.TextYAlignment = Enum.TextYAlignment.Top
            local d = C.txt(holder, desc, 12, win.Theme.Sub, Enum.Font.Gotham,
                { Size = UDim2.new(1, 0, 0, 16), Position = UDim2.fromOffset(0, 24), TextTruncate = Enum.TextTruncate.AtEnd })
            win:paint(d, "TextColor3", "Sub")
        end
        return t
    end
    function C.bindRight(card, control, opts)
        opts = opts or {}
        local normalSize = control.Size
        local normalPos = control.Position
        local normalAnchor = control.AnchorPoint
        local okAuto, normalAuto = pcall(function() return control.AutomaticSize end)
        local normalH = opts.normalHeight or card.Size.Y.Offset
        local compactH = opts.compactHeight or (normalH + 40)
        local minWidth = opts.minWidth or 430
        local controlH = opts.controlHeight or math.max(28, normalSize.Y.Offset)
        local rightInset = opts.rightInset or 120
        local title = card:FindFirstChild("BPUI_Title")
        local function apply()
            if not (card.Parent and control.Parent) then return end
            local w = card.AbsoluteSize.X
            local compact = w > 0 and w < minWidth
            if compact then
                card.Size = UDim2.new(1, 0, 0, compactH)
                control.AnchorPoint = Vector2.new(0, 0)
                control.Position = UDim2.new(0, 14, 1, -(controlH + 10))
                if opts.fill == false then
                    control.Size = UDim2.fromOffset(math.min(normalSize.X.Offset, math.max(80, w - 28)), controlH)
                else
                    if okAuto then pcall(function() control.AutomaticSize = Enum.AutomaticSize.None end) end
                    control.Size = UDim2.new(1, -28, 0, controlH)
                end
                if title then title.Size = UDim2.new(1, -32, 0, math.max(30, compactH - controlH - 12)) end
            else
                if okAuto then pcall(function() control.AutomaticSize = normalAuto end) end
                card.Size = UDim2.new(1, 0, 0, normalH)
                control.AnchorPoint = normalAnchor
                control.Position = normalPos
                control.Size = normalSize
                if title then title.Size = UDim2.new(1, -rightInset, 1, 0) end
            end
        end
        local cn = card:GetPropertyChangedSignal("AbsoluteSize"):Connect(apply)
        card.AncestryChanged:Connect(function(_, parent) if not parent then pcall(function() cn:Disconnect() end) end end)
        task.defer(apply)
        return cn
    end

    function C.makeToggleable(win, comp)
        local card = comp.Instance
        if not card or comp.SetEnabled then return end
        comp._enabled = true
        local enabled, shown, cover = true, true, nil
        function comp:SetEnabled(v)
            v = v ~= false
            comp._enabled = v
            if v == enabled then return end
            enabled = v
            if not v then
                if not cover then
                    cover = C.new("TextButton", { Parent = card, BackgroundColor3 = win.Theme.Bg, BorderSizePixel = 0,
                        BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = (card.ZIndex or 1) + 30,
                        Active = true, AutoButtonColor = false, Text = "", Modal = false, Selectable = false })
                    C.corner(cover, 8)
                    win:paint(cover, "BackgroundColor3", "Bg")
                    cover.InputBegan:Connect(function() end)
                end
                cover.Visible = true
                C.tw(cover, 0.15, { BackgroundTransparency = 0.5 })
            elseif cover then
                local c = cover
                C.tw(c, 0.15, { BackgroundTransparency = 1 })
                task.delay(0.16, function() if enabled and c then c.Visible = false end end)
            end
        end
        function comp:IsEnabled() return enabled end
        function comp:SetVisible(v)
            v = v ~= false
            shown = v
            card.Visible = v
        end
        function comp:IsVisible() return shown end
    end

    function C.popupHolder(win)
        if win._popups and win._popups.Parent then return win._popups end
        win._popups = new("Frame", { Parent = win.gui, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 100 })
        return win._popups
    end
    function C.placePopup(anchor, w, h)
        local vp = C.viewport()
        local px = anchor.AbsolutePosition.X
        local py = anchor.AbsolutePosition.Y + anchor.AbsoluteSize.Y + 4
        px = math.clamp(px, 8, math.max(8, vp.X - w - 8))
        if py + h > vp.Y - 8 then py = anchor.AbsolutePosition.Y - h - 4 end
        py = math.max(C.insetTop(), py)
        return px, py
    end

    local b64c = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    function C.b64encode(data)
        return ((data:gsub(".", function(x)
            local r, b = "", x:byte()
            for i = 8, 1, -1 do r = r .. (b % 2 ^ i - b % 2 ^ (i - 1) > 0 and "1" or "0") end
            return r
        end) .. "0000"):gsub("%d%d%d?%d?%d?%d?", function(x)
            if #x < 6 then return "" end
            local c = 0
            for i = 1, 6 do c = c + (x:sub(i, i) == "1" and 2 ^ (6 - i) or 0) end
            return b64c:sub(c + 1, c + 1)
        end) .. ({ "", "==", "=" })[#data % 3 + 1])
    end
    function C.b64decode(data)
        data = data:gsub("[^" .. b64c .. "=]", "")
        return (data:gsub(".", function(x)
            if x == "=" then return "" end
            local r, f = "", (b64c:find(x, 1, true) - 1)
            for i = 6, 1, -1 do r = r .. (f % 2 ^ i - f % 2 ^ (i - 1) > 0 and "1" or "0") end
            return r
        end):gsub("%d%d%d?%d?%d?%d?%d?%d?", function(x)
            if #x ~= 8 then return "" end
            local c = 0
            for i = 1, 8 do c = c + (x:sub(i, i) == "1" and 2 ^ (8 - i) or 0) end
            return string.char(c)
        end))
    end

    local Maid = {}
    Maid.__index = Maid
    function Maid.new() return setmetatable({ _t = {} }, Maid) end
    function Maid:give(x) self._t[#self._t + 1] = x return x end
    function Maid:clean()
        for _, x in ipairs(self._t) do
            pcall(function()
                if typeof(x) == "RBXScriptConnection" then x:Disconnect()
                elseif typeof(x) == "Instance" then x:Destroy()
                elseif type(x) == "table" and x.Remove then x:Remove()
                elseif type(x) == "table" and x.Destroy then x:Destroy()
                elseif type(x) == "thread" then task.cancel(x)
                elseif type(x) == "function" then x() end
            end)
        end
        table.clear(self._t)
    end
    C.Maid = Maid

    return C
end
