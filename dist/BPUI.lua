return (function()
local BPUI = {}
local M, C, L = {}, {}, {}
local function use(name)
    if not L[name] then
        local f = M[name]
        if not f then error("BPUI bundle missing module: " .. name) end
        L[name] = true
        C[name] = f(use, BPUI)
    end
    return C[name]
end
M["core"] = function(use, BPUI)
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
M["theme"] = function(use, BPUI)
    local Palette = {
        Bg = Color3.fromRGB(32, 32, 32),
        Bg2 = Color3.fromRGB(43, 43, 43),
        Panel = Color3.fromRGB(45, 45, 45),
        Panel2 = Color3.fromRGB(53, 53, 53),
        Hover = Color3.fromRGB(60, 60, 60),
        Stroke = Color3.fromRGB(72, 72, 72),
        Text = Color3.fromRGB(255, 255, 255),
        Sub = Color3.fromRGB(199, 199, 199),
        Dim = Color3.fromRGB(140, 140, 140),
        Good = Color3.fromRGB(108, 203, 95),
        Bad = Color3.fromRGB(255, 99, 99),
        Warn = Color3.fromRGB(252, 225, 0),
        OnAccent = Color3.fromRGB(0, 0, 0),
    }
    local Accents = {
        Default = Color3.fromRGB(76, 194, 255),
        Blue = Color3.fromRGB(76, 194, 255),
        Teal = Color3.fromRGB(48, 196, 196),
        Green = Color3.fromRGB(108, 203, 95),
        Purple = Color3.fromRGB(155, 122, 230),
        Magenta = Color3.fromRGB(214, 122, 214),
        Orange = Color3.fromRGB(255, 140, 70),
        Amber = Color3.fromRGB(255, 185, 48),
        Red = Color3.fromRGB(255, 99, 99),
        Pink = Color3.fromRGB(255, 121, 198),
        Slate = Color3.fromRGB(150, 168, 196),
        Midnight = Color3.fromRGB(139, 101, 255),
    }

    BPUI.Palette = Palette
    BPUI.Accents = Accents
    BPUI.Themes = {
        Light = {
            Bg = Color3.fromRGB(243, 243, 243),
            Bg2 = Color3.fromRGB(251, 251, 251),
            Panel = Color3.fromRGB(255, 255, 255),
            Panel2 = Color3.fromRGB(246, 246, 246),
            Hover = Color3.fromRGB(237, 237, 237),
            Stroke = Color3.fromRGB(225, 225, 225),
            Text = Color3.fromRGB(26, 26, 26),
            Sub = Color3.fromRGB(95, 95, 95),
            Dim = Color3.fromRGB(140, 140, 140),
        },
        Oled = {
            Bg = Color3.fromRGB(0, 0, 0),
            Bg2 = Color3.fromRGB(0, 0, 0),
            Panel = Color3.fromRGB(13, 13, 16),
            Panel2 = Color3.fromRGB(22, 22, 27),
            Hover = Color3.fromRGB(30, 30, 36),
            Stroke = Color3.fromRGB(40, 40, 48),
        },
    }
    function BPUI:AddTheme(name, palette) self.Themes[name] = palette return self end
    function BPUI:AddAccent(name, color) self.Accents[name] = color return self end

    local T = { Palette = Palette, Accents = Accents }
    function T.resolve(o)
        local theme = {}
        for k, v in pairs(Palette) do theme[k] = v end
        theme.Accent = Accents.Default
        if type(o.Theme) == "string" then
            if BPUI.Themes[o.Theme] then for k, v in pairs(BPUI.Themes[o.Theme]) do theme[k] = v end
            elseif Accents[o.Theme] then theme.Accent = Accents[o.Theme] end
        elseif type(o.Theme) == "table" then
            for k, v in pairs(o.Theme) do theme[k] = v end
        end
        if type(o.Palette) == "table" then for k, v in pairs(o.Palette) do theme[k] = v end end
        if typeof(o.Accent) == "Color3" then theme.Accent = o.Accent
        elseif type(o.Accent) == "string" and Accents[o.Accent] then theme.Accent = Accents[o.Accent] end
        return theme
    end
    function T.apply(theme, arg)
        if type(arg) == "string" then
            if BPUI.Themes[arg] then
                local accent = theme.Accent
                for k, v in pairs(Palette) do theme[k] = v end
                theme.Accent = accent
                for k, v in pairs(BPUI.Themes[arg]) do theme[k] = v end
                return arg
            elseif Accents[arg] then theme.Accent = Accents[arg] return arg end
        elseif type(arg) == "table" then
            for k, v in pairs(arg) do theme[k] = v end
        elseif typeof(arg) == "Color3" then
            theme.Accent = arg
        end
    end
    return T
end
M["icons"] = function(use, BPUI)
    local Core = use("core")
    local new, txt = Core.new, Core.txt

    local Icons = {}

    local function vseg(h, x1, y1, x2, y2, th)
        th = th or 2.2
        local dx, dy = x2 - x1, y2 - y1
        local len = math.sqrt(dx * dx + dy * dy)
        local f = new("Frame", { Parent = h, AnchorPoint = Vector2.new(0.5, 0.5), BorderSizePixel = 0,
            Position = UDim2.fromScale((x1 + x2) / 48, (y1 + y2) / 48), Size = UDim2.new(len / 24, 0, 0, th),
            Rotation = math.deg(math.atan2(dy, dx)), BackgroundColor3 = Color3.new(1, 1, 1) })
        new("UICorner", { Parent = f, CornerRadius = UDim.new(1, 0) })
        return f
    end
    local function vdot(h, cx, cy, d)
        local f = new("Frame", { Parent = h, AnchorPoint = Vector2.new(0.5, 0.5), BorderSizePixel = 0,
            Position = UDim2.fromScale(cx / 24, cy / 24), Size = UDim2.fromScale(d / 24, d / 24), BackgroundColor3 = Color3.new(1, 1, 1) })
        new("UICorner", { Parent = f, CornerRadius = UDim.new(1, 0) })
        return f
    end
    local function vring(h, cx, cy, d, th)
        local f = new("Frame", { Parent = h, AnchorPoint = Vector2.new(0.5, 0.5), BorderSizePixel = 0,
            Position = UDim2.fromScale(cx / 24, cy / 24), Size = UDim2.fromScale(d / 24, d / 24), BackgroundTransparency = 1 })
        new("UICorner", { Parent = f, CornerRadius = UDim.new(1, 0) })
        new("UIStroke", { Parent = f, Thickness = th or 2.2, Color = Color3.new(1, 1, 1) })
        return f
    end
    local function vbox(h, x, y, w, hh, r, th)
        local f = new("Frame", { Parent = h, BorderSizePixel = 0, Position = UDim2.fromScale(x / 24, y / 24),
            Size = UDim2.fromScale(w / 24, hh / 24), BackgroundTransparency = 1 })
        new("UICorner", { Parent = f, CornerRadius = UDim.new(0, r or 3) })
        new("UIStroke", { Parent = f, Thickness = th or 2.2, Color = Color3.new(1, 1, 1) })
        return f
    end
    local function vfill(h, x, y, w, hh, r)
        local f = new("Frame", { Parent = h, BorderSizePixel = 0, Position = UDim2.fromScale(x / 24, y / 24),
            Size = UDim2.fromScale(w / 24, hh / 24), BackgroundColor3 = Color3.new(1, 1, 1) })
        new("UICorner", { Parent = f, CornerRadius = UDim.new(0, r or 2) })
        return f
    end
    local function varc(h, cx, cy, r, a1, a2, th)
        local steps = 11
        local px, py
        for i = 0, steps do
            local a = math.rad(a1 + (a2 - a1) * i / steps)
            local x, y = cx + math.cos(a) * r, cy + math.sin(a) * r
            if px then vseg(h, px, py, x, y, th or 2.4) end
            px, py = x, y
        end
    end

    local V = {}
    function V.home(h) vseg(h, 3, 12, 12, 4) vseg(h, 12, 4, 21, 12) vseg(h, 5, 11, 5, 20) vseg(h, 19, 11, 19, 20) vseg(h, 5, 20, 19, 20) vseg(h, 10, 20, 10, 15) vseg(h, 14, 20, 14, 15) vseg(h, 10, 15, 14, 15) end
    function V.settings(h) vring(h, 12, 12, 9, 2.2) vring(h, 12, 12, 3.6, 2.2) for i = 0, 7 do local a = i * math.pi / 4 vseg(h, 12 + math.cos(a) * 8, 12 + math.sin(a) * 8, 12 + math.cos(a) * 11.5, 12 + math.sin(a) * 11.5, 2.8) end end
    function V.sliders(h) vseg(h, 4, 8, 20, 8, 2.2) vdot(h, 15, 8, 5) vseg(h, 4, 16, 20, 16, 2.2) vdot(h, 9, 16, 5) end
    function V.stats(h) vfill(h, 4.5, 12, 3.4, 7, 1) vfill(h, 10.3, 8, 3.4, 11, 1) vfill(h, 16.1, 5, 3.4, 14, 1) end
    function V.user(h, clip) clip() vring(h, 12, 8, 7, 2.2) vbox(h, 4, 16, 16, 13, 8, 2.2) end
    function V.users(h, clip) clip() vring(h, 9, 8.5, 6, 2.1) vbox(h, 2.5, 15, 13, 12, 7, 2.1) vring(h, 17, 8, 4.6, 2) vseg(h, 17, 14, 21.5, 14, 2) vseg(h, 21.5, 14, 21.5, 18, 2) end
    function V.search(h) vring(h, 10, 10, 7, 2.4) vseg(h, 15, 15, 20, 20, 2.6) end
    function V.close(h) vseg(h, 6, 6, 18, 18, 2.6) vseg(h, 18, 6, 6, 18, 2.6) end
    function V.check(h) vseg(h, 5, 13, 10, 18, 2.8) vseg(h, 10, 18, 19, 6, 2.8) end
    function V.plus(h) vseg(h, 12, 5, 12, 19, 2.6) vseg(h, 5, 12, 19, 12, 2.6) end
    function V.minus(h) vseg(h, 5, 12, 19, 12, 2.6) end
    function V.menu(h) vseg(h, 4, 7, 20, 7, 2.3) vseg(h, 4, 12, 20, 12, 2.3) vseg(h, 4, 17, 20, 17, 2.3) end
    function V.list(h) vdot(h, 4, 7, 2.4) vseg(h, 8, 7, 20, 7, 2.2) vdot(h, 4, 12, 2.4) vseg(h, 8, 12, 20, 12, 2.2) vdot(h, 4, 17, 2.4) vseg(h, 8, 17, 20, 17, 2.2) end
    function V.grid(h) vbox(h, 4, 4, 7, 7, 2, 2) vbox(h, 13, 4, 7, 7, 2, 2) vbox(h, 4, 13, 7, 7, 2, 2) vbox(h, 13, 13, 7, 7, 2, 2) end
    function V.chevron(h) vseg(h, 9, 5, 16, 12, 2.6) vseg(h, 16, 12, 9, 19, 2.6) end
    function V.chevrondown(h) vseg(h, 5, 9, 12, 16, 2.6) vseg(h, 12, 16, 19, 9, 2.6) end
    function V.chevronup(h) vseg(h, 5, 15, 12, 8, 2.6) vseg(h, 12, 8, 19, 15, 2.6) end
    function V.chevronleft(h) vseg(h, 15, 5, 8, 12, 2.6) vseg(h, 8, 12, 15, 19, 2.6) end
    function V.arrow(h) vseg(h, 4, 12, 20, 12, 2.6) vseg(h, 13, 5, 20, 12, 2.6) vseg(h, 20, 12, 13, 19, 2.6) end
    function V.refresh(h) varc(h, 12, 12, 8, -55, 205, 2.5) vseg(h, 16, 4.5, 18.6, 8.2, 2.5) vseg(h, 18.6, 8.2, 14.3, 9, 2.5) end
    function V.power(h) varc(h, 12, 13, 8.4, -65, 245, 2.6) vseg(h, 12, 3, 12, 11.5, 2.8) end
    function V.trash(h) vseg(h, 4, 7, 20, 7, 2.4) vseg(h, 9, 7, 9.5, 4, 2.2) vseg(h, 9.5, 4, 14.5, 4, 2.2) vseg(h, 14.5, 4, 15, 7, 2.2) vbox(h, 6, 8, 12, 13, 2, 2.2) vseg(h, 10, 11, 10, 18, 2) vseg(h, 14, 11, 14, 18, 2) end
    function V.edit(h) vseg(h, 5, 19, 16, 8, 3) vseg(h, 16, 8, 18.5, 10.5, 3) vdot(h, 5.2, 18.8, 2.4) vfill(h, 15.5, 5, 4, 4, 1) end
    function V.save(h) vbox(h, 4, 4, 16, 16, 2, 2.2) vfill(h, 7.5, 4, 9, 6, 1) vbox(h, 8, 13, 8, 7, 1, 2) end
    function V.info(h) vring(h, 12, 12, 18, 2.2) vdot(h, 12, 7.6, 2.4) vseg(h, 12, 11, 12, 17, 2.4) end
    function V.warning(h) vseg(h, 12, 4, 21, 20, 2.4) vseg(h, 21, 20, 3, 20, 2.4) vseg(h, 3, 20, 12, 4, 2.4) vdot(h, 12, 17, 2.2) vseg(h, 12, 9, 12, 14, 2.4) end
    function V.lock(h) vbox(h, 8, 4, 8, 8, 4, 2.2) vfill(h, 5, 11, 14, 10, 2.5) end
    function V.eye(h) vseg(h, 3, 12, 9, 8, 2.4) vseg(h, 9, 8, 15, 8, 2.4) vseg(h, 15, 8, 21, 12, 2.4) vseg(h, 21, 12, 15, 16, 2.4) vseg(h, 15, 16, 9, 16, 2.4) vseg(h, 9, 16, 3, 12, 2.4) vring(h, 12, 12, 5, 2.2) end
    function V.star(h) local pts = {} for i = 0, 9 do local r = (i % 2 == 0) and 9 or 4 local a = -math.pi / 2 + i * math.pi / 5 pts[#pts + 1] = { 12 + math.cos(a) * r, 12 + math.sin(a) * r } end for i = 1, 10 do local p, q = pts[i], pts[i % 10 + 1] vseg(h, p[1], p[2], q[1], q[2], 2.2) end end
    function V.heart(h) vring(h, 8.5, 9, 5, 2.4) vring(h, 15.5, 9, 5, 2.4) vseg(h, 4.6, 11, 12, 20, 2.5) vseg(h, 19.4, 11, 12, 20, 2.5) end
    function V.shield(h) vseg(h, 12, 3, 20, 6, 2.4) vseg(h, 20, 6, 20, 12, 2.4) vseg(h, 20, 12, 12, 21, 2.4) vseg(h, 12, 21, 4, 12, 2.4) vseg(h, 4, 12, 4, 6, 2.4) vseg(h, 4, 6, 12, 3, 2.4) end
    function V.shieldcheck(h) V.shield(h) vseg(h, 8.5, 12, 11, 14.5, 2.4) vseg(h, 11, 14.5, 15.5, 9, 2.4) end
    function V.box(h) vbox(h, 4, 6, 16, 14, 2, 2.2) vseg(h, 4, 10, 20, 10, 2.2) vseg(h, 12, 6, 12, 10, 2.2) end
    function V.layers(h) vseg(h, 12, 3, 20, 8, 2.4) vseg(h, 20, 8, 12, 13, 2.4) vseg(h, 12, 13, 4, 8, 2.4) vseg(h, 4, 8, 12, 3, 2.4) vseg(h, 4, 13, 12, 18, 2.4) vseg(h, 12, 18, 20, 13, 2.4) end
    function V.image(h) vbox(h, 4, 4, 16, 16, 3, 2.2) vdot(h, 9, 9, 3) vseg(h, 5.5, 18, 11, 12, 2.2) vseg(h, 11, 12, 20, 19, 2.2) end
    function V.palette(h) vring(h, 12, 12, 18, 2.2) vdot(h, 8, 8, 2.6) vdot(h, 14, 7, 2.6) vdot(h, 17, 12, 2.6) vdot(h, 9, 16.5, 2.6) end
    function V.bell(h) vbox(h, 7, 5, 10, 12, 5, 2.2) vseg(h, 5, 17, 19, 17, 2.4) vdot(h, 12, 20, 2.6) end
    function V.code(h) vseg(h, 9, 7, 4, 12, 2.4) vseg(h, 4, 12, 9, 17, 2.4) vseg(h, 15, 7, 20, 12, 2.4) vseg(h, 20, 12, 15, 17, 2.4) vseg(h, 14, 5, 10, 19, 2.2) end
    function V.terminal(h) vbox(h, 3, 5, 18, 14, 2, 2.2) vseg(h, 7, 10, 10, 12.5, 2.2) vseg(h, 10, 12.5, 7, 15, 2.2) vseg(h, 12, 15, 17, 15, 2.2) end
    function V.globe(h) vring(h, 12, 12, 18, 2.2) vseg(h, 3, 12, 21, 12, 2) vring(h, 12, 12, 9, 2) vseg(h, 12, 3, 12, 21, 2) end
    function V.link(h) vbox(h, 3, 9, 9, 6, 3, 2.4) vbox(h, 12, 9, 9, 6, 3, 2.4) vseg(h, 8, 12, 16, 12, 2.4) end
    function V.filter(h) vseg(h, 4, 5, 20, 5, 2.4) vseg(h, 4.5, 5.5, 11, 13, 2.4) vseg(h, 19.5, 5.5, 13, 13, 2.4) vseg(h, 11, 13, 11, 19, 2.4) vseg(h, 13, 13, 13, 16.5, 2.4) end
    function V.copy(h) vbox(h, 4, 4, 12, 12, 2, 2.2) vbox(h, 9, 9, 11, 11, 2, 2.2) end
    function V.play(h) vseg(h, 7, 4.5, 7, 19.5, 2.6) vseg(h, 7, 4.5, 19, 12, 2.6) vseg(h, 7, 19.5, 19, 12, 2.6) end
    function V.pause(h) vfill(h, 7, 5, 3.6, 14, 1) vfill(h, 13.4, 5, 3.6, 14, 1) end
    function V.download(h) vseg(h, 12, 3, 12, 15, 2.6) vseg(h, 7, 11, 12, 16, 2.6) vseg(h, 17, 11, 12, 16, 2.6) vseg(h, 5, 19.5, 19, 19.5, 2.4) end
    function V.upload(h) vseg(h, 12, 3, 12, 15, 2.6) vseg(h, 7, 8, 12, 3, 2.6) vseg(h, 17, 8, 12, 3, 2.6) vseg(h, 5, 19.5, 19, 19.5, 2.4) end
    function V.spark(h) vseg(h, 13, 3, 6, 13, 2.6) vseg(h, 6, 13, 12, 13, 2.6) vseg(h, 12, 13, 11, 21, 2.6) vseg(h, 11, 21, 18, 11, 2.6) vseg(h, 18, 11, 12, 11, 2.6) vseg(h, 12, 11, 13, 3, 2.6) end
    function V.key(h) vring(h, 8, 16, 7, 2.4) vseg(h, 11, 13, 20, 4, 2.6) vseg(h, 17, 7, 19.5, 9.5, 2.2) vseg(h, 14, 10, 16, 12, 2.2) end
    function V.gift(h) vbox(h, 4.5, 10, 15, 11, 2, 2.2) vfill(h, 4, 7, 16, 4, 1) vseg(h, 12, 7, 12, 21, 2.2) vring(h, 9, 5.5, 4, 2) vring(h, 15, 5.5, 4, 2) end
    function V.trophy(h) vbox(h, 7, 4, 10, 9, 3, 2.4) vseg(h, 7, 6, 4, 6, 2.2) vseg(h, 4, 6, 4.5, 9.5, 2.2) vseg(h, 4.5, 9.5, 7.5, 11, 2.2) vseg(h, 17, 6, 20, 6, 2.2) vseg(h, 20, 6, 19.5, 9.5, 2.2) vseg(h, 19.5, 9.5, 16.5, 11, 2.2) vseg(h, 12, 13, 12, 17, 2.4) vseg(h, 8, 19, 16, 19, 2.6) end
    function V.clock(h) vring(h, 12, 12, 18, 2.2) vseg(h, 12, 12, 12, 7, 2.2) vseg(h, 12, 12, 16, 13, 2.2) end
    function V.calendar(h) vbox(h, 4, 5, 16, 16, 2, 2.2) vseg(h, 4, 9.5, 20, 9.5, 2.2) vseg(h, 8, 3, 8, 7, 2.2) vseg(h, 16, 3, 16, 7, 2.2) end
    function V.target(h) vring(h, 12, 12, 18, 2.2) vring(h, 12, 12, 9, 2.2) vdot(h, 12, 12, 2.6) end
    function V.folder(h) vfill(h, 3, 6, 8, 4, 2) vbox(h, 3, 8, 18, 12, 2, 2.2) end
    function V.bag(h) vbox(h, 5, 8, 14, 13, 3, 2.2) vseg(h, 8.5, 8, 8.5, 5.5, 2.2) vseg(h, 8.5, 5.5, 15.5, 5.5, 2.2) vseg(h, 15.5, 5.5, 15.5, 8, 2.2) end
    function V.gamepad(h) vbox(h, 3, 8, 18, 9, 4, 2.4) vseg(h, 7, 12.5, 9.5, 12.5, 2.2) vseg(h, 8.25, 11.25, 8.25, 13.75, 2.2) vdot(h, 15, 11.5, 2.2) vdot(h, 17, 13.5, 2.2) end
    function V.map(h) vbox(h, 4, 5, 16, 15, 1, 2.2) vseg(h, 9, 5, 9, 20, 2) vseg(h, 15, 5, 15, 20, 2) end
    function V.sun(h) vring(h, 12, 12, 9, 2.4) for i = 0, 7 do local a = i * math.pi / 4 vseg(h, 12 + math.cos(a) * 7, 12 + math.sin(a) * 7, 12 + math.cos(a) * 10.5, 12 + math.sin(a) * 10.5, 2.4) end end
    function V.moon(h) varc(h, 12, 12, 9, 50, 310, 2.4) varc(h, 14.5, 12, 6.5, 58, 302, 2.4) vseg(h, 13.8, 4.85, 16.68, 6.45, 2.4) vseg(h, 13.8, 19.15, 16.68, 17.55, 2.4) end
    function V.leaf(h) vseg(h, 5, 19, 18, 6, 2.4) vseg(h, 5, 19, 7, 8, 2.4) vseg(h, 7, 8, 18, 6, 2.4) vseg(h, 18, 6, 16, 17, 2.4) vseg(h, 16, 17, 5, 19, 2.4) end
    function V.fire(h) varc(h, 12, 14.5, 7, 200, 340, 2.4) vseg(h, 5.4, 12.1, 12, 3, 2.4) vseg(h, 18.6, 12.1, 12, 3, 2.4) varc(h, 12, 16, 3.4, 195, 345, 2.2) vseg(h, 8.7, 15.1, 12, 10, 2.2) vseg(h, 15.3, 15.1, 12, 10, 2.2) end
    function V.tag(h) vseg(h, 4, 4, 12, 4, 2.4) vseg(h, 4, 4, 4, 12, 2.4) vseg(h, 4, 12, 13, 21, 2.4) vseg(h, 13, 21, 21, 13, 2.4) vseg(h, 21, 13, 12, 4, 2.4) vdot(h, 8, 8, 2.6) end
    function V.pin(h) vring(h, 12, 9, 9, 2.4) vdot(h, 12, 9, 3) vseg(h, 12, 14, 12, 21, 2.4) end
    function V.coin(h) vring(h, 12, 12, 18, 2.4) vseg(h, 12, 7, 12, 17, 2.4) vseg(h, 9.5, 9, 14, 9, 2.2) vseg(h, 10, 15, 14.5, 15, 2.2) end
    function V.heartbeat(h) vseg(h, 3, 12, 8, 12, 2.4) vseg(h, 8, 12, 10, 7, 2.4) vseg(h, 10, 7, 13, 17, 2.4) vseg(h, 13, 17, 15, 12, 2.4) vseg(h, 15, 12, 21, 12, 2.4) end
    function V.dot(h) vdot(h, 12, 12, 7) end
    function V.arrowup(h) vseg(h, 12, 20, 12, 4, 2.6) vseg(h, 5, 11, 12, 4, 2.6) vseg(h, 19, 11, 12, 4, 2.6) end
    function V.arrowdown(h) vseg(h, 12, 4, 12, 20, 2.6) vseg(h, 5, 13, 12, 20, 2.6) vseg(h, 19, 13, 12, 20, 2.6) end
    function V.arrowleft(h) vseg(h, 20, 12, 4, 12, 2.6) vseg(h, 11, 5, 4, 12, 2.6) vseg(h, 11, 19, 4, 12, 2.6) end
    function V.circle(h) vring(h, 12, 12, 18, 2.4) end
    function V.checkcircle(h) vring(h, 12, 12, 18, 2.2) vseg(h, 7.5, 12.5, 11, 16, 2.4) vseg(h, 11, 16, 16.5, 8.5, 2.4) end
    function V.xcircle(h) vring(h, 12, 12, 18, 2.2) vseg(h, 8.5, 8.5, 15.5, 15.5, 2.4) vseg(h, 15.5, 8.5, 8.5, 15.5, 2.4) end
    function V.pluscircle(h) vring(h, 12, 12, 18, 2.2) vseg(h, 12, 8, 12, 16, 2.4) vseg(h, 8, 12, 16, 12, 2.4) end
    function V.minuscircle(h) vring(h, 12, 12, 18, 2.2) vseg(h, 8, 12, 16, 12, 2.4) end
    function V.alertcircle(h) vring(h, 12, 12, 18, 2.2) vseg(h, 12, 7, 12, 13, 2.4) vdot(h, 12, 16.5, 2.2) end
    function V.bookmark(h) vseg(h, 6, 4, 18, 4, 2.4) vseg(h, 6, 4, 6, 20, 2.4) vseg(h, 18, 4, 18, 20, 2.4) vseg(h, 6, 20, 12, 15, 2.4) vseg(h, 12, 15, 18, 20, 2.4) end
    function V.flag(h) vseg(h, 6, 3, 6, 21, 2.4) vseg(h, 6, 4, 18, 4, 2.4) vseg(h, 18, 4, 18, 13, 2.4) vseg(h, 18, 13, 6, 13, 2.4) end
    function V.send(h) vseg(h, 21, 3, 3, 11, 2.4) vseg(h, 3, 11, 11, 13, 2.4) vseg(h, 11, 13, 13, 21, 2.4) vseg(h, 13, 21, 21, 3, 2.4) end
    function V.share(h) vring(h, 18, 5, 5, 2.2) vring(h, 6, 12, 5, 2.2) vring(h, 18, 19, 5, 2.2) vseg(h, 8.6, 10.6, 15.4, 6.4, 2.2) vseg(h, 8.6, 13.4, 15.4, 17.6, 2.2) end
    function V.externallink(h) vbox(h, 4, 8, 12, 12, 2, 2.2) vseg(h, 13, 5, 20, 5, 2.4) vseg(h, 20, 5, 20, 12, 2.4) vseg(h, 20, 5, 11, 14, 2.4) end
    function V.maximize(h) vseg(h, 4, 9, 4, 4, 2.4) vseg(h, 4, 4, 9, 4, 2.4) vseg(h, 15, 4, 20, 4, 2.4) vseg(h, 20, 4, 20, 9, 2.4) vseg(h, 20, 15, 20, 20, 2.4) vseg(h, 20, 20, 15, 20, 2.4) vseg(h, 9, 20, 4, 20, 2.4) vseg(h, 4, 20, 4, 15, 2.4) end
    function V.morehoriz(h) vdot(h, 5, 12, 2.8) vdot(h, 12, 12, 2.8) vdot(h, 19, 12, 2.8) end
    function V.morevert(h) vdot(h, 12, 5, 2.8) vdot(h, 12, 12, 2.8) vdot(h, 12, 19, 2.8) end
    function V.eyeoff(h) vseg(h, 3, 12, 9, 8, 2.4) vseg(h, 9, 8, 15, 8, 2.4) vseg(h, 15, 8, 21, 12, 2.4) vseg(h, 21, 12, 15, 16, 2.4) vseg(h, 15, 16, 9, 16, 2.4) vseg(h, 9, 16, 3, 12, 2.4) vring(h, 12, 12, 5, 2.2) vseg(h, 4, 4, 20, 20, 2.6) end
    function V.unlock(h) vfill(h, 5, 11, 14, 10, 2.5) vseg(h, 8, 11, 8, 8, 2.2) varc(h, 12, 8, 4, 180, 360, 2.2) end
    function V.belloff(h) vbox(h, 7, 5, 10, 12, 5, 2.2) vseg(h, 5, 17, 19, 17, 2.4) vdot(h, 12, 20, 2.6) vseg(h, 4, 4, 20, 20, 2.6) end
    function V.volume(h) vseg(h, 4, 10, 8, 10, 2.2) vseg(h, 8, 10, 12, 6, 2.2) vseg(h, 12, 6, 12, 18, 2.2) vseg(h, 12, 18, 8, 14, 2.2) vseg(h, 8, 14, 4, 14, 2.2) vseg(h, 4, 10, 4, 14, 2.2) varc(h, 13, 12, 4, -55, 55, 2) varc(h, 13, 12, 7, -55, 55, 2) end
    function V.volumex(h) vseg(h, 4, 10, 8, 10, 2.2) vseg(h, 8, 10, 12, 6, 2.2) vseg(h, 12, 6, 12, 18, 2.2) vseg(h, 12, 18, 8, 14, 2.2) vseg(h, 8, 14, 4, 14, 2.2) vseg(h, 4, 10, 4, 14, 2.2) vseg(h, 16, 9, 21, 14, 2.2) vseg(h, 21, 9, 16, 14, 2.2) end
    function V.mic(h) vbox(h, 9, 3, 6, 11, 3, 2.2) varc(h, 12, 12, 5, 0, 180, 2.2) vseg(h, 12, 17, 12, 21, 2.2) vseg(h, 9, 21, 15, 21, 2.2) end
    function V.camera(h) vbox(h, 3, 7, 18, 13, 2, 2.2) vring(h, 12, 13, 6, 2.2) vfill(h, 7, 5, 5, 3, 1) end
    function V.video(h) vbox(h, 3, 7, 12, 10, 2, 2.2) vseg(h, 15, 9, 20, 7, 2.2) vseg(h, 20, 7, 20, 17, 2.2) vseg(h, 20, 17, 15, 15, 2.2) vseg(h, 15, 9, 15, 15, 2.2) end
    function V.message(h) vbox(h, 3, 4, 18, 13, 3, 2.2) vseg(h, 7, 17, 7, 21, 2.2) vseg(h, 7, 21, 12, 17, 2.2) end
    function V.mail(h) vbox(h, 3, 5, 18, 14, 2, 2.2) vseg(h, 3.5, 6, 12, 13, 2.2) vseg(h, 12, 13, 20.5, 6, 2.2) end
    function V.phone(h) vbox(h, 7, 3, 10, 18, 3, 2.2) vseg(h, 10, 5, 14, 5, 2.2) vdot(h, 12, 18, 1.8) end
    function V.file(h) vseg(h, 6, 3, 15, 3, 2.4) vseg(h, 15, 3, 19, 7, 2.4) vseg(h, 19, 7, 19, 21, 2.4) vseg(h, 19, 21, 6, 21, 2.4) vseg(h, 6, 21, 6, 3, 2.4) vseg(h, 15, 3, 15, 7, 2.4) vseg(h, 15, 7, 19, 7, 2.4) end
    function V.filetext(h) V.file(h) vseg(h, 9, 11, 15, 11, 2) vseg(h, 9, 14, 15, 14, 2) vseg(h, 9, 17, 13, 17, 2) end
    function V.creditcard(h) vbox(h, 3, 6, 18, 12, 2, 2.2) vseg(h, 3, 10, 21, 10, 2.4) vseg(h, 6, 15, 10, 15, 2) end
    function V.logout(h) vseg(h, 13, 4, 5, 4, 2.4) vseg(h, 5, 4, 5, 20, 2.4) vseg(h, 5, 20, 13, 20, 2.4) vseg(h, 11, 12, 21, 12, 2.4) vseg(h, 17, 8, 21, 12, 2.4) vseg(h, 21, 12, 17, 16, 2.4) end
    function V.login(h) vseg(h, 11, 4, 19, 4, 2.4) vseg(h, 19, 4, 19, 20, 2.4) vseg(h, 19, 20, 11, 20, 2.4) vseg(h, 3, 12, 13, 12, 2.4) vseg(h, 9, 8, 13, 12, 2.4) vseg(h, 13, 12, 9, 16, 2.4) end
    function V.crosshair(h) vring(h, 12, 12, 16, 2.2) vseg(h, 12, 2, 12, 7, 2.2) vseg(h, 12, 17, 12, 22, 2.2) vseg(h, 2, 12, 7, 12, 2.2) vseg(h, 17, 12, 22, 12, 2.2) vdot(h, 12, 12, 2) end
    function V.award(h) vring(h, 12, 9, 9, 2.4) vseg(h, 9, 16, 7, 21, 2.4) vseg(h, 7, 21, 12, 18.5, 2.4) vseg(h, 12, 18.5, 17, 21, 2.4) vseg(h, 17, 21, 15, 16, 2.4) end
    function V.dice(h) vbox(h, 4, 4, 16, 16, 3, 2.2) vdot(h, 8.5, 8.5, 2.4) vdot(h, 15.5, 15.5, 2.4) vdot(h, 12, 12, 2.4) end
    function V.plug(h) vseg(h, 8, 3, 8, 9, 2.4) vseg(h, 16, 3, 16, 9, 2.4) vbox(h, 6, 9, 12, 6, 2, 2.4) vseg(h, 12, 15, 12, 21, 2.4) end
    function V.wifi(h) varc(h, 12, 17, 10, -145, -35, 2.4) varc(h, 12, 17, 6, -150, -30, 2.4) vdot(h, 12, 17, 2.6) end
    function V.signal(h) vfill(h, 4, 15, 3, 5, 1) vfill(h, 10.5, 11, 3, 9, 1) vfill(h, 17, 6, 3, 14, 1) end
    function V.rocket(h) vseg(h, 12, 3, 7.5, 12, 2.4) vseg(h, 12, 3, 16.5, 12, 2.4) vseg(h, 7.5, 12, 7.5, 16, 2.4) vseg(h, 16.5, 12, 16.5, 16, 2.4) vseg(h, 7.5, 16, 12, 20, 2.4) vseg(h, 16.5, 16, 12, 20, 2.4) vdot(h, 12, 9.5, 2.2) vseg(h, 7.5, 15, 4, 18, 2.2) vseg(h, 16.5, 15, 20, 18, 2.2) end
    function V.crown(h) vseg(h, 4, 19, 20, 19, 2.4) vseg(h, 4, 19, 4, 8, 2.4) vseg(h, 4, 8, 8, 12, 2.4) vseg(h, 8, 12, 12, 6, 2.4) vseg(h, 12, 6, 16, 12, 2.4) vseg(h, 16, 12, 20, 8, 2.4) vseg(h, 20, 8, 20, 19, 2.4) end
    function V.skull(h) varc(h, 12, 11, 9, 180, 360, 2.2) vseg(h, 3, 11, 3, 16, 2.2) vseg(h, 21, 11, 21, 16, 2.2) vseg(h, 3, 16, 8, 18, 2.2) vseg(h, 21, 16, 16, 18, 2.2) vseg(h, 8, 18, 8, 21, 2.2) vseg(h, 16, 18, 16, 21, 2.2) vseg(h, 8, 21, 16, 21, 2.2) vdot(h, 8.5, 12, 2.6) vdot(h, 15.5, 12, 2.6) end
    function V.sword(h) vseg(h, 4, 20, 6, 18, 2.4) vseg(h, 6, 19, 17, 8, 2.6) vseg(h, 16, 4, 20, 8, 2.4) vseg(h, 17, 7, 20, 4, 2.4) vseg(h, 13, 11, 17, 15, 2.4) vseg(h, 5, 17, 7, 19, 2.2) end
    function V.dollar(h) vseg(h, 12, 3, 12, 21, 2.4) varc(h, 12, 8.5, 4.5, -20, 200, 2.4) varc(h, 12, 15.5, 4.5, 160, 380, 2.4) end
    function V.percent(h) vring(h, 7.5, 7.5, 5, 2.2) vring(h, 16.5, 16.5, 5, 2.2) vseg(h, 18, 5, 6, 19, 2.6) end

    V.x = V.close V.cross = V.close V.gear = V.settings V.cog = V.settings V.controls = V.sliders
    V.chart = V.stats V.magic = V.spark V.bolt = V.spark V.zap = V.spark V.flash = V.spark
    V.chevronright = V.chevron V["chevron-right"] = V.chevron V["chevron-down"] = V.chevrondown
    V["chevron-up"] = V.chevronup V["chevron-left"] = V.chevronleft V.arrowright = V.arrow
    V.player = V.user V.account = V.user V.profile = V.user V.team = V.users V.shop = V.bag
    V.cart = V.bag V.money = V.coin V.gem = V.spark V.flame = V.fire V.clean = V.refresh
    V.reload = V.refresh V.sync = V.refresh V.delete = V.trash V.remove = V.trash V.add = V.plus
    V.config = V.settings V.tools = V.settings V.wrench = V.settings V.heart_pulse = V.heartbeat
    V.activity = V.heartbeat V.location = V.pin V.label = V.tag V.health = V.heart
    V["arrow-up"] = V.arrowup V["arrow-down"] = V.arrowdown V["arrow-left"] = V.arrowleft
    V.up = V.arrowup V.down = V.arrowdown V.left = V.arrowleft V.right = V.arrow
    V.success = V.checkcircle V.error = V.xcircle V.alert = V.alertcircle V.warn = V.warning
    V["check-circle"] = V.checkcircle V["x-circle"] = V.xcircle V["alert-circle"] = V.alertcircle
    V.notification = V.bell V.notify = V.bell V.more = V.morehoriz V.dots = V.morehoriz
    V.kebab = V.morevert V.menudots = V.morevert V.expand = V.maximize V.fullscreen = V.maximize
    V.signout = V.logout V["log-out"] = V.logout V.signin = V.login V["log-in"] = V.login
    V.external = V.externallink V["external-link"] = V.externallink V.chat = V.message V.messages = V.message
    V.comment = V.message V.envelope = V.mail V.mobile = V.phone V.document = V.filetext
    V.doc = V.filetext V.card = V.creditcard V.payment = V.creditcard V.medal = V.award
    V.speaker = V.volume V.sound = V.volume V.mute = V.volumex V.microphone = V.mic
    V.cam = V.camera V.photo = V.camera V.network = V.wifi V.bars = V.signal
    V.openlock = V.unlock V.hidden = V.eyeoff V["eye-off"] = V.eyeoff V.king = V.crown
    V.death = V.skull V.blade = V.sword V.combat = V.sword V.aim = V.crosshair
    V.usd = V.dollar V.cash = V.dollar V.bookmarked = V.bookmark V.share2 = V.share
    Icons.vector = V

    Icons.names = {}
    do
        local seen = {}
        for name, fn in pairs(V) do if not seen[fn] then seen[fn] = true Icons.names[#Icons.names + 1] = name end end
        table.sort(Icons.names)
    end

    Icons.emoji = {
        menu = "≡", search = "⌕", close = "✕", min = "—", pin = "⚲", info = "ⓘ", dot = "•",
        home = "⌂", combat = "⚔", sword = "⚔", aim = "◎", gun = "➶", shield = "⛨",
        quest = "❖", map = "⊞", shop = "🛒", cart = "🛍", coin = "◉", money = "$",
        fruit = "🍇", fish = "🎣", craft = "⚒", gear = "⚙", stats = "▤", star = "★",
        rocket = "🚀", fire = "🔥", ice = "❄", bolt = "⚡", magic = "✦", skull = "☠",
        teleport = "✲", island = "🏝", boat = "⛵", chest = "🧰", key = "⚷", lock = "🔒",
        player = "☺", players = "👥", crown = "♛", bot = "🤖", eye = "◉", radar = "📡",
        speed = "»", fly = "🪽", car = "🏎", run = "🏃", jump = "🦘", clock = "◷",
        bell = "🔔", flask = "⚗", gem = "◈", dragon = "🐉", fox = "🦊", paw = "🐾",
        heart = "♥", check = "✔", cross = "✖", plus = "+", minus = "−", chevron = "›",
        server = "🌐", link = "🔗", folder = "🗀", code = "‹›", bug = "🐛", wrench = "🔧",
        leaf = "🍃", seed = "🌱", flower = "🌸", tree = "🌳", sun = "☀", moon = "☾",
        bag = "🛍", box = "📦", gift = "🎁", trophy = "🏆", target = "◎", spark = "✦",
        settings = "⚙", user = "☺", users = "👥", grid = "▦", list = "☰", tag = "🏷",
        download = "⬇", upload = "⬆", refresh = "↻", power = "⏻", play = "▶", pause = "⏸",
        image = "🖼", trash = "🗑", edit = "✎", copy = "⧉", save = "💾", filter = "⚆", calendar = "📅", layers = "▤",
        warning = "⚠", shieldcheck = "⛨", palette = "🎨", terminal = "▢", globe = "🌐",
        sparkles = "✨", lightning = "⚡", diamond = "◆", flag = "⚑", mail = "✉", phone = "✆",
        camera = "📷", video = "🎬", music = "♫", mic = "🎙", volume = "🔊", mute = "🔇",
        wifi = "📶", battery = "🔋", cloud = "☁", rain = "🌧", snow = "🌨", wind = "🌬",
        compass = "🧭", anchor = "⚓", rocket2 = "🚀", atom = "⚛", dna = "🧬", brain = "🧠",
        sparkle = "✦", arrowup = "↑", arrowdown = "↓", arrowleft = "←", arrowright = "→",
        plug = "🔌", cpu = "▣", database = "🗄", shieldx = "⛒", verified = "✔", question = "?",
        exclaim = "!", at = "@", hash = "#", percent = "%", clipboard = "📋", pencil = "✎",
        scissors = "✂", magnet = "🧲", bomb = "💣", rocket3 = "🛸", ghost = "👻", alien = "👾",
    }

    Icons.registry = {}
    Icons.sheet = { Image = nil, Map = {} }
    Icons._fileCache = {}
    local resolving = {}

    function Icons.setSheet(image, map)
        Icons.sheet.Image = (type(image) == "number") and ("rbxassetid://" .. image) or image
        if map then Icons.sheet.Map = map end
    end
    function Icons.register(name, value) Icons.registry[name] = value end

    local function fileAsset(p)
        if Icons._fileCache[p] ~= nil then return Icons._fileCache[p] end
        local img = false
        if Core.customAsset then local ok, r = pcall(Core.customAsset, p) if ok and r then img = r end end
        Icons._fileCache[p] = img
        return img
    end

    function Icons.resolve(value)
        if value == nil then return { kind = "vector", draw = V.dot } end
        if type(value) == "number" then return { kind = "image", image = "rbxassetid://" .. value } end
        if typeof(value) == "table" then
            if value.image then return { kind = "image", image = value.image, rect = value.rect } end
            if value.draw then return { kind = "vector", draw = value.draw } end
            if value.text then return { kind = "text", text = value.text } end
        end
        if type(value) == "string" then
            if value:match("^rbxassetid://") then return { kind = "image", image = value } end
            if value:match("^%d+$") then return { kind = "image", image = "rbxassetid://" .. value } end
            local file = value:match("^file:(.+)$")
            if file then
                local img = fileAsset(file)
                if img then return { kind = "image", image = img } end
                return { kind = "vector", draw = V.dot }
            end
            local emo = value:match("^emoji:(.+)$")
            if emo then return { kind = "text", text = Icons.emoji[emo] or emo } end
            local lname = value:match("^lucide:(.+)$") or value
            if Icons.registry[lname] ~= nil and not resolving[lname] then
                resolving[lname] = true
                local d = Icons.resolve(Icons.registry[lname])
                resolving[lname] = nil
                return d
            end
            if Icons.sheet.Image and Icons.sheet.Map[lname] then
                local r = Icons.sheet.Map[lname]
                return { kind = "image", image = Icons.sheet.Image,
                    rect = Rect.new(r[1], r[2], r[1] + r[3], r[2] + r[4]) }
            end
            if V[lname] then return { kind = "vector", draw = V[lname] } end
            if Icons.emoji[lname] then return { kind = "text", text = Icons.emoji[lname] } end
            return { kind = "text", text = lname }
        end
        return { kind = "vector", draw = V.dot }
    end

    function Icons.tintVector(holder, color)
        for _, d in ipairs(holder:GetDescendants()) do
            if d:IsA("UIStroke") then d.Color = color
            elseif d:IsA("Frame") and d.BackgroundTransparency < 1 then d.BackgroundColor3 = color end
        end
    end

    function Icons.make(parent, value, o)
        o = o or {}
        local d = Icons.resolve(value)
        if d.kind == "vector" then
            local holder = new("Frame", { Parent = parent, BackgroundTransparency = 1, BorderSizePixel = 0,
                Size = o.size or UDim2.fromOffset(20, 20), Position = o.position, AnchorPoint = o.anchor,
                ClipsDescendants = false, ZIndex = o.zindex or 1 })
            new("UIAspectRatioConstraint", { Parent = holder, AspectRatio = 1 })
            local clip = function() holder.ClipsDescendants = true end
            d.draw(holder, clip)
            Icons.tintVector(holder, o.color or Color3.new(1, 1, 1))
            if o.zindex then for _, c in ipairs(holder:GetDescendants()) do if c:IsA("GuiObject") then c.ZIndex = o.zindex end end end
            return holder, "vector"
        end
        if d.kind == "image" then
            local img = new("ImageLabel", {
                Parent = parent, BackgroundTransparency = 1, Image = d.image,
                Size = o.size or UDim2.fromOffset(20, 20), Position = o.position, AnchorPoint = o.anchor,
                ImageColor3 = o.color or Color3.new(1, 1, 1), ZIndex = o.zindex or 1,
            })
            if d.rect then img.ImageRectOffset = d.rect.Min img.ImageRectSize = d.rect.Max - d.rect.Min end
            return img, "image"
        end
        local t = txt(parent, d.text, o.textSize or 18, o.color or Color3.new(1, 1, 1), o.font or Enum.Font.GothamBold, {
            Size = o.size or UDim2.fromOffset(22, 22), Position = o.position, AnchorPoint = o.anchor,
            TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center, ZIndex = o.zindex or 1,
        })
        return t, "text"
    end

    function Icons.tint(inst, kind, color)
        if not inst then return end
        if kind == "vector" then Icons.tintVector(inst, color)
        elseif kind == "image" or inst:IsA("ImageLabel") then inst.ImageColor3 = color
        elseif inst:IsA("TextLabel") or inst:IsA("TextButton") then inst.TextColor3 = color end
    end

    local FILE_ICONS = {
        "home", "settings", "bell", "user", "users", "star", "heart", "shield", "zap", "globe",
        "box", "palette", "power", "trash", "search", "menu", "check", "x", "plus", "minus",
        "chevron-right", "chevron-down", "image", "refresh", "spark", "layers", "edit", "save",
        "eye", "lock", "info", "sliders", "grid", "list", "gamepad",
    }
    Icons.dir = "BPUI/icons/png/"
    function Icons.autoload(folder)
        if not (Core.hasFS and Core.customAsset) then return 0 end
        local base = folder or Icons.dir
        local n = 0
        for _, name in ipairs(FILE_ICONS) do
            local p = base .. name .. ".png"
            local ok, exists = pcall(function() return isfile(p) end)
            if ok and exists then Icons.registry[name] = "file:" .. p n += 1 end
        end
        return n
    end
    pcall(Icons.autoload)

    BPUI.Icons = Icons
    function BPUI:RegisterIcon(name, value) Icons.register(name, value) return self end
    function BPUI:SetIconSheet(image, map) Icons.setSheet(image, map) return self end
    function BPUI:LoadFileIcons(folder) return Icons.autoload(folder) end

    return Icons
end
M["button"] = function(use, BPUI)
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
M["toggle"] = function(use, BPUI)
    local C = use("core")
    local new, txt, tw, corner, stroke, mkCard, titleBlock = C.new, C.txt, C.tw, C.corner, C.stroke, C.mkCard, C.titleBlock
    local Maid, UIS = C.Maid, C.UIS

    return function(win, page, o)
        local hasKey = o.Keybind ~= nil
        local card = mkCard(win, page, o.Desc and 54 or 44, true)
        titleBlock(win, card, o.Title or "Toggle", o.Desc, hasKey and 162 or 74)
        local state = o.Default and true or false
        local groupW = hasKey and 136 or 40
        local group = new("Frame", { Parent = card, BackgroundTransparency = 1, AnchorPoint = Vector2.new(0, 0.5),
            Position = hasKey and UDim2.new(1, -150, 0.5, 0) or UDim2.new(1, -54, 0.5, 0),
            Size = UDim2.fromOffset(groupW, 30) })
        local track = new("Frame", { Parent = group, Size = UDim2.fromOffset(40, 21), AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(1, -40, 0.5, 0), BackgroundColor3 = win.Theme.Accent, BackgroundTransparency = state and 0 or 1 })
        corner(track, 11)
        C.gloss(track, 0.86)
        local ts = stroke(track, win.Theme.Sub, 1, state and 1 or 0.3)
        local knob = new("Frame", { Parent = track, Size = UDim2.fromOffset(13, 13), AnchorPoint = Vector2.new(0, 0.5),
            Position = state and UDim2.new(1, -17, 0.5, 0) or UDim2.new(0, 4, 0.5, 0), BackgroundColor3 = state and win.Theme.OnAccent or win.Theme.Sub })
        corner(knob, 7)
        local btn = new("TextButton", { Parent = group, BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(1, -20, 0.5, 0), Size = UDim2.fromOffset(62, 38), Text = "", AutoButtonColor = false })
        C.hoverable(track, function() C.tw(track, 0.12, { BackgroundTransparency = state and 0 or 0.92 }) end,
            function() C.tw(track, 0.12, { BackgroundTransparency = state and 0 or 1 }) end)
        local obj = { kind = "toggle" }
        local cm
        local function render(fire)
            tw(track, 0.16, { BackgroundColor3 = win.Theme.Accent, BackgroundTransparency = state and 0 or 1 })
            tw(knob, 0.16, { Position = state and UDim2.new(1, -17, 0.5, 0) or UDim2.new(0, 4, 0.5, 0), BackgroundColor3 = state and win.Theme.OnAccent or win.Theme.Sub })
            tw(ts, 0.16, { Transparency = state and 1 or 0.3 })
            if fire then pcall(o.Callback, state) end
        end
        win:onTheme(function() track.BackgroundColor3 = win.Theme.Accent ts.Color = win.Theme.Sub knob.BackgroundColor3 = state and win.Theme.OnAccent or win.Theme.Sub end)
        btn.MouseButton1Click:Connect(function() state = not state render(true) win:save() end)
        if hasKey then
            C.bindRight(card, group, { rightInset = 162, normalHeight = o.Desc and 54 or 44, compactHeight = o.Desc and 92 or 82, minWidth = 430, controlHeight = 30 })
            cm = Maid.new() win.maid:give(function() cm:clean() end)
            local kcur = (o.Keybind ~= true and o.Keybind) or "None"
            local kb = new("TextButton", { Parent = group, BackgroundColor3 = win.Theme.Panel2, AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.fromOffset(84, 26), Text = "", AutoButtonColor = false })
            corner(kb, 6)
            win:paint(kb, "BackgroundColor3", "Panel2")
            local kbs = stroke(kb, win.Theme.Stroke, 1, 0.5)
            local klb = txt(kb, tostring(kcur), 12, win.Theme.Sub, Enum.Font.GothamMedium, { Size = UDim2.new(1, 0, 1, 0), TextXAlignment = Enum.TextXAlignment.Center })
            local cap, just = false, false
            win:onTheme(function() if not cap then kbs.Color = win.Theme.Stroke end end)
            kb.MouseButton1Click:Connect(function() cap = true klb.Text = "..." tw(kbs, 0.15, { Color = win.Theme.Accent, Transparency = 0 }) end)
            cm:give(UIS.InputBegan:Connect(function(i, gpe)
                if cap then
                    cap = false just = true
                    tw(kbs, 0.15, { Color = win.Theme.Stroke, Transparency = 0.5 })
                    local nm = C.keyFromInput(i)
                    if i.KeyCode == Enum.KeyCode.Escape or i.KeyCode == Enum.KeyCode.Backspace then nm = "None" end
                    kcur = nm or "None" klb.Text = kcur win:save()
                    task.defer(function() just = false end)
                    return
                end
                if gpe or just or obj._enabled == false then return end
                if C.keyMatches(i, kcur) then state = not state render(true) win:save() end
            end))
            obj.GetKey = function() return kcur end
            obj.SetKey = function(_, k) kcur = k or "None" klb.Text = kcur end
        end
        function obj:Set(v, fire) state = v and true or false render(fire ~= false) if fire ~= false then win:save() end end
        function obj:Get() return state end
        obj.Instance = card
        function obj:Destroy() if cm then cm:clean() end card:Destroy() end
        return obj
    end
end
M["slider"] = function(use, BPUI)
    local C = use("core")
    local new, txt, corner, mkCard, titleBlock = C.new, C.txt, C.corner, C.mkCard, C.titleBlock
    local Maid, UIS = C.Maid, C.UIS

    local function fmtNum(v, suffix)
        suffix = suffix or ""
        if math.abs(v - math.floor(v + 0.5)) < 1e-6 then return tostring(math.floor(v + 0.5)) .. suffix end
        return string.format("%g", v) .. suffix
    end

    return function(win, page, o)
        local cm = Maid.new() win.maid:give(function() cm:clean() end)
        local card = mkCard(win, page, o.Desc and 72 or 56, true)
        titleBlock(win, card, o.Title or "Slider", o.Desc, 90)
        local mn, mx = o.Min or 0, o.Max or 100
        local step = o.Step or 1 if step == 0 then step = 1 end
        local rng = (mx - mn) if rng == 0 then rng = 1 end
        local val = math.clamp(o.Default or mn, mn, mx)
        local suffix = o.Suffix or ""
        local yTop = o.Desc and 26 or 8
        local valLbl = txt(card, fmtNum(val, suffix), 13, win.Theme.Accent, C.MONO,
            { Size = UDim2.fromOffset(80, 18), Position = UDim2.new(1, -94, 0, yTop), TextXAlignment = Enum.TextXAlignment.Right })
        win:paint(valLbl, "TextColor3", "Accent")
        local track = new("Frame", { Parent = card, Size = UDim2.new(1, -28, 0, 6), Position = UDim2.new(0, 14, 1, -16), BackgroundColor3 = win.Theme.Panel2 })
        corner(track, 3)
        win:paint(track, "BackgroundColor3", "Panel2")
        local fill = new("Frame", { Parent = track, Size = UDim2.fromScale((val - mn) / rng, 1), BackgroundColor3 = win.Theme.Accent })
        corner(fill, 3)
        C.gloss(fill, 0.85)
        win:paint(fill, "BackgroundColor3", "Accent")
        local knob = new("Frame", { Parent = track, Size = UDim2.fromOffset(16, 16), AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new((val - mn) / rng, 0, 0.5, 0), BackgroundColor3 = Color3.fromRGB(255, 255, 255), ZIndex = 3 })
        corner(knob, 8)
        win:paint(C.stroke(knob, win.Theme.Stroke, 1, 0.4), "Color", "Stroke")
        local kdot = new("Frame", { Parent = knob, Size = UDim2.fromOffset(8, 8), AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5), BackgroundColor3 = win.Theme.Accent, ZIndex = 4 })
        corner(kdot, 4)
        win:paint(kdot, "BackgroundColor3", "Accent")
        C.hoverable(card, function() C.tw(kdot, 0.12, { Size = UDim2.fromOffset(10, 10) }) end,
            function() C.tw(kdot, 0.12, { Size = UDim2.fromOffset(8, 8) }) end)
        local obj = { kind = "slider" }
        local function apply(v, fire)
            v = math.clamp(v, mn, mx)
            v = mn + math.floor((v - mn) / step + 0.5) * step
            v = math.clamp(v, mn, mx)
            val = v
            local a = (v - mn) / rng
            fill.Size = UDim2.fromScale(a, 1)
            knob.Position = UDim2.new(a, 0, 0.5, 0)
            valLbl.Text = fmtNum(v, suffix)
            if fire then pcall(o.Callback, v) end
        end
        local dragging = false
        local hit = new("TextButton", { Parent = card, BackgroundTransparency = 1, Text = "", AutoButtonColor = false,
            Size = UDim2.new(1, 0, 0, 22), Position = UDim2.new(0, 0, 1, -22) })
        local function fromX(px)
            if track.AbsoluteSize.X <= 0 then return end
            local a = math.clamp((px - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            apply(mn + a * rng, true)
        end
        hit.InputBegan:Connect(function(i) if C.isPress(i) then dragging = true fromX(i.Position.X) end end)
        cm:give(UIS.InputChanged:Connect(function(i) if dragging and C.isMove(i) then fromX(i.Position.X) end end))
        cm:give(UIS.InputEnded:Connect(function(i) if C.isPress(i) and dragging then dragging = false win:save() end end))
        function obj:Set(v, fire) apply(v, fire ~= false) if fire ~= false then win:save() end end
        function obj:Get() return val end
        obj.Instance = card
        function obj:Destroy() cm:clean() card:Destroy() end
        return obj
    end
end
M["dropdown"] = function(use, BPUI)
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
M["input"] = function(use, BPUI)
    local C = use("core")
    local new, txt, corner, stroke, tw, mkCard, titleBlock = C.new, C.txt, C.corner, C.stroke, C.tw, C.mkCard, C.titleBlock

    return function(win, page, o)
        local card = mkCard(win, page, o.Desc and 54 or 44, true)
        titleBlock(win, card, o.Title or "Input", o.Desc, 200)
        local box = new("Frame", { Parent = card, BackgroundColor3 = win.Theme.Panel2, AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(1, -190, 0.5, 0), Size = UDim2.fromOffset(176, 30) })
        corner(box, 6)
        win:paint(box, "BackgroundColor3", "Panel2")
        local bs = stroke(box, win.Theme.Stroke, 1, 0.5)
        local tb = new("TextBox", { Parent = box, BackgroundTransparency = 1, Size = UDim2.new(1, -20, 1, 0),
            Position = UDim2.fromOffset(10, 0), Font = C.uifont(Enum.Font.GothamMedium), TextSize = 13, TextColor3 = win.Theme.Text,
            PlaceholderText = o.Placeholder or "...", PlaceholderColor3 = win.Theme.Dim, Text = o.Default or "",
            TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, TextTruncate = Enum.TextTruncate.AtEnd })
        C.bindRight(card, box, { rightInset = 200, normalHeight = o.Desc and 54 or 44, compactHeight = o.Desc and 92 or 82, minWidth = 430, controlHeight = 30 })
        win:paint(tb, "TextColor3", "Text")
        tb.Focused:Connect(function() tw(bs, 0.15, { Color = win.Theme.Accent, Transparency = 0 }) end)
        tb.FocusLost:Connect(function()
            tw(bs, 0.15, { Color = win.Theme.Stroke, Transparency = 0.5 })
            pcall(o.Callback, tb.Text) win:save()
            if o.Clear then tb.Text = "" end
        end)
        return { kind = "input", Instance = card,
            Set = function(_, s, fire) tb.Text = tostring(s) if fire ~= false then pcall(o.Callback, tb.Text) win:save() end end,
            Get = function() return tb.Text end, Destroy = function() card:Destroy() end }
    end
end
M["keybind"] = function(use, BPUI)
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
M["colorpicker"] = function(use, BPUI)
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
M["text"] = function(use, BPUI)
    local C = use("core")
    local new, txt, mkCard = C.new, C.txt, C.mkCard

    local T = {}

    function T.section(win, page, opts)
        local title = (type(opts) == "table" and (opts.Title or opts.title)) or opts or "Section"
        local desc = type(opts) == "table" and (opts.Desc or opts.desc) or nil
        local hasD = desc ~= nil and desc ~= ""
        local topGap = ((page:GetAttribute("ord") or 0) == 0) and 0 or 14
        local wrap = new("Frame", { Parent = page, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = C.nextOrd(page) })
        C.pad(wrap, 0, 0, topGap, 0)
        C.list(wrap, 6)
        local hdr = new("Frame", { Parent = wrap, BackgroundTransparency = 1, LayoutOrder = 0,
            Size = UDim2.new(1, 0, 0, hasD and 34 or 18) })
        local tick = new("Frame", { Parent = hdr, BorderSizePixel = 0, Size = UDim2.fromOffset(3, 13),
            Position = UDim2.fromOffset(2, hasD and 1 or 2), BackgroundColor3 = win.Theme.Accent })
        C.corner(tick, 2)
        win:paint(tick, "BackgroundColor3", "Accent")
        local tl = txt(hdr, string.upper(title), 12, win.Theme.Text, Enum.Font.GothamBold,
            { Size = UDim2.new(1, -14, 0, 16), Position = UDim2.fromOffset(11, hasD and 0 or 1) })
        win:paint(tl, "TextColor3", "Text")
        if hasD then
            local dl = txt(hdr, desc, 12, win.Theme.Sub, Enum.Font.Gotham,
                { Size = UDim2.new(1, -14, 0, 15), Position = UDim2.fromOffset(11, 18), TextTruncate = Enum.TextTruncate.AtEnd })
            win:paint(dl, "TextColor3", "Sub")
        end
        local content = new("Frame", { Parent = wrap, BackgroundTransparency = 1, LayoutOrder = 1,
            Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y })
        content:SetAttribute("bpuiFlat", true)
        C.list(content, 3)
        return { Set = function(_, s) tl.Text = string.upper(tostring(s)) end, Destroy = function() wrap:Destroy() end, Instance = content, content = content }
    end

    function T.divider(win, page)
        local d = new("Frame", { Parent = page, Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = win.Theme.Stroke,
            BackgroundTransparency = 0.4, LayoutOrder = C.nextOrd(page) })
        win:paint(d, "BackgroundColor3", "Stroke")
        return d
    end

    function T.label(win, page, text)
        local card = mkCard(win, page, 36, true)
        local l = txt(card, text or "", 13, win.Theme.Sub, Enum.Font.Gotham,
            { Size = UDim2.new(1, -32, 0, 16), Position = UDim2.fromOffset(16, 11), TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, LineHeight = 1.08 })
        win:paint(l, "TextColor3", "Sub")
        local function fit() card.Size = UDim2.new(1, 0, 0, math.max(38, l.TextBounds.Y + 22)) end
        l:GetPropertyChangedSignal("TextBounds"):Connect(fit)
        l:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
        task.defer(fit)
        return { kind = "label", Instance = card, Set = function(_, s) l.Text = tostring(s) end, Destroy = function() card:Destroy() end }
    end

    function T.paragraph(win, page, o)
        local card = mkCard(win, page, 60, true)
        local t = txt(card, o.Title or "", 14, win.Theme.Text, Enum.Font.GothamBold,
            { Size = UDim2.new(1, -32, 0, 18), Position = UDim2.fromOffset(16, 14) })
        win:paint(t, "TextColor3", "Text")
        local b = txt(card, o.Body or "", 13, win.Theme.Sub, Enum.Font.Gotham,
            { Size = UDim2.new(1, -32, 0, 0), Position = UDim2.fromOffset(16, 36), TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, LineHeight = 1.08 })
        win:paint(b, "TextColor3", "Sub")
        local function fit() card.Size = UDim2.new(1, 0, 0, math.max(64, b.TextBounds.Y + 52)) end
        b:GetPropertyChangedSignal("TextBounds"):Connect(fit)
        b:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
        task.defer(fit)
        return { kind = "paragraph", Instance = card, SetTitle = function(_, s) t.Text = s end,
            Set = function(_, s) b.Text = s end, Destroy = function() card:Destroy() end }
    end

    return T
end
M["progress"] = function(use, BPUI)
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
M["segmented"] = function(use, BPUI)
    local C = use("core")
    local new, txt, corner, pad, list, tw, hoverable, mkCard, titleBlock = C.new, C.txt, C.corner, C.pad, C.list, C.tw, C.hoverable, C.mkCard, C.titleBlock
    return function(win, page, o)
        local card = mkCard(win, page, o.Desc and 54 or 44, true)
        titleBlock(win, card, o.Title or "Segmented", o.Desc, 240)
        local opts = o.Options or o.Items or {}
        local sel = o.Default
        local has = false
        for _, v in ipairs(opts) do if v == sel then has = true break end end
        if not has then sel = opts[1] end
        local box = new("Frame", { Parent = card, BackgroundColor3 = win.Theme.Bg2, AutomaticSize = Enum.AutomaticSize.X,
            AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0), Size = UDim2.fromOffset(0, 30) })
        corner(box, 7)
        win:paint(box, "BackgroundColor3", "Bg2")
        pad(box, 3, 3, 3, 3)
        list(box, 4, Enum.FillDirection.Horizontal)
        C.bindRight(card, box, { rightInset = 240, normalHeight = o.Desc and 54 or 44, compactHeight = o.Desc and 92 or 82, minWidth = 520, controlHeight = 30 })
        local pills = {}
        local function skin(v, p)
            local on = v == sel
            tw(p.btn, 0.16, { BackgroundColor3 = on and win.Theme.Accent or win.Theme.Hover, BackgroundTransparency = on and 0 or 1 })
            tw(p.lbl, 0.16, { TextColor3 = on and win.Theme.OnAccent or win.Theme.Sub })
        end
        local function render() for v, p in pairs(pills) do skin(v, p) end end
        local function pick(v, fire)
            sel = v render()
            if fire then pcall(o.Callback, v) win:save() end
        end
        for _, v in ipairs(opts) do
            local on = v == sel
            local btn = new("TextButton", { Parent = box, Text = "", AutoButtonColor = false, AutomaticSize = Enum.AutomaticSize.X,
                Size = UDim2.fromOffset(0, 24), BackgroundColor3 = on and win.Theme.Accent or win.Theme.Hover, BackgroundTransparency = on and 0 or 1 })
            corner(btn, 6)
            pad(btn, 12, 12, 0, 0)
            local lbl = txt(btn, tostring(v), 13, on and win.Theme.OnAccent or win.Theme.Sub, Enum.Font.GothamMedium,
                { Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, TextXAlignment = Enum.TextXAlignment.Center })
            local p = { btn = btn, lbl = lbl }
            pills[v] = p
            hoverable(btn, function() if v ~= sel then tw(btn, 0.1, { BackgroundTransparency = 0.5 }) end end,
                function() if v ~= sel then tw(btn, 0.1, { BackgroundTransparency = 1 }) end end)
            btn.MouseButton1Click:Connect(function() if v ~= sel then pick(v, true) end end)
        end
        win:onTheme(function() box.BackgroundColor3 = win.Theme.Bg2 for v, p in pairs(pills) do
            local on = v == sel
            p.btn.BackgroundColor3 = on and win.Theme.Accent or win.Theme.Hover
            p.btn.BackgroundTransparency = on and 0 or 1
            p.lbl.TextColor3 = on and win.Theme.OnAccent or win.Theme.Sub
        end end)
        local obj = { kind = "segmented" }
        function obj:Set(v, fire)
            if pills[v] == nil then return end
            sel = v render()
            if fire ~= false then pcall(o.Callback, v) win:save() end
        end
        function obj:Get() return sel end
        obj.Instance = card
        function obj:Destroy() card:Destroy() end
        return obj
    end
end
M["radio"] = function(use, BPUI)
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
M["stepper"] = function(use, BPUI)
    local C = use("core")
    local new, txt, corner, mkCard, titleBlock = C.new, C.txt, C.corner, C.mkCard, C.titleBlock

    local function fmtNum(v, suffix)
        suffix = suffix or ""
        if math.abs(v - math.floor(v + 0.5)) < 1e-6 then return tostring(math.floor(v + 0.5)) .. suffix end
        return string.format("%g", v) .. suffix
    end

    return function(win, page, o)
        local card = mkCard(win, page, o.Desc and 54 or 44, true)
        titleBlock(win, card, o.Title or "Stepper", o.Desc, 150)
        local mn, mx = o.Min or 0, o.Max or 100
        local step = o.Step or 1 if step == 0 then step = 1 end
        local suffix = o.Suffix or ""
        local function snap(v)
            v = math.clamp(v, mn, mx)
            v = mn + math.floor((v - mn) / step + 0.5) * step
            return math.clamp(v, mn, mx)
        end
        local val = snap(o.Default or mn)
        local group = new("Frame", { Parent = card, BackgroundColor3 = win.Theme.Bg2, AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(1, -140, 0.5, 0), Size = UDim2.fromOffset(126, 30) })
        corner(group, 6)
        win:paint(group, "BackgroundColor3", "Bg2")
        local minus = new("TextButton", { Parent = group, BackgroundTransparency = 1, Size = UDim2.fromOffset(28, 30),
            Position = UDim2.new(0, 0, 0, 0), Text = "−", TextColor3 = win.Theme.Sub, Font = Enum.Font.GothamBold, TextSize = 18, AutoButtonColor = false })
        win:paint(minus, "TextColor3", "Sub")
        local plus = new("TextButton", { Parent = group, BackgroundTransparency = 1, Size = UDim2.fromOffset(28, 30),
            Position = UDim2.new(1, -28, 0, 0), Text = "+", TextColor3 = win.Theme.Sub, Font = Enum.Font.GothamBold, TextSize = 18, AutoButtonColor = false })
        win:paint(plus, "TextColor3", "Sub")
        local valLbl = txt(group, fmtNum(val, suffix), 13, win.Theme.Text, C.MONO,
            { Size = UDim2.new(1, -56, 1, 0), Position = UDim2.new(0, 28, 0, 0), TextXAlignment = Enum.TextXAlignment.Center })
        win:paint(valLbl, "TextColor3", "Text")
        C.bindRight(card, group, { rightInset = 150, normalHeight = o.Desc and 54 or 44, compactHeight = o.Desc and 92 or 82, minWidth = 380, controlHeight = 30, fill = false })
        C.hoverable(minus, function() minus.TextColor3 = win.Theme.Text end, function() minus.TextColor3 = win.Theme.Sub end)
        C.hoverable(plus, function() plus.TextColor3 = win.Theme.Text end, function() plus.TextColor3 = win.Theme.Sub end)
        local obj = { kind = "stepper" }
        local function apply(v, fire)
            val = snap(v)
            valLbl.Text = fmtNum(val, suffix)
            if fire then pcall(o.Callback, val) end
        end
        minus.MouseButton1Click:Connect(function() apply(val - step, true) win:save() end)
        plus.MouseButton1Click:Connect(function() apply(val + step, true) win:save() end)
        function obj:Set(v, fire) apply(v, fire ~= false) if fire ~= false then win:save() end end
        function obj:Get() return val end
        obj.Instance = card
        function obj:Destroy() card:Destroy() end
        return obj
    end
end
M["image"] = function(use, BPUI)
    local C = use("core")
    local new, txt, corner, mkCard = C.new, C.txt, C.corner, C.mkCard
    local function resolve(o2)
        if o2.Avatar then return "rbxthumb://type=AvatarHeadShot&id=" .. o2.Avatar .. "&w=150&h=150"
        elseif type(o2.Image) == "number" then return "rbxassetid://" .. o2.Image
        elseif type(o2.Image) == "string" then return o2.Image
        else return "" end
    end
    return function(win, page, o)
        local h = o.Height or 120
        local card = mkCard(win, page, (o.Title and 22 or 0) + h + 20, true)
        local cap
        if o.Title then
            cap = txt(card, o.Title, 12, win.Theme.Sub, Enum.Font.GothamMedium,
                { Size = UDim2.new(1, -28, 0, 16), Position = UDim2.fromOffset(14, 8) })
            win:paint(cap, "TextColor3", "Sub")
        end
        local img = new("ImageLabel", { Parent = card, Size = UDim2.new(1, -28, 0, h),
            Position = UDim2.fromOffset(14, (o.Title and 30 or 0) + 8), BackgroundColor3 = win.Theme.Bg2,
            ScaleType = o.ScaleType or Enum.ScaleType.Crop, ClipsDescendants = true, Image = resolve(o) })
        if o.Rounded ~= false then corner(img, 8) end
        win:paint(img, "BackgroundColor3", "Bg2")
        local obj = { kind = "image" }
        function obj:SetImage(image, avatar) img.Image = resolve({ Image = image, Avatar = avatar }) end
        obj.Instance = card
        function obj:Destroy() card:Destroy() end
        return obj
    end
end
M["stat"] = function(use, BPUI)
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
M["buttonrow"] = function(use, BPUI)
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
M["accordion"] = function(use, BPUI)
    local C = use("core")
    local Icons = use("icons")
    local new, txt, corner = C.new, C.txt, C.corner

    return function(win, page, o)
        o = o or {}
        local card = new("Frame", { Parent = page, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1, BorderSizePixel = 0, LayoutOrder = C.nextOrd(page), ClipsDescendants = true })
        corner(card, 8)
        C.list(card, 0)

        local hasD = o.Desc ~= nil and o.Desc ~= ""
        local header = new("TextButton", { Parent = card, Size = UDim2.new(1, 0, 0, hasD and 54 or 44), BackgroundColor3 = win.Theme.Hover, BackgroundTransparency = 1,
            Text = "", AutoButtonColor = false, LayoutOrder = 0 })
        corner(header, 8)
        win:paint(header, "BackgroundColor3", "Hover")
        local tx = 16
        if o.Icon then
            local ic, ik = Icons.make(header, o.Icon, { size = UDim2.fromOffset(20, 20), anchor = Vector2.new(0, 0.5),
                position = UDim2.new(0, 16, 0.5, 0), color = win.Theme.Accent, textSize = 16 })
            win:onTheme(function() Icons.tint(ic, ik, win.Theme.Accent) end)
            tx = 46
        end
        local tl = txt(header, o.Title or "Section", 14, win.Theme.Text, Enum.Font.GothamBold,
            { Size = UDim2.new(1, -(tx + 44), 0, hasD and 18 or 44), Position = UDim2.fromOffset(tx, hasD and 9 or 0),
                TextYAlignment = hasD and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center, TextTruncate = Enum.TextTruncate.AtEnd })
        win:paint(tl, "TextColor3", "Text")
        if hasD then
            local dl = txt(header, o.Desc, 12, win.Theme.Sub, Enum.Font.Gotham,
                { Size = UDim2.new(1, -(tx + 44), 0, 16), Position = UDim2.fromOffset(tx, 29), TextTruncate = Enum.TextTruncate.AtEnd })
            win:paint(dl, "TextColor3", "Sub")
        end
        local chev = Icons.make(header, "chevrondown", { size = UDim2.fromOffset(18, 18), anchor = Vector2.new(0, 0.5),
            position = UDim2.new(1, -32, 0.5, 0), color = win.Theme.Sub })
        win:onTheme(function() Icons.tint(chev, "vector", win.Theme.Sub) end)
        C.press(header, { radius = 8 })
        C.hoverable(header, function() C.tw(header, 0.12, { BackgroundTransparency = 0.82 }) Icons.tint(chev, "vector", win.Theme.Text) end,
            function() C.tw(header, 0.14, { BackgroundTransparency = 1 }) Icons.tint(chev, "vector", win.Theme.Sub) end)

        local body = new("Frame", { Parent = card, Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1, ClipsDescendants = true, LayoutOrder = 1 })
        local inner = new("Frame", { Parent = body, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1 })
        inner:SetAttribute("bpuiFlat", true)
        C.pad(inner, 8, 8, 2, 8)
        local ll = C.list(inner, 3)

        local open = o.Open and true or false
        local function contentH() return ll.AbsoluteContentSize.Y + 10 end
        local function refresh(animate)
            local target = open and contentH() or 0
            if animate then
                C.tw(body, 0.24, { Size = UDim2.new(1, 0, 0, target) })
                C.tw(chev, 0.22, { Rotation = open and 180 or 0 })
            else
                body.Size = UDim2.new(1, 0, 0, target)
                chev.Rotation = open and 180 or 0
            end
        end
        ll:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            if open then body.Size = UDim2.new(1, 0, 0, contentH()) end
        end)
        header.MouseButton1Click:Connect(function() open = not open refresh(true) end)
        task.defer(function() refresh(false) end)

        local obj = { kind = "accordion", content = inner, Instance = card }
        obj.Open = function() if not open then open = true refresh(true) end end
        obj.Close = function() if open then open = false refresh(true) end end
        obj.Toggle = function() open = not open refresh(true) end
        obj.IsOpen = function() return open end
        obj.Set = function(_, s) tl.Text = tostring(s) end
        obj.Destroy = function() card:Destroy() end
        return obj
    end
end
M["rangeslider"] = function(use, BPUI)
    local C = use("core")
    local new, txt, corner, mkCard, titleBlock = C.new, C.txt, C.corner, C.mkCard, C.titleBlock
    local Maid, UIS = C.Maid, C.UIS

    local function fmt(v, suffix)
        suffix = suffix or ""
        if math.abs(v - math.floor(v + 0.5)) < 1e-6 then return tostring(math.floor(v + 0.5)) .. suffix end
        return string.format("%g", v) .. suffix
    end

    return function(win, page, o)
        local cm = Maid.new() win.maid:give(function() cm:clean() end)
        local card = mkCard(win, page, o.Desc and 72 or 56, true)
        titleBlock(win, card, o.Title or "Range", o.Desc, 130)
        local mn, mx = o.Min or 0, o.Max or 100
        local step = o.Step or 1 if step == 0 then step = 1 end
        local rng = (mx - mn) if rng == 0 then rng = 1 end
        local suffix = o.Suffix or ""
        local function snap(v)
            v = math.clamp(v, mn, mx)
            v = mn + math.floor((v - mn) / step + 0.5) * step
            return math.clamp(v, mn, mx)
        end
        local lo = snap(o.DefaultMin or mn)
        local hi = snap(o.DefaultMax or mx)
        if lo > hi then lo, hi = hi, lo end

        local yTop = o.Desc and 26 or 8
        local valLbl = txt(card, "", 13, win.Theme.Accent, C.MONO,
            { Size = UDim2.fromOffset(120, 18), Position = UDim2.new(1, -134, 0, yTop), TextXAlignment = Enum.TextXAlignment.Right })
        win:paint(valLbl, "TextColor3", "Accent")

        local track = new("Frame", { Parent = card, Size = UDim2.new(1, -28, 0, 6), Position = UDim2.new(0, 14, 1, -16), BackgroundColor3 = win.Theme.Panel2 })
        corner(track, 3)
        win:paint(track, "BackgroundColor3", "Panel2")
        local fill = new("Frame", { Parent = track, BackgroundColor3 = win.Theme.Accent })
        corner(fill, 3)
        C.gloss(fill, 0.85)
        win:paint(fill, "BackgroundColor3", "Accent")

        local function mkKnob()
            local k = new("Frame", { Parent = track, Size = UDim2.fromOffset(16, 16), AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255), ZIndex = 3 })
            corner(k, 8)
            win:paint(C.stroke(k, win.Theme.Stroke, 1, 0.4), "Color", "Stroke")
            local d = new("Frame", { Parent = k, Size = UDim2.fromOffset(8, 8), AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0.5, 0.5), BackgroundColor3 = win.Theme.Accent, ZIndex = 4 })
            corner(d, 4)
            win:paint(d, "BackgroundColor3", "Accent")
            return k, d
        end
        local loK, loD = mkKnob()
        local hiK, hiD = mkKnob()
        C.hoverable(card, function() C.tw(loD, 0.12, { Size = UDim2.fromOffset(10, 10) }) C.tw(hiD, 0.12, { Size = UDim2.fromOffset(10, 10) }) end,
            function() C.tw(loD, 0.12, { Size = UDim2.fromOffset(8, 8) }) C.tw(hiD, 0.12, { Size = UDim2.fromOffset(8, 8) }) end)

        local obj = { kind = "range" }
        local function render(fire)
            local a, b = (lo - mn) / rng, (hi - mn) / rng
            fill.Position = UDim2.new(a, 0, 0, 0)
            fill.Size = UDim2.new(b - a, 0, 1, 0)
            loK.Position = UDim2.new(a, 0, 0.5, 0)
            hiK.Position = UDim2.new(b, 0, 0.5, 0)
            valLbl.Text = fmt(lo, suffix) .. " – " .. fmt(hi, suffix)
            if fire then pcall(o.Callback, lo, hi) end
        end
        render(false)

        local dragging = nil
        local hit = new("TextButton", { Parent = card, BackgroundTransparency = 1, Text = "", AutoButtonColor = false,
            Size = UDim2.new(1, 0, 0, 24), Position = UDim2.new(0, 0, 1, -23) })
        local function fracAt(px)
            if track.AbsoluteSize.X <= 0 then return 0 end
            return math.clamp((px - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        end
        local function moveTo(px)
            local f = fracAt(px)
            local v = snap(mn + f * rng)
            if dragging == "lo" then lo = math.min(v, hi)
            elseif dragging == "hi" then hi = math.max(v, lo) end
            render(true)
        end
        hit.InputBegan:Connect(function(i)
            if not C.isPress(i) then return end
            local f = fracAt(i.Position.X)
            local la, ha = (lo - mn) / rng, (hi - mn) / rng
            if math.abs(f - la) < math.abs(f - ha) then dragging = "lo"
            elseif math.abs(f - la) > math.abs(f - ha) then dragging = "hi"
            else dragging = (f >= ha) and "hi" or "lo" end
            moveTo(i.Position.X)
        end)
        cm:give(UIS.InputChanged:Connect(function(i) if dragging and C.isMove(i) then moveTo(i.Position.X) end end))
        cm:give(UIS.InputEnded:Connect(function(i) if C.isPress(i) and dragging then dragging = nil win:save() end end))

        function obj:Set(a, b, c)
            local nlo, nhi, fire
            if type(a) == "table" then nlo = a.Min or a[1]; nhi = a.Max or a[2]; fire = b
            else nlo = a; nhi = b; fire = c end
            lo = snap(nlo or lo) hi = snap(nhi or hi)
            if lo > hi then lo, hi = hi, lo end
            render(fire ~= false)
            if fire ~= false then win:save() end
        end
        function obj:Get() return { Min = lo, Max = hi } end
        obj.Instance = card
        function obj:Destroy() cm:clean() card:Destroy() end
        return obj
    end
end
M["datatable"] = function(use, BPUI)
    local C = use("core")
    local new, txt, corner = C.new, C.txt, C.corner

    return function(win, page, o)
        o = o or {}
        local cols = {}
        local total = 0
        for _, c in ipairs(o.Columns or {}) do
            local col = (type(c) == "table") and { title = tostring(c.Title or c.title or ""), w = c.Weight or 1, align = c.Align }
                or { title = tostring(c), w = 1 }
            total = total + col.w
            cols[#cols + 1] = col
        end
        if total <= 0 then total = 1 end
        local colX, acc = {}, 0
        for i, c in ipairs(cols) do colX[i] = acc acc = acc + c.w / total end
        local function alignOf(col) return col.align == "right" and Enum.TextXAlignment.Right
            or col.align == "center" and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left end

        local flat = page:GetAttribute("bpuiFlat") == true
        local card = new("Frame", { Parent = page, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = flat and win.Theme.Hover or win.Theme.Panel, BackgroundTransparency = flat and 1 or 0,
            BorderSizePixel = 0, LayoutOrder = C.nextOrd(page), ClipsDescendants = true })
        corner(card, 8)
        win:paint(card, "BackgroundColor3", flat and "Hover" or "Panel")
        if not flat then
            local cs = C.fluentStroke(card, win.Theme.Stroke, 0)
            win:paint(cs, "Color", "Stroke")
        end
        C.pad(card, 4, 4, 10, 10)
        C.list(card, 0)

        if o.Title then
            local th = new("Frame", { Parent = card, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 26), LayoutOrder = 0 })
            local tl = txt(th, o.Title, 14, win.Theme.Text, Enum.Font.GothamBold, { Size = UDim2.new(1, -20, 1, 0), Position = UDim2.fromOffset(10, 0) })
            win:paint(tl, "TextColor3", "Text")
        end

        local function rowFrame(lo, h)
            return new("Frame", { Parent = card, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, h), LayoutOrder = lo, BorderSizePixel = 0 })
        end
        local function cell(row, i, s, size, color, font)
            local lbl = txt(row, s, size, color, font, { Position = UDim2.new(colX[i], 0, 0, 0),
                Size = UDim2.new(cols[i].w / total, 0, 1, 0), TextXAlignment = alignOf(cols[i]), TextTruncate = Enum.TextTruncate.AtEnd })
            C.pad(lbl, 10, 8, 0, 0)
            return lbl
        end

        local header = rowFrame(1, 28)
        for i, col in ipairs(cols) do
            local hl = cell(header, i, string.upper(col.title), 11, win.Theme.Dim, Enum.Font.GothamBold)
            win:paint(hl, "TextColor3", "Dim")
        end
        local hdrLine = new("Frame", { Parent = header, Size = UDim2.new(1, -8, 0, 1), Position = UDim2.new(0, 4, 1, -1),
            BackgroundColor3 = win.Theme.Stroke, BackgroundTransparency = 0.4, BorderSizePixel = 0, ZIndex = 2 })
        win:paint(hdrLine, "BackgroundColor3", "Stroke")

        local rowsHolder = new("Frame", { Parent = card, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 2 })
        C.list(rowsHolder, 0)

        local function norm(r)
            if type(r) == "table" and r.Cells then return r.Cells, r.Color, r.Callback end
            return r, nil, nil
        end

        local rowData = {}
        local function build()
            for _, ch in ipairs(rowsHolder:GetChildren()) do if ch:IsA("Frame") then ch:Destroy() end end
            for idx, r in ipairs(rowData) do
                local cells, color, cb = norm(r)
                local row = new("Frame", { Parent = rowsHolder, BackgroundColor3 = win.Theme.Hover,
                    BackgroundTransparency = (idx % 2 == 0) and 0.55 or 1, Size = UDim2.new(1, 0, 0, 32), LayoutOrder = idx, BorderSizePixel = 0 })
                corner(row, 5)
                for i = 1, #cols do
                    local val = cells and cells[i]
                    local isFirst = i == 1
                    local lbl = cell(row, i, tostring(val == nil and "" or val), 13,
                        color or (isFirst and win.Theme.Text or win.Theme.Sub), isFirst and Enum.Font.GothamMedium or Enum.Font.Gotham)
                    if not color then win:paint(lbl, "TextColor3", isFirst and "Text" or "Sub") end
                end
                local interactive = cb ~= nil or o.OnRow ~= nil
                if interactive then
                    local btn = new("TextButton", { Parent = row, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Text = "", AutoButtonColor = false, ZIndex = 3 })
                    local base = (idx % 2 == 0) and 0.55 or 1
                    C.hoverable(row, function() C.tw(row, 0.12, { BackgroundTransparency = 0.3 }) end,
                        function() C.tw(row, 0.14, { BackgroundTransparency = base }) end)
                    C.press(btn, { radius = 5 })
                    local cap = r
                    btn.MouseButton1Click:Connect(function()
                        if cb then pcall(cb, cap, idx) end
                        if o.OnRow then pcall(o.OnRow, cap, idx) end
                    end)
                end
            end
            if #rowData == 0 then
                local e = txt(rowsHolder, o.Empty or "No data", 13, win.Theme.Dim, Enum.Font.Gotham,
                    { Size = UDim2.new(1, -20, 0, 30), Position = UDim2.fromOffset(10, 0), LayoutOrder = 1, TextXAlignment = Enum.TextXAlignment.Left })
                win:paint(e, "TextColor3", "Dim")
            end
        end
        rowData = o.Rows or {}
        build()
        win:onTheme(function()
            for _, ch in ipairs(rowsHolder:GetChildren()) do
                if ch:IsA("Frame") then ch.BackgroundColor3 = win.Theme.Hover end
            end
        end)

        local obj = { kind = "table", Instance = card }
        function obj:SetRows(rows) rowData = rows or {} build() end
        function obj:AddRow(r) rowData[#rowData + 1] = r build() end
        function obj:Clear() rowData = {} build() end
        function obj:Get() return rowData end
        function obj:Destroy() card:Destroy() end
        return obj
    end
end
M["icongallery"] = function(use, BPUI)
    local C = use("core")
    local Icons = use("icons")
    local new, txt, corner = C.new, C.txt, C.corner

    return function(win, page, o)
        o = o or {}
        local source = o.Icons or Icons.names
        local gridH = o.Height or 200
        local flat = page:GetAttribute("bpuiFlat") == true
        local card = new("Frame", { Parent = page, Size = UDim2.new(1, 0, 0, (o.Title and 28 or 6) + 38 + gridH + 12),
            BackgroundColor3 = flat and win.Theme.Hover or win.Theme.Panel, BackgroundTransparency = flat and 1 or 0,
            BorderSizePixel = 0, LayoutOrder = C.nextOrd(page), ClipsDescendants = true })
        corner(card, 8)
        win:paint(card, "BackgroundColor3", flat and "Hover" or "Panel")
        if not flat then
            local cs = C.fluentStroke(card, win.Theme.Stroke, 0)
            win:paint(cs, "Color", "Stroke")
        end

        local y = 10
        if o.Title then
            local tl = txt(card, o.Title, 14, win.Theme.Text, Enum.Font.GothamBold, { Size = UDim2.new(1, -28, 0, 20), Position = UDim2.fromOffset(14, 8) })
            win:paint(tl, "TextColor3", "Text")
            y = 32
        end

        local sb = new("Frame", { Parent = card, BackgroundColor3 = win.Theme.Panel2, Size = UDim2.new(1, -28, 0, 30), Position = UDim2.fromOffset(14, y) })
        corner(sb, 6)
        local sbs = C.stroke(sb, win.Theme.Stroke, 1, 0.5)
        win:paint(sb, "BackgroundColor3", "Panel2")
        Icons.make(sb, "search", { size = UDim2.fromOffset(16, 16), anchor = Vector2.new(0, 0.5), position = UDim2.new(0, 10, 0.5, 0), color = win.Theme.Dim })
        local tb = new("TextBox", { Parent = sb, BackgroundTransparency = 1, Size = UDim2.new(1, -36, 1, 0), Position = UDim2.fromOffset(32, 0),
            Font = C.uifont(Enum.Font.GothamMedium), TextSize = 13, TextColor3 = win.Theme.Text, PlaceholderText = o.Placeholder or "Search icons...",
            PlaceholderColor3 = win.Theme.Dim, Text = "", ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left })
        win:paint(tb, "TextColor3", "Text")
        tb.Focused:Connect(function() C.tw(sbs, 0.15, { Color = win.Theme.Accent, Transparency = 0 }) end)
        tb.FocusLost:Connect(function() C.tw(sbs, 0.15, { Color = win.Theme.Stroke, Transparency = 0.5 }) end)

        local scroll = new("ScrollingFrame", { Parent = card, BackgroundTransparency = 1, Position = UDim2.fromOffset(10, y + 38),
            Size = UDim2.new(1, -16, 0, gridH), CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollBarThickness = 3, ScrollBarImageColor3 = win.Theme.Accent, ScrollBarImageTransparency = 0.4, BorderSizePixel = 0 })
        win:paint(scroll, "ScrollBarImageColor3", "Accent")
        local grid = new("UIGridLayout", { Parent = scroll, CellSize = UDim2.fromOffset(72, 62), CellPadding = UDim2.fromOffset(6, 6),
            SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Left })
        C.pad(scroll, 4, 4, 4, 6)

        local function makeTile(name)
            local tile = new("TextButton", { Parent = scroll, BackgroundColor3 = win.Theme.Hover, BackgroundTransparency = 1,
                Text = "", AutoButtonColor = false })
            corner(tile, 7)
            local ico = Icons.make(tile, name, { size = UDim2.fromOffset(24, 24), anchor = Vector2.new(0.5, 0),
                position = UDim2.new(0.5, 0, 0, 9), color = win.Theme.Sub })
            local lbl = txt(tile, name, 10, win.Theme.Dim, Enum.Font.Gotham,
                { Size = UDim2.new(1, -6, 0, 14), Position = UDim2.new(0, 3, 1, -16), TextXAlignment = Enum.TextXAlignment.Center, TextTruncate = Enum.TextTruncate.AtEnd })
            C.hoverable(tile, function()
                C.tw(tile, 0.1, { BackgroundTransparency = 0.4 })
                Icons.tint(ico, "vector", win.Theme.Accent) lbl.TextColor3 = win.Theme.Text
            end, function()
                C.tw(tile, 0.12, { BackgroundTransparency = 1 })
                Icons.tint(ico, "vector", win.Theme.Sub) lbl.TextColor3 = win.Theme.Dim
            end)
            C.press(tile, { radius = 7 })
            tile.MouseButton1Click:Connect(function()
                if o.Copy ~= false then pcall(function() (setclipboard or set_clipboard)(name) end) end
                pcall(o.OnSelect, name)
            end)
        end

        local function fill(q)
            for _, ch in ipairs(scroll:GetChildren()) do if ch:IsA("TextButton") then ch:Destroy() end end
            q = (q or ""):lower()
            for _, name in ipairs(source) do
                if q == "" or tostring(name):lower():find(q, 1, true) then makeTile(name) end
            end
        end
        tb:GetPropertyChangedSignal("Text"):Connect(function() fill(tb.Text) end)
        fill("")
        win:onTheme(function() fill(tb.Text) end)

        local obj = { kind = "icongallery", Instance = card }
        function obj:Destroy() card:Destroy() end
        return obj
    end
end
M["configmanager"] = function(use, BPUI)
    local C = use("core")
    local mkDropdown = use("dropdown")
    local mkInput = use("input")
    local mkButtonRow = use("buttonrow")
    local mkButton = use("button")

    return function(win, page, o)
        o = o or {}
        local selected, newName, code = nil, "", ""

        local dd
        local function refresh(keepSel)
            local list = win:ListConfigs()
            dd:Refresh(list, keepSel ~= false)
            if keepSel == false then selected = nil end
        end

        dd = mkDropdown(win, page, { Title = "Saved Profiles", Desc = "Select a profile to load or delete",
            Items = win:ListConfigs(), Callback = function(v) selected = v end })

        local nameInp = mkInput(win, page, { Title = "Profile Name", Placeholder = "e.g. PvP",
            Callback = function(s) newName = s end })

        local function doSave(nm)
            if not win:SaveConfig(nm) then win:Notify({ Title = "Save failed (no file access?)", Type = "error" }) return end
            refresh(true)
            selected = nm
            dd:Set(nm, false)
            win:Notify({ Title = "Saved '" .. nm .. "'", Content = "Selected — press Load to restore it later.", Type = "success" })
        end

        local fileRow = mkButtonRow(win, page, { Title = "Manage", Items = {
            { Title = "Save As", Icon = "save", Variant = "primary", Callback = function()
                if newName == "" then win:Notify({ Title = "Type a profile name first", Type = "warning" }) return end
                doSave(newName)
            end },
            { Title = "Overwrite", Callback = function()
                if not selected then win:Notify({ Title = "Select a profile first", Type = "warning" }) return end
                doSave(selected)
            end },
            { Title = "Delete", Variant = "danger", Callback = function()
                if not selected then win:Notify({ Title = "Select a profile first", Type = "warning" }) return end
                local nm = selected
                win:DeleteConfig(nm) refresh(false) dd:Set(nil, false)
                win:Notify({ Title = "Deleted '" .. nm .. "'", Type = "error" })
            end },
        } })

        local loadBtn = mkButton(win, page, { Title = "Load Selected Profile", Desc = "Applies the selected profile to all controls",
            Icon = "download", Callback = function()
                if not selected then win:Notify({ Title = "Select a profile first", Type = "warning" }) return end
                if win:LoadConfigByName(selected) then win:Notify({ Title = "Loaded '" .. selected .. "'", Type = "success" })
                else win:Notify({ Title = "Load failed", Type = "error" }) end
            end })

        local codeInp = mkInput(win, page, { Title = "Import Code", Placeholder = "paste a BPUI1: share code",
            Callback = function(s) code = s end })

        local shareRow = mkButtonRow(win, page, { Title = "Share", Items = {
            { Title = "Copy Current", Icon = "copy", Variant = "primary", Callback = function()
                pcall(function() (setclipboard or set_clipboard)(win:ExportConfig()) end)
                win:Notify({ Title = "Config copied to clipboard", Type = "success" })
            end },
            { Title = "Import", Icon = "upload", Callback = function()
                if code == "" then win:Notify({ Title = "Paste a code first", Type = "warning" }) return end
                if win:ImportConfig(code) then win:Notify({ Title = "Config imported", Type = "success" })
                else win:Notify({ Title = "Invalid share code", Type = "error" }) end
            end },
        } })

        local obj = { kind = "configmanager", Instance = dd.Instance }
        function obj:Refresh() refresh(true) end
        function obj:Destroy()
            for _, c in ipairs({ dd, nameInp, fileRow, loadBtn, codeInp, shareRow }) do pcall(function() c:Destroy() end) end
        end
        return obj
    end
end
M["tab"] = function(use, BPUI)
    local C = use("core")
    local mkButton = use("button")
    local mkToggle = use("toggle")
    local mkSlider = use("slider")
    local mkDropdown = use("dropdown")
    local mkInput = use("input")
    local mkKeybind = use("keybind")
    local mkColor = use("colorpicker")
    local mkProgress = use("progress")
    local mkSegmented = use("segmented")
    local mkRadio = use("radio")
    local mkStepper = use("stepper")
    local mkImage = use("image")
    local mkStat = use("stat")
    local mkButtonRow = use("buttonrow")
    local mkAccordion = use("accordion")
    local mkRange = use("rangeslider")
    local mkTable = use("datatable")
    local mkIconGallery = use("icongallery")
    local mkConfigManager = use("configmanager")
    local Text = use("text")

    local Tab = {}
    Tab.__index = Tab

    local function reg(self, o, comp)
        o = o or {}
        self.win:track(o.Flag, comp)
        if comp and comp.Instance then
            C.makeToggleable(self.win, comp)
            if o.Title and o.Title ~= "" then self.win:indexEntry(o.Title, self.tab, comp) end
            if o.Tooltip then self.win:wireTooltip(comp.Instance, o.Tooltip) end
            if o.Depends then self.win:_addDepend(comp, o.Depends, o.DependsValue) end
            if o.Disabled then comp:SetEnabled(false) end
            if o.Visible == false then comp:SetVisible(false) end
        end
        return comp
    end

    function Tab:_target() return self._section or self.page end
    function Tab:Section(o) local s = Text.section(self.win, self.page, o) self._section = s.content return s end
    function Tab:Divider() return Text.divider(self.win, self.page) end
    function Tab:Label(t) return Text.label(self.win, self:_target(), t) end
    function Tab:Paragraph(o) return Text.paragraph(self.win, self:_target(), o) end
    function Tab:Button(o) return reg(self, o, mkButton(self.win, self:_target(), o)) end
    function Tab:Toggle(o) return reg(self, o, mkToggle(self.win, self:_target(), o)) end
    function Tab:Slider(o) return reg(self, o, mkSlider(self.win, self:_target(), o)) end
    function Tab:Dropdown(o) return reg(self, o, mkDropdown(self.win, self:_target(), o)) end
    function Tab:Input(o) return reg(self, o, mkInput(self.win, self:_target(), o)) end
    function Tab:Keybind(o) return reg(self, o, mkKeybind(self.win, self:_target(), o)) end
    function Tab:Colorpicker(o) return reg(self, o, mkColor(self.win, self:_target(), o)) end
    function Tab:Progress(o) return reg(self, o, mkProgress(self.win, self:_target(), o)) end
    function Tab:Segmented(o) return reg(self, o, mkSegmented(self.win, self:_target(), o)) end
    function Tab:Radio(o) return reg(self, o, mkRadio(self.win, self:_target(), o)) end
    function Tab:Stepper(o) return reg(self, o, mkStepper(self.win, self:_target(), o)) end
    function Tab:Image(o) return reg(self, o, mkImage(self.win, self:_target(), o)) end
    function Tab:Stat(o) return reg(self, o, mkStat(self.win, self:_target(), o)) end
    function Tab:Buttons(o) return reg(self, o, mkButtonRow(self.win, self:_target(), o)) end
    function Tab:RangeSlider(o) return reg(self, o, mkRange(self.win, self:_target(), o)) end
    function Tab:Table(o) return reg(self, o, mkTable(self.win, self:_target(), o)) end
    function Tab:IconGallery(o) return reg(self, o, mkIconGallery(self.win, self:_target(), o)) end
    function Tab:Flyout(o) return self.win:Flyout(o) end
    function Tab:ConfigManager(o) return mkConfigManager(self.win, self:_target(), o) end
    function Tab:Accordion(o)
        local acc = mkAccordion(self.win, self.page, o or {})
        local sub = setmetatable({ win = self.win, page = acc.content, tab = self.tab, _acc = acc }, Tab)
        sub.Expand = function() acc.Open() end
        sub.Collapse = function() acc.Close() end
        sub.SetOpen = function(_, v) if v then acc.Open() else acc.Close() end end
        sub.Instance = acc.Instance
        return sub
    end

    return Tab
end
M["flyout"] = function(use, BPUI)
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
M["window"] = function(use, BPUI)
    local C = use("core")
    local Theme = use("theme")
    local Icons = use("icons")
    local Tab = use("tab")
    local mkFlyout = use("flyout")
    local new, corner, stroke, pad, list, tw, txt, hoverable = C.new, C.corner, C.stroke, C.pad, C.list, C.tw, C.txt, C.hoverable
    local Maid, UIS, TS = C.Maid, C.UIS, C.TS
    local IS_TOUCH, HAS_MOUSE = C.IS_TOUCH, C.HAS_MOUSE
    local viewport, insetTop = C.viewport, C.insetTop

    local Window = {}
    Window.__index = Window

    function Window:paint(inst, prop, key) self._paint[#self._paint + 1] = { inst, prop, key } inst[prop] = self.Theme[key] return inst end
    function Window:onTheme(fn) self._reskin[#self._reskin + 1] = fn end
    function Window:track(flag, comp) if flag then self.Flags[flag] = comp comp._flag = flag end return comp end
    function Window:indexEntry(title, tab, comp)
        if not (title and title ~= "" and comp and comp.Instance) then return end
        self._index[#self._index + 1] = { title = title, tab = tab, instance = comp.Instance }
    end
    function Window:wireTooltip(inst, text) C.tooltip(self, inst, text) end
    function Window:pulseLogo() end
    function Window:_addDepend(comp, flag, value)
        if not (comp and comp.SetEnabled and flag) then return end
        self._depends[#self._depends + 1] = { comp = comp, flag = flag, value = value }
        self:_evalDepends()
    end
    function Window:_evalDepends()
        for _, d in ipairs(self._depends) do
            local src = self.Flags[d.flag]
            if src and src.Get then
                local ok, v = pcall(src.Get, src)
                if ok then
                    local pass
                    if d.value ~= nil then pass = (v == d.value)
                    else
                        pass = v and v ~= false
                        if type(v) == "table" then pass = #v > 0 end
                    end
                    pcall(function() d.comp:SetEnabled(pass and true or false) end)
                end
            end
        end
    end
    function Window:refreshDepends() self:_evalDepends() end

    local function serial(c)
        local v = c:Get()
        if c.kind == "color" then return { __c3 = true, r = v.R, g = v.G, b = v.B } end
        return v
    end
    local function deserial(c, raw)
        if c.kind == "color" and type(raw) == "table" and raw.__c3 then c:Set(Color3.new(raw.r, raw.g, raw.b), true) return end
        c:Set(raw, true)
    end
    function Window:save()
        if self._depends[1] then self:_evalDepends() end
        if not (self.cfg and self.cfg.Enabled and C.hasFS) then return end
        if self._saveQ then return end
        self._saveQ = true
        task.delay(0.4, function()
            self._saveQ = false
            local data = {}
            for flag, c in pairs(self.Flags) do if c.Get then local ok, v = pcall(serial, c) if ok then data[flag] = v end end end
            if self.cfg.SaveWindowState ~= false and self.holder then
                data.__bpui = { x = self.holder.Position.X.Offset, y = self.holder.Position.Y.Offset,
                    w = self._size.X.Offset, h = self._size.Y.Offset, tab = self.current and self.current.name or nil }
            end
            pcall(function() writefile(self.cfgPath, C.HttpService:JSONEncode(data)) end)
        end)
    end
    function Window:_applyWinState(ws)
        if type(ws) ~= "table" then return end
        local vp = viewport()
        if ws.w and ws.h then
            local nw, nh = C.safeWindowSize(UDim2.fromOffset(ws.w, ws.h), UDim2.fromOffset(360, 280))
            self._size = UDim2.fromOffset(nw, nh)
            self.holder.Size = self._size
        end
        if ws.x and ws.y then
            local ox = math.clamp(ws.x, -(vp.X / 2) + 40, (vp.X / 2) - 40)
            local oy = math.clamp(ws.y, -(vp.Y / 2) + 40, (vp.Y / 2) - 40)
            self.holder.Position = UDim2.new(0.5, ox, 0.5, oy)
        end
        if ws.tab then self:SelectTab(ws.tab) end
    end
    function Window:loadConfig()
        if not (self.cfg and self.cfg.Enabled and C.hasFS) then return end
        local okf, ex = pcall(isfile, self.cfgPath)
        if not (okf and ex) then return end
        local ok, data = pcall(function() return C.HttpService:JSONDecode(readfile(self.cfgPath)) end)
        if not ok or type(data) ~= "table" then return end
        if self.cfg.SaveWindowState ~= false then pcall(function() self:_applyWinState(data.__bpui) end) end
        for flag, raw in pairs(data) do
            if flag ~= "__bpui" then
                local c = self.Flags[flag]
                if c and c.Set then pcall(deserial, c, raw) end
            end
        end
    end

    function Window:_collectData()
        local data = {}
        for flag, c in pairs(self.Flags) do if c.Get then local ok, v = pcall(serial, c) if ok then data[flag] = v end end end
        return data
    end
    function Window:_applyData(data)
        if type(data) ~= "table" then return end
        for flag, raw in pairs(data) do
            if flag ~= "__bpui" then
                local c = self.Flags[flag]
                if c and c.Set then pcall(deserial, c, raw) end
            end
        end
        self:_evalDepends()
    end
    function Window:_ensureDirs()
        if not C.hasFS then return end
        pcall(function() if not isfolder("BPUI") then makefolder("BPUI") end end)
        pcall(function() if not isfolder(self._cfgFolder) then makefolder(self._cfgFolder) end end)
        pcall(function() if not isfolder(self.profileDir) then makefolder(self.profileDir) end end)
    end
    function Window:_profilePath(name) return self.profileDir .. "/" .. name .. ".json" end
    function Window:SaveConfig(name)
        if not (C.hasFS and name and name ~= "") then return false end
        self:_ensureDirs()
        return (pcall(function() writefile(self:_profilePath(name), C.HttpService:JSONEncode(self:_collectData())) end))
    end
    function Window:LoadConfigByName(name)
        if not (C.hasFS and name) then return false end
        local p = self:_profilePath(name)
        local okf, ex = pcall(isfile, p)
        if not (okf and ex) then return false end
        local ok, data = pcall(function() return C.HttpService:JSONDecode(readfile(p)) end)
        if ok and type(data) == "table" then self:_applyData(data) self:save() return true end
        return false
    end
    function Window:DeleteConfig(name)
        if not (C.hasFS and name and delfile) then return false end
        local p = self:_profilePath(name)
        local okf, ex = pcall(isfile, p)
        if okf and ex then return (pcall(function() delfile(p) end)) end
        return false
    end
    function Window:ListConfigs()
        local out = {}
        if not (C.hasFS and listfiles) then return out end
        local ok, files = pcall(function() return listfiles(self.profileDir) end)
        if ok and files then
            for _, p in ipairs(files) do
                local nm = tostring(p):match("([^/\\]+)%.json$")
                if nm then out[#out + 1] = nm end
            end
        end
        table.sort(out)
        return out
    end
    function Window:ExportConfig()
        return "BPUI1:" .. C.b64encode(C.HttpService:JSONEncode(self:_collectData()))
    end
    function Window:ImportConfig(code)
        if type(code) ~= "string" then return false end
        code = code:gsub("^%s+", ""):gsub("%s+$", "")
        local body = code:match("^BPUI1:(.+)$") or code
        local ok, json = pcall(C.b64decode, body)
        if not ok or not json or json == "" then return false end
        local ok2, data = pcall(function() return C.HttpService:JSONDecode(json) end)
        if not ok2 or type(data) ~= "table" then return false end
        self:_applyData(data) self:save()
        return true
    end

    function Window:SetTheme(arg)
        local name = Theme.apply(self.Theme, arg)
        if name then self.themeName = name end
        local live = {}
        for _, e in ipairs(self._paint) do
            if e[1] and e[1].Parent then live[#live + 1] = e pcall(function() tw(e[1], 0.2, { [e[2]] = self.Theme[e[3]] }) end) end
        end
        self._paint = live
        for _, fn in ipairs(self._reskin) do pcall(fn) end
        if self.current then pcall(function() self:SelectTab(self.current) end) end
    end

    function Window:SelectTab(target)
        for _, t in ipairs(self.tabs) do
            local on = (t == target) or (type(target) == "string" and t.name == target)
            t.page.Visible = on
            if t.acc then
                t.acc.BackgroundColor3 = on and self.Theme.Hover:Lerp(self.Theme.Accent, 0.22) or self.Theme.Hover
                tw(t.acc, 0.18, { BackgroundTransparency = on and 0.18 or 1 })
            end
            Icons.tint(t.ico, t.iconKind, on and self.Theme.Accent or self.Theme.Sub)
            tw(t.lbl, 0.15, { TextColor3 = on and self.Theme.Text or self.Theme.Sub })
            tw(t.bar, 0.2, { BackgroundTransparency = on and 0 or 1, Size = on and UDim2.fromOffset(3, 18) or UDim2.fromOffset(3, 0) })
            if t.barGlow then tw(t.barGlow, 0.22, { ImageTransparency = on and 0.45 or 1 }) end
            if on then self.current = t end
        end
    end

    local function railExpand(win, on)
        win._railOpen = on
        tw(win.rail, 0.2, { Size = UDim2.new(0, on and (win._railWide or 188) or (win._railClosed or 56), 1, -52) })
        for _, t in ipairs(win.tabs) do tw(t.lbl, 0.2, { TextTransparency = on and 0 or 1 }) end
        for _, hl in ipairs(win._headers) do tw(hl, 0.2, { TextTransparency = on and 0 or 1 }) end
        tw(win.brand, 0.2, { TextTransparency = on and 0 or 1 })
        if win.footer then tw(win.footer, 0.2, { TextTransparency = on and 0 or 1 }) end
    end

    function Window:Tab(o)
        o = o or {}
        if o.Group and not self._railGroups[o.Group] then
            self._railGroups[o.Group] = true
            self._railOrder += 1
            local hdr = txt(self.railList, string.upper(o.Group), 11, self.Theme.Dim, Enum.Font.GothamBold,
                { Size = UDim2.new(1, 0, 0, 24), LayoutOrder = self._railOrder, TextTransparency = self._railOpen and 0 or 1 })
            pad(hdr, 16, 0, 8, 0)
            self:paint(hdr, "TextColor3", "Dim")
            self._headers[#self._headers + 1] = hdr
        end
        self._railOrder += 1
        local i = #self.tabs + 1
        local btn = new("TextButton", { Parent = self.railList, Size = UDim2.new(1, 0, 0, 42), BackgroundColor3 = self.Theme.Panel2,
            BackgroundTransparency = 1, Text = "", AutoButtonColor = false, LayoutOrder = self._railOrder })
        corner(btn, 8)
        local acc = new("Frame", { Parent = btn, Size = UDim2.new(1, -10, 1, 0), Position = UDim2.fromOffset(5, 0), BackgroundColor3 = self.Theme.Hover, BackgroundTransparency = 1 })
        corner(acc, 7)
        C.gloss(acc, 0.84)
        self:paint(acc, "BackgroundColor3", "Hover")
        local barGlow = new("ImageLabel", { Parent = btn, BackgroundTransparency = 1, Image = "rbxassetid://6014261993",
            ScaleType = Enum.ScaleType.Slice, SliceCenter = Rect.new(49, 49, 450, 450), ImageColor3 = self.Theme.Accent,
            ImageTransparency = 1, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, -5, 0.5, 0),
            Size = UDim2.fromOffset(24, 30), ZIndex = 1, BorderSizePixel = 0 })
        self:paint(barGlow, "ImageColor3", "Accent")
        local bar = new("Frame", { Parent = btn, Size = UDim2.fromOffset(3, 0), AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 2, 0.5, 0),
            BackgroundColor3 = self.Theme.Accent, BackgroundTransparency = 1, ZIndex = 2 })
        corner(bar, 2)
        self:paint(bar, "BackgroundColor3", "Accent")
        local ico, iconKind = Icons.make(btn, o.Icon or "dot", { size = UDim2.fromOffset(24, 22), position = UDim2.fromOffset(18, 10), color = self.Theme.Sub, textSize = 18, zindex = 2 })
        local lbl = txt(btn, o.Title or ("Tab " .. i), 14, self.Theme.Sub, Enum.Font.GothamMedium,
            { Size = UDim2.new(1, -54, 1, 0), Position = UDim2.fromOffset(50, 0), TextTransparency = self._railOpen and 0 or 1, ZIndex = 2 })
        local tabObj = { name = o.Title, btn = btn, ico = ico, iconKind = iconKind, lbl = lbl, bar = bar, acc = acc, barGlow = barGlow }
        hoverable(btn, function() if self.current ~= tabObj then tw(acc, 0.12, { BackgroundTransparency = 0.55 }) end end,
            function() if self.current ~= tabObj then tw(acc, 0.12, { BackgroundTransparency = 1 }) end end)
        local page = new("ScrollingFrame", { Parent = self.body, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0),
            Visible = false, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 3,
            ScrollBarImageColor3 = self.Theme.Accent, ScrollBarImageTransparency = 0.5, BorderSizePixel = 0 })
        if IS_TOUCH then pad(page, 12, 10, 12, 16) else pad(page, 16, 14, 16, 20) end
        list(page, IS_TOUCH and 8 or 10)
        tabObj.page = page
        self.tabs[#self.tabs + 1] = tabObj
        btn.MouseButton1Click:Connect(function() self:SelectTab(tabObj) self:save() if IS_TOUCH then railExpand(self, false) end end)
        if #self.tabs == 1 then self:SelectTab(tabObj) end
        return setmetatable({ win = self, page = page, tab = tabObj }, Tab)
    end

    function Window:Flyout(o) return mkFlyout(self, o or {}) end

    function Window:Palette()
        if self._paletteOpen then return end
        self._paletteOpen = true
        local pm = Maid.new()
        self._palMaid = pm
        local first
        local dim = new("Frame", { Parent = self.gui, Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0),
            BackgroundTransparency = 1, ZIndex = 210, Active = true })
        local function shut()
            if not self._paletteOpen then return end
            self._paletteOpen = false
            pm:clean()
            if self._palMaid == pm then self._palMaid = nil end
            tw(dim, 0.14, { BackgroundTransparency = 1 })
            task.delay(0.16, function() if dim then dim:Destroy() end end)
        end
        tw(dim, 0.16, { BackgroundTransparency = 0.5 })
        local W = C.safePopupWidth(460, 40, 260)
        local card = new("Frame", { Parent = dim, AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.new(0.5, 0, 0, math.max(insetTop() + 30, viewport().Y * 0.14)),
            Size = UDim2.fromOffset(W, 52), BackgroundColor3 = self.Theme.Bg, ZIndex = 211, ClipsDescendants = true })
        corner(card, 12) stroke(card, self.Theme.Stroke, 1, 0.15)
        C.glow(card, self.Theme.Accent, 0.82, 16)
        local srow = new("Frame", { Parent = card, BackgroundTransparency = 1, Size = UDim2.new(1, -20, 0, 44), Position = UDim2.fromOffset(10, 4), ZIndex = 212 })
        txt(srow, Icons.emoji.search, 18, self.Theme.Sub, Enum.Font.GothamBold,
            { Size = UDim2.fromOffset(24, 44), Position = UDim2.fromOffset(2, 0), TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 213 })
        local tb = new("TextBox", { Parent = srow, BackgroundTransparency = 1, Size = UDim2.new(1, -34, 1, 0), Position = UDim2.fromOffset(30, 0),
            Font = C.uifont(Enum.Font.GothamMedium), TextSize = 15, TextColor3 = self.Theme.Text, PlaceholderText = "Search controls...", PlaceholderColor3 = self.Theme.Dim,
            Text = "", ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 213 })
        local listFrame = new("ScrollingFrame", { Parent = card, BackgroundTransparency = 1, Position = UDim2.fromOffset(6, 50),
            Size = UDim2.new(1, -12, 1, -56), CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 3,
            ScrollBarImageColor3 = self.Theme.Accent, ScrollBarImageTransparency = 0.4, BorderSizePixel = 0, ZIndex = 212 })
        pad(listFrame, 4, 4, 2, 4) list(listFrame, 3)
        local entries = {}
        for _, t in ipairs(self.tabs) do entries[#entries + 1] = { title = t.name or "Tab", tab = t, isTab = true } end
        for _, e in ipairs(self._index) do entries[#entries + 1] = e end
        local results = {}
        local function fill(q)
            for _, r in ipairs(results) do r:Destroy() end
            results = {} first = nil
            q = (q or ""):lower()
            local count = 0
            for _, e in ipairs(entries) do
                local hay = ((e.title or "") .. " " .. ((e.tab and e.tab.name) or "")):lower()
                if q == "" or hay:find(q, 1, true) then
                    count += 1
                    if not first then first = e end
                    if count <= 60 then
                        local it = new("TextButton", { Parent = listFrame, BackgroundColor3 = self.Theme.Panel, BackgroundTransparency = 1,
                            Text = "", AutoButtonColor = false, Size = UDim2.new(1, 0, 0, 34), ZIndex = 213 })
                        corner(it, 7)
                        txt(it, e.title or "", 13, self.Theme.Text, Enum.Font.GothamMedium,
                            { Size = UDim2.new(1, -92, 1, 0), Position = UDim2.fromOffset(12, 0), TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 214 })
                        txt(it, e.isTab and "Tab" or ((e.tab and e.tab.name) or ""), 11, self.Theme.Sub, Enum.Font.Gotham,
                            { Size = UDim2.new(0, 78, 1, 0), Position = UDim2.new(1, -84, 0, 0), TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 214 })
                        hoverable(it, function() tw(it, 0.1, { BackgroundTransparency = 0.45 }) end, function() tw(it, 0.1, { BackgroundTransparency = 1 }) end)
                        local cap = e
                        it.MouseButton1Click:Connect(function() shut() self:jumpTo(cap) end)
                        results[#results + 1] = it
                    end
                end
            end
            local rows = math.clamp(count, 0, 7)
            tw(card, 0.14, { Size = UDim2.fromOffset(W, 52 + (rows == 0 and 0 or (rows * 37 + 6))) })
        end
        tb:GetPropertyChangedSignal("Text"):Connect(function() fill(tb.Text) end)
        pm:give(UIS.InputBegan:Connect(function(i, gpe)
            if i.KeyCode == Enum.KeyCode.Escape then shut()
            elseif i.KeyCode == Enum.KeyCode.Return and first then local f = first shut() self:jumpTo(f) end
        end))
        dim.InputBegan:Connect(function(i)
            if C.isPress(i) then
                local mp = i.Position local p, s = card.AbsolutePosition, card.AbsoluteSize
                if not (mp.X >= p.X and mp.X <= p.X + s.X and mp.Y >= p.Y and mp.Y <= p.Y + s.Y) then shut() end
            end
        end)
        fill("")
        task.defer(function() pcall(function() tb:CaptureFocus() end) end)
    end

    function Window:jumpTo(entry)
        if not entry then return end
        if self._min then self:Restore() elseif not self._visible then self:SetVisible(true) end
        if entry.tab then self:SelectTab(entry.tab) end
        local inst = entry.instance
        if not inst then return end
        task.defer(function()
            if not inst.Parent then return end
            local page = entry.tab and entry.tab.page
            if page then
                local rel = inst.AbsolutePosition.Y - page.AbsolutePosition.Y + page.CanvasPosition.Y
                tw(page, 0.3, { CanvasPosition = Vector2.new(0, math.max(0, rel - 12)) })
            end
            local hl = new("Frame", { Parent = inst, BackgroundColor3 = self.Theme.Accent, BackgroundTransparency = 0.7,
                Size = UDim2.fromScale(1, 1), ZIndex = 40 })
            corner(hl, 9)
            tw(hl, 0.55, { BackgroundTransparency = 1 })
            task.delay(0.6, function() if hl then hl:Destroy() end end)
        end)
    end

    function Window:Notify(o)
        o = o or {}
        self:pulseLogo()
        local variants = {
            success = { self.Theme.Good, "check" }, warning = { self.Theme.Warn, "warning" },
            error = { self.Theme.Bad, "cross" }, info = { self.Theme.Accent, "info" }, loading = { self.Theme.Accent, "refresh" },
        }
        local vv = variants[o.Type]
        local accentCol = (vv and vv[1]) or self.Theme.Accent
        local loading = o.Type == "loading"
        local card = new("Frame", { Parent = self.notif, BackgroundColor3 = self.Theme.Bg2, Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1 })
        corner(card, 9)
        local cs = stroke(card, self.Theme.Stroke, 1, 0.2)
        local accent = new("Frame", { Parent = card, Size = UDim2.new(0, 4, 1, 0), BackgroundColor3 = accentCol, BackgroundTransparency = 1 })
        corner(accent, 2)
        local body = new("Frame", { Parent = card, BackgroundTransparency = 1, Size = UDim2.new(1, -12, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y, Position = UDim2.fromOffset(12, 0) })
        pad(body, 0, 10, 10, 10) list(body, 5)
        local d = Icons.resolve(o.Icon or (vv and vv[2]) or "bell")
        local titleRow = new("Frame", { Parent = body, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 18), LayoutOrder = 1 })
        local tx = 0
        if d.kind == "image" then
            local img = new("ImageLabel", { Parent = titleRow, BackgroundTransparency = 1, Image = d.image, Size = UDim2.fromOffset(16, 16),
                AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0), ImageColor3 = accentCol })
            if d.rect then img.ImageRectOffset = d.rect.Min img.ImageRectSize = d.rect.Max - d.rect.Min end
            tx = 22
        end
        local t = txt(titleRow, (d.kind == "text" and (d.text .. "  ") or "") .. (o.Title or "Notice"), 14, self.Theme.Text, Enum.Font.GothamBold,
            { Size = UDim2.new(1, -tx, 1, 0), Position = UDim2.fromOffset(tx, 0), TextTruncate = Enum.TextTruncate.AtEnd })
        local c
        if o.Content and o.Content ~= "" then
            c = txt(body, o.Content, 12, self.Theme.Sub, Enum.Font.Gotham,
                { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextWrapped = true,
                  TextYAlignment = Enum.TextYAlignment.Top, LayoutOrder = 2 })
        end
        local alive = true
        local segTween
        local function doClose()
            if not alive then return end alive = false
            if segTween then pcall(function() segTween:Cancel() end) end
            if card and card.Parent then
                tw(card, 0.22, { BackgroundTransparency = 1 }) tw(cs, 0.22, { Transparency = 1 })
                tw(t, 0.22, { TextTransparency = 1 }) tw(accent, 0.22, { BackgroundTransparency = 1 })
                if c then tw(c, 0.22, { TextTransparency = 1 }) end
                task.delay(0.26, function() if card then card:Destroy() end end)
            end
        end
        local hasButtons = type(o.Buttons) == "table" and #o.Buttons > 0
        if hasButtons then
            local brow = new("Frame", { Parent = body, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 28), LayoutOrder = 3 })
            list(brow, 6, Enum.FillDirection.Horizontal)
            for _, b in ipairs(o.Buttons) do
                local prim = b.Variant == "primary"
                local bb = new("TextButton", { Parent = brow, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0, 0, 1, 0),
                    BackgroundColor3 = prim and accentCol or self.Theme.Panel2, Text = "", AutoButtonColor = false, ClipsDescendants = true })
                corner(bb, 6) pad(bb, 12, 12, 0, 0)
                if not prim then stroke(bb, self.Theme.Stroke, 1, 0.4) end
                txt(bb, b.Title or "OK", 12, prim and self.Theme.OnAccent or self.Theme.Text, Enum.Font.GothamBold,
                    { Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, TextXAlignment = Enum.TextXAlignment.Center })
                C.ripple(bb, Color3.fromRGB(255, 255, 255))
                C.press(bb, { radius = 6 })
                bb.MouseButton1Click:Connect(function() local ok, keep = pcall(b.Callback) if not (ok and keep) then doClose() end end)
            end
        end
        local barFill
        local hasTimer = (not loading) and (o.Duration ~= false) and (not hasButtons)
        if loading or hasTimer then
            local track = new("Frame", { Parent = body, BackgroundColor3 = self.Theme.Panel2, Size = UDim2.new(1, 0, 0, 2),
                LayoutOrder = 4, BackgroundTransparency = 0.4, ClipsDescendants = true })
            corner(track, 1)
            barFill = new("Frame", { Parent = track, BackgroundColor3 = accentCol,
                Size = loading and UDim2.new(0.35, 0, 1, 0) or UDim2.new(1, 0, 1, 0) })
            corner(barFill, 1)
            if loading then
                barFill.Position = UDim2.new(-0.35, 0, 0, 0)
                segTween = TS:Create(barFill, TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, false),
                    { Position = UDim2.new(1, 0, 0, 0) })
                segTween:Play()
            end
        end
        task.defer(function() tw(card, 0.2, { BackgroundTransparency = 0 }) tw(accent, 0.2, { BackgroundTransparency = 0 }) end)
        if hasTimer then
            local dur = o.Duration or 4
            if barFill then tw(barFill, dur, { Size = UDim2.new(0, 0, 1, 0) }, Enum.EasingStyle.Linear) end
            task.delay(dur, doClose)
        end
        return {
            Close = function() doClose() end,
            SetTitle = function(_, s) t.Text = (d.kind == "text" and (d.text .. "  ") or "") .. tostring(s) end,
            SetContent = function(_, s) if c then c.Text = tostring(s) end end,
            SetProgress = function(_, p)
                if not barFill then return end
                if segTween then pcall(function() segTween:Cancel() end) segTween = nil end
                barFill.Position = UDim2.new(0, 0, 0, 0)
                tw(barFill, 0.2, { Size = UDim2.new(math.clamp(p or 0, 0, 1), 0, 1, 0) })
            end,
        }
    end

    function Window:Dialog(o)
        o = o or {}
        local dim = new("Frame", { Parent = self.gui, Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0),
            BackgroundTransparency = 1, ZIndex = 200, Active = true })
        local closed = false
        local function shut()
            if closed then return end closed = true
            tw(dim, 0.18, { BackgroundTransparency = 1 })
            task.delay(0.2, function() dim:Destroy() end)
        end
        tw(dim, 0.2, { BackgroundTransparency = 0.45 })
        local W = C.safePopupWidth(o.Width or 380, 40, 260)
        local card = new("Frame", { Parent = dim, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(W, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = self.Theme.Bg, ZIndex = 201 })
        corner(card, 12) stroke(card, self.Theme.Stroke, 1, 0.2)
        pad(card, 22, 22, 20, 18) list(card, 12)
        txt(card, o.Title or "Confirm", 18, self.Theme.Text, Enum.Font.GothamBold, { Size = UDim2.new(1, 0, 0, 24), ZIndex = 202, LayoutOrder = 1 })
        if o.Content and o.Content ~= "" then
            txt(card, o.Content, 13, self.Theme.Sub, Enum.Font.Gotham, { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
                TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 202, LayoutOrder = 2 })
        end
        local row = new("Frame", { Parent = card, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 34), ZIndex = 202, LayoutOrder = 3 })
        new("UIListLayout", { Parent = row, FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Right,
            VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder })
        local btns = o.Buttons or { { Title = "OK" } }
        for idx, b in ipairs(btns) do
            local variant = b.Variant or (idx == 1 and "primary" or "default")
            local bg = (variant == "primary" and self.Theme.Accent) or (variant == "danger" and self.Theme.Bad) or self.Theme.Panel2
            local fg = (variant == "primary" and self.Theme.OnAccent) or (variant == "danger" and Color3.new(1, 1, 1)) or self.Theme.Text
            local bw = math.clamp(#(b.Title or "OK") * 8 + 32, 76, math.max(76, W - 60))
            local bb = new("TextButton", { Parent = row, Size = UDim2.fromOffset(bw, 34), BackgroundColor3 = bg, Text = b.Title or "OK",
                Font = C.uifont(Enum.Font.GothamBold), TextSize = 13, TextColor3 = fg, AutoButtonColor = false, ZIndex = 203, LayoutOrder = idx, ClipsDescendants = true })
            corner(bb, 6)
            C.ripple(bb, Color3.new(1, 1, 1))
            C.press(bb, { radius = 6 })
            if variant == "default" then stroke(bb, self.Theme.Stroke, 1, 0.4) end
            bb.MouseButton1Click:Connect(function()
                local ok, keep = pcall(b.Callback)
                if not (ok and keep) then shut() end
            end)
        end
        if o.DismissOnClickOutside then
            dim.InputBegan:Connect(function(i) if C.isPress(i) then
                local mp = i.Position local p, sz = card.AbsolutePosition, card.AbsoluteSize
                if not (mp.X >= p.X and mp.X <= p.X + sz.X and mp.Y >= p.Y and mp.Y <= p.Y + sz.Y) then shut() end
            end end)
        end
        return { Close = shut }
    end

    function Window:Minimize()
        if self._min then return end
        self._min = true self._visible = false
        if self._closePopup then pcall(self._closePopup) end
        tw(self.root, 0.16, { GroupTransparency = 1 })
        tw(self.root, 0.18, { Position = UDim2.fromOffset(0, 8) })
        if self.blur then tw(self.blur, 0.2, { Size = 0 }) end
        task.delay(0.2, function() if self._min then self.holder.Visible = false end end)
        self.pill.Visible = true self.pill.GroupTransparency = 1
        tw(self.pill, 0.18, { GroupTransparency = 0 })
    end
    function Window:Restore()
        if not self._min then return end
        self._min = false
        tw(self.pill, 0.16, { GroupTransparency = 1 })
        task.delay(0.18, function() if not self._min then self.pill.Visible = false end end)
        self:SetVisible(true)
    end

    function Window:Toggle()
        if self._min then self:Restore() else self:SetVisible(not self._visible) end
    end
    function Window:SetVisible(v)
        self._visible = v
        if not v and self._closePopup then pcall(self._closePopup) end
        if v then
            self.holder.Visible = true self.root.GroupTransparency = 1 self.root.Position = UDim2.fromOffset(0, 10)
            tw(self.root, 0.22, { GroupTransparency = 0 })
            tw(self.root, 0.3, { Position = UDim2.fromOffset(0, 0) })
            if self.blur then tw(self.blur, 0.3, { Size = self._blurSize }) end
        else
            tw(self.root, 0.16, { GroupTransparency = 1 })
            tw(self.root, 0.18, { Position = UDim2.fromOffset(0, 8) })
            if self.blur then tw(self.blur, 0.2, { Size = 0 }) end
            task.delay(0.2, function() if not self._visible then self.holder.Visible = false end end)
        end
    end
    function Window:Destroy()
        if self._destroyed then return end
        self._destroyed = true
        for i = #BPUI._windows, 1, -1 do
            if BPUI._windows[i] == self then table.remove(BPUI._windows, i) end
        end
        self.maid:clean()
        pcall(function() self.gui:Destroy() end)
        if self.blur then pcall(function() self.blur:Destroy() end) end
    end

    local function applyDrag(win, handle)
        local function clampW(offX, offY)
            local vp = viewport()
            local hh = win._size.Y.Offset
            offX = math.clamp(offX, -(vp.X / 2) + 40, (vp.X / 2) - 40)
            local minY = insetTop() - (vp.Y / 2) + (hh / 2) + 26
            local maxY = (vp.Y / 2) - 40
            offY = math.clamp(offY, math.min(minY, maxY), maxY)
            return offX, offY
        end
        local dragging, startP, startPos
        handle.InputBegan:Connect(function(i) if C.isPress(i) then dragging = true startP = i.Position startPos = win.holder.Position end end)
        win.maid:give(UIS.InputChanged:Connect(function(i)
            if dragging and C.isMove(i) then
                local d = i.Position - startP
                local ox, oy = clampW(startPos.X.Offset + d.X, startPos.Y.Offset + d.Y)
                win.holder.Position = UDim2.new(0.5, ox, 0.5, oy)
            end
        end))
        win.maid:give(UIS.InputEnded:Connect(function(i) if C.isPress(i) and dragging then dragging = false win:save() end end))
    end

    local function buildKeyGate(opts, onPass)
        local P = opts.Palette
        local gui = new("ScreenGui", { Name = "BPUI_Key", IgnoreGuiInset = true, ResetOnSpawn = false,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 9998 })
        C.protect(gui) gui.Parent = C.host()
        new("Frame", { Parent = gui, Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.3 })
        local hasLink = type(opts.GetKeyLink) == "string"
        local W = C.safePopupWidth(360, 32, 260)
        local card = new("Frame", { Parent = gui, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(W, hasLink and 256 or 220), BackgroundColor3 = P.Bg })
        corner(card, 12) stroke(card, P.Stroke, 1, 0.2)
        C.glow(card, opts.Accent or P.Accent, 0.82, 18)
        local accent = opts.Accent or P.Accent
        txt(card, (opts.Title or "BPUI") .. "  🔑", 20, P.Text, Enum.Font.GothamBold, { Size = UDim2.new(1, -40, 0, 26), Position = UDim2.fromOffset(20, 22) })
        txt(card, opts.Note or "Enter your access key to continue", 13, P.Sub, Enum.Font.Gotham, { Size = UDim2.new(1, -40, 0, 18), Position = UDim2.fromOffset(20, 52) })
        local box = new("Frame", { Parent = card, BackgroundColor3 = P.Panel, Size = UDim2.new(1, -40, 0, 40), Position = UDim2.fromOffset(20, 92) })
        corner(box, 8) local bs = stroke(box, P.Stroke, 1, 0.4)
        local tb = new("TextBox", { Parent = box, BackgroundTransparency = 1, Size = UDim2.new(1, -20, 1, 0), Position = UDim2.fromOffset(12, 0),
            Font = Enum.Font.GothamMedium, TextSize = 14, TextColor3 = P.Text, PlaceholderText = "Key...", PlaceholderColor3 = P.Dim,
            Text = "", ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left })
        tb.Focused:Connect(function() tw(bs, 0.15, { Color = accent, Transparency = 0 }) end)
        tb.FocusLost:Connect(function() tw(bs, 0.15, { Color = P.Stroke, Transparency = 0.4 }) end)
        local status = txt(card, "", 12, P.Bad, Enum.Font.GothamMedium, { Size = UDim2.new(1, -40, 0, 16), Position = UDim2.fromOffset(20, 140) })
        local submit = new("TextButton", { Parent = card, BackgroundColor3 = accent, Size = UDim2.new(1, -40, 0, 38), Position = UDim2.fromOffset(20, 166),
            Text = "Unlock", Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = P.OnAccent, AutoButtonColor = false })
        corner(submit, 8) C.ripple(submit, Color3.new(1, 1, 1)) C.press(submit, { radius = 8 })
        if hasLink then
            local gk = new("TextButton", { Parent = card, BackgroundColor3 = P.Panel, Size = UDim2.new(1, -40, 0, 32), Position = UDim2.fromOffset(20, 210),
                Text = "Get Key (copy link)", Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = P.Sub, AutoButtonColor = false })
            corner(gk, 8)
            gk.MouseButton1Click:Connect(function() pcall(function() (setclipboard or set_clipboard)(opts.GetKeyLink) end) status.TextColor3 = P.Good status.Text = "Link copied" end)
        end
        local function check()
            local k = tb.Text
            local ok = false
            for _, val in ipairs(opts.Keys or {}) do if k == val then ok = true break end end
            if type(opts.Validate) == "function" then local r pcall(function() r = opts.Validate(k) end) if r then ok = true end end
            if ok then tw(card, 0.2, { BackgroundTransparency = 1 }) gui:Destroy() onPass()
            else status.TextColor3 = P.Bad status.Text = "Invalid key"
                tw(box, 0.05, { Position = UDim2.fromOffset(26, 92) })
                task.delay(0.05, function() tw(box, 0.05, { Position = UDim2.fromOffset(20, 92) }) end) end
        end
        submit.MouseButton1Click:Connect(check)
        tb.FocusLost:Connect(function(enter) if enter then check() end end)
    end

    function BPUI:Window(o)
        o = o or {}
        local self = setmetatable({}, Window)
        self.maid = Maid.new()
        self.tabs = {} self.Flags = {} self._paint = {} self._reskin = {} self._headers = {} self._railGroups = {} self._index = {} self._depends = {}
        self._railOpen = false self._railOrder = 0 self._min = false self._paletteOpen = false self._palMaid = nil
        self.maid:give(function() if self._palMaid then self._palMaid:clean() end end)
        self.themeName = (type(o.Theme) == "string" and o.Theme) or "Custom"
        self.Theme = Theme.resolve(o)
        self.cfg = o.ConfigSave or { Enabled = false }
        self._cfgFolder = "BPUI/" .. (self.cfg.Folder or "Configs")
        self.profileDir = self._cfgFolder .. "/profiles"
        if self.cfg.Enabled and C.hasFS then
            pcall(function() if not isfolder("BPUI") then makefolder("BPUI") end end)
            pcall(function() if not isfolder(self._cfgFolder) then makefolder(self._cfgFolder) end end)
            self.cfgPath = self._cfgFolder .. "/" .. (self.cfg.File or "config") .. ".json"
        end

        local hasTouch = IS_TOUCH
        local toggleKey = o.ToggleKey or Enum.KeyCode.RightShift
        local vp = viewport()
        local w, h = C.safeWindowSize(o.Size, o.MinSize)
        self._size = UDim2.fromOffset(w, h)

        local gui = new("ScreenGui", { Name = o.Name or "BPUI", IgnoreGuiInset = true, ResetOnSpawn = false,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 9999 })
        C.protect(gui) gui.Parent = C.host()
        self.gui = gui self.maid:give(gui)

        local glass = o.Acrylic == true
        self.glass = glass
        self._blurSize = glass and 14 or 0
        if glass then self.blur = new("BlurEffect", { Parent = C.Lighting, Size = 0 }) end

        local holder = new("Frame", { Parent = gui, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(w, h), BackgroundTransparency = 1 })
        self.holder = holder
        self._scale = new("UIScale", { Parent = holder, Scale = 1 })
        C.shadow(holder, 0.5, 16)

        local root = new("CanvasGroup", { Parent = holder, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 })
        self.root = root

        local shell = new("Frame", { Parent = root, Size = UDim2.fromScale(1, 1), BackgroundColor3 = self.Theme.Bg,
            BackgroundTransparency = glass and 0.05 or 0, ClipsDescendants = true })
        self.shell = shell
        corner(shell, 8)
        self:paint(shell, "BackgroundColor3", "Bg")
        local sStroke = stroke(shell, self.Theme.Stroke, 1, 0.25)
        self:paint(sStroke, "Color", "Stroke")

        local top = new("Frame", { Parent = shell, Size = UDim2.new(1, 0, 0, 52), BackgroundColor3 = self.Theme.Bg2, BackgroundTransparency = glass and 0.03 or 0 })
        self:paint(top, "BackgroundColor3", "Bg2")
        local logoInst, logoKind = Icons.make(top, o.Logo or "spark", { size = UDim2.fromOffset(28, 26), position = UDim2.fromOffset(16, 13), color = self.Theme.Accent, textSize = 22 })
        logoInst.ZIndex = 2
        self._logo, self._logoSize = logoInst, UDim2.fromOffset(28, 26)
        self:onTheme(function() Icons.tint(logoInst, logoKind, self.Theme.Accent) end)
        local tt = txt(top, o.Title or "BPUI", 17, self.Theme.Text, Enum.Font.GothamBold, { Size = UDim2.new(1, -152, 0, 20), Position = UDim2.fromOffset(50, 9), ZIndex = 2, TextTruncate = Enum.TextTruncate.AtEnd })
        self:paint(tt, "TextColor3", "Text")
        if o.Subtitle then
            local st = txt(top, o.Subtitle, 12, self.Theme.Sub, Enum.Font.Gotham, { Size = UDim2.new(1, -152, 0, 16), Position = UDim2.fromOffset(50, 28), ZIndex = 2, TextTruncate = Enum.TextTruncate.AtEnd })
            self:paint(st, "TextColor3", "Sub")
        end
        local edge = new("Frame", { Parent = top, Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1), BackgroundColor3 = self.Theme.Stroke, BackgroundTransparency = 0.3, ZIndex = 3 })
        self:paint(edge, "BackgroundColor3", "Stroke")
        local function topBtn(sym, x, col)
            local rest = IS_TOUCH and 0.85 or 1
            local sz = IS_TOUCH and 32 or 28
            local b = new("TextButton", { Parent = top, Size = UDim2.fromOffset(sz, sz), AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, x, 0.5, 0), BackgroundColor3 = self.Theme.Panel, BackgroundTransparency = rest,
                Text = sym, Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = self.Theme.Sub, AutoButtonColor = false, ZIndex = 4 })
            corner(b, IS_TOUCH and 8 or 7)
            self:paint(b, "BackgroundColor3", "Panel")
            hoverable(b, function() tw(b, 0.12, { BackgroundTransparency = 0, TextColor3 = col or self.Theme.Text }) end,
                function() tw(b, 0.12, { BackgroundTransparency = rest, TextColor3 = self.Theme.Sub }) end)
            return b
        end
        local closeB = topBtn(Icons.emoji.close, -12, self.Theme.Bad)
        closeB.MouseButton1Click:Connect(function() self:SetVisible(false) end)
        C.tooltip(self, closeB, "Hide  (" .. (typeof(toggleKey) == "EnumItem" and toggleKey.Name or "toggle") .. ")")
        local minB = topBtn(Icons.emoji.min, -48)
        minB.MouseButton1Click:Connect(function() self:Minimize() end)
        C.tooltip(self, minB, "Minimize")
        local searchB = topBtn(Icons.emoji.search, -84)
        searchB.MouseButton1Click:Connect(function() self:Palette() end)
        C.tooltip(self, searchB, "Search  Ctrl+K")
        applyDrag(self, top)

        local fixedRail = HAS_MOUSE
        local railW = fixedRail and math.clamp(math.floor(w * 0.26), 164, 188) or 56
        self._railWide = fixedRail and railW or math.min(188, math.max(156, w - 24))
        self._railClosed = 56
        self._railOpen = fixedRail
        local rail = new("Frame", { Parent = shell, Size = UDim2.new(0, railW, 1, -52), Position = UDim2.fromOffset(0, 52), BackgroundColor3 = self.Theme.Bg2, BackgroundTransparency = glass and 0.03 or 0, ZIndex = 5 })
        self.rail = rail
        self:paint(rail, "BackgroundColor3", "Bg2")
        local railDiv = new("Frame", { Parent = rail, Size = UDim2.new(0, 1, 1, 0), Position = UDim2.new(1, -1, 0, 0), BackgroundColor3 = self.Theme.Stroke, BackgroundTransparency = 0.4 })
        self:paint(railDiv, "BackgroundColor3", "Stroke")
        if not fixedRail then
            local railShadow = new("Frame", { Parent = rail, AnchorPoint = Vector2.new(0, 0), Position = UDim2.new(1, 0, 0, 0),
                Size = UDim2.new(0, 12, 1, 0), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0, ZIndex = 4 })
            new("UIGradient", { Parent = railShadow, Color = ColorSequence.new(Color3.new(0, 0, 0)),
                Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.74), NumberSequenceKeypoint.new(1, 1) }) })
        end
        self.brand = txt(rail, o.Title or "BPUI", 13, self.Theme.Sub, Enum.Font.GothamBold,
            { Size = UDim2.new(1, -28, 0, 16), Position = UDim2.fromOffset(16, 14), TextTransparency = fixedRail and 0 or 1 })
        self:paint(self.brand, "TextColor3", "Sub")
        local railList = new("ScrollingFrame", { Parent = rail, BackgroundTransparency = 1, Size = UDim2.new(1, -16, 1, -80),
            Position = UDim2.fromOffset(8, 42), CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 0, ZIndex = 6, BorderSizePixel = 0 })
        self.railList = railList
        list(railList, 4)
        pad(railList, 0, 0, 0, 6)
        self.footer = txt(rail, "BPUI v" .. (BPUI.Version or "2.0.0"), 11, self.Theme.Dim, Enum.Font.GothamMedium,
            { Size = UDim2.new(1, -16, 0, 16), Position = UDim2.new(0, 16, 1, -22), TextTransparency = fixedRail and 0 or 1 })
        self:paint(self.footer, "TextColor3", "Dim")

        local body = new("Frame", { Parent = shell, BackgroundColor3 = self.Theme.Bg, BackgroundTransparency = glass and 1 or 0, Size = UDim2.new(1, -railW, 1, -52), Position = UDim2.fromOffset(railW, 52) })
        self.body = body
        self:paint(body, "BackgroundColor3", "Bg")

        if not fixedRail then
            local handle = new("TextButton", { Parent = rail, Size = UDim2.fromOffset(48, 30), Position = UDim2.fromOffset(4, 4),
                BackgroundTransparency = 1, Text = Icons.emoji.menu, Font = Enum.Font.GothamBold, TextSize = 22, TextColor3 = self.Theme.Sub, ZIndex = 7, AutoButtonColor = false })
            handle.MouseButton1Click:Connect(function() railExpand(self, not self._railOpen) end)
        end

        local notifW = math.min(300, math.max(220, vp.X - 24))
        local notif = new("Frame", { Parent = gui, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 12),
            Size = UDim2.new(0, notifW, 1, -24), BackgroundTransparency = 1, ZIndex = 80 })
        self.notif = notif
        new("UIListLayout", { Parent = notif, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder,
            HorizontalAlignment = Enum.HorizontalAlignment.Right, VerticalAlignment = Enum.VerticalAlignment.Top })

        local pill = new("CanvasGroup", { Parent = gui, Visible = false, AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.fromOffset(20, vp.Y * 0.5), Size = UDim2.fromOffset(170, 44), BackgroundColor3 = self.Theme.Bg2, ZIndex = 95 })
        self.pill = pill
        corner(pill, 22)
        local pillStroke = stroke(pill, self.Theme.Accent, 1.5, 0.35)
        self:paint(pill, "BackgroundColor3", "Bg2")
        self:paint(pillStroke, "Color", "Accent")
        local pIco, pIcoK = Icons.make(pill, o.Logo or "spark", { size = UDim2.fromOffset(22, 22), anchor = Vector2.new(0, 0.5), position = UDim2.new(0, 16, 0.5, 0), color = self.Theme.Accent, textSize = 18 })
        self:onTheme(function() Icons.tint(pIco, pIcoK, self.Theme.Accent) end)
        local pTitle = txt(pill, o.Title or "BPUI", 14, self.Theme.Text, Enum.Font.GothamBold, { Size = UDim2.new(1, -56, 1, 0), Position = UDim2.fromOffset(44, 0), TextTruncate = Enum.TextTruncate.AtEnd })
        self:paint(pTitle, "TextColor3", "Text")
        local pBtn = new("TextButton", { Parent = pill, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Text = "", AutoButtonColor = false, ZIndex = 96 })
        do
            local dragging, moved, sP, sC
            pBtn.InputBegan:Connect(function(i) if C.isPress(i) then dragging = true moved = false sP = i.Position
                sC = Vector2.new(pill.Position.X.Offset, pill.Position.Y.Offset) end end)
            self.maid:give(UIS.InputChanged:Connect(function(i)
                if dragging and C.isMove(i) then
                    local d = i.Position - sP
                    if d.Magnitude > 6 then moved = true end
                    local vpc = viewport()
                    pill.Position = UDim2.fromOffset(math.clamp(sC.X + d.X, 10, math.max(10, vpc.X - 180)),
                        math.clamp(sC.Y + d.Y, 22 + insetTop(), math.max(22 + insetTop(), vpc.Y - 22)))
                end
            end))
            self.maid:give(UIS.InputEnded:Connect(function(i) if C.isPress(i) and dragging then dragging = false if not moved then self:Restore() end end end))
        end

        local floatBtn = new("TextButton", { Parent = gui, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(40, vp.Y * 0.5),
            Size = UDim2.fromOffset(48, 48), BackgroundColor3 = self.Theme.Accent, Text = "", AutoButtonColor = false, Visible = hasTouch, ZIndex = 90 })
        corner(floatBtn, 24) stroke(floatBtn, Color3.new(0, 0, 0), 2, 0.6)
        self:paint(floatBtn, "BackgroundColor3", "Accent")
        Icons.make(floatBtn, o.Logo or "spark", { size = UDim2.fromOffset(24, 24), anchor = Vector2.new(0.5, 0.5), position = UDim2.fromScale(0.5, 0.5), color = Color3.new(1, 1, 1), textSize = 22 })
        do
            local dragging, moved, startP, startCenter
            floatBtn.InputBegan:Connect(function(i) if C.isPress(i) then dragging = true moved = false startP = i.Position
                startCenter = Vector2.new(floatBtn.Position.X.Offset, floatBtn.Position.Y.Offset) end end)
            self.maid:give(UIS.InputChanged:Connect(function(i)
                if dragging and C.isMove(i) then
                    local d = i.Position - startP
                    if d.Magnitude > 6 then moved = true end
                    local vpc = viewport()
                    local cx = math.clamp(startCenter.X + d.X, 28, vpc.X - 28)
                    local cy = math.clamp(startCenter.Y + d.Y, 28 + insetTop(), vpc.Y - 28)
                    floatBtn.Position = UDim2.fromOffset(cx, cy)
                end
            end))
            self.maid:give(UIS.InputEnded:Connect(function(i) if C.isPress(i) and dragging then dragging = false if not moved then self:Toggle() end end end))
        end

        if o.Resizable ~= false and HAS_MOUSE then
            local minSize = o.MinSize or UDim2.fromOffset(360, 280)
            local grip = new("TextButton", { Parent = shell, AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -3, 1, -3),
                Size = UDim2.fromOffset(18, 18), BackgroundTransparency = 1, Text = "◢", Font = Enum.Font.GothamBold, TextSize = 11,
                TextColor3 = self.Theme.Dim, AutoButtonColor = false, ZIndex = 20 })
            self:paint(grip, "TextColor3", "Dim")
            local rz, sp, ss
            grip.InputBegan:Connect(function(i) if C.isPress(i) then rz = true sp = i.Position ss = self._size end end)
            self.maid:give(UIS.InputChanged:Connect(function(i)
                if rz and C.isMove(i) then
                    local d = i.Position - sp
                    local nw, nh = C.safeWindowSize(UDim2.fromOffset(ss.X.Offset + d.X, ss.Y.Offset + d.Y), minSize)
                    self._size = UDim2.fromOffset(nw, nh)
                    self.holder.Size = self._size
                end
            end))
            self.maid:give(UIS.InputEnded:Connect(function(i) if C.isPress(i) and rz then rz = false self:save() end end))
        end

        self.maid:give(UIS.InputBegan:Connect(function(i, gpe)
            if gpe then return end
            if i.KeyCode == toggleKey then self:Toggle()
            elseif i.KeyCode == Enum.KeyCode.K and (UIS:IsKeyDown(Enum.KeyCode.LeftControl) or UIS:IsKeyDown(Enum.KeyCode.RightControl)) then self:Palette() end
        end))

        self._visible = true
        self.root.GroupTransparency = 1
        self.root.Position = UDim2.fromOffset(0, 10)
        task.defer(function()
            tw(self.root, 0.22, { GroupTransparency = 0 })
            tw(self.root, 0.3, { Position = UDim2.fromOffset(0, 0) })
            if self.blur then tw(self.blur, 0.3, { Size = self._blurSize }) end
        end)

        BPUI._windows[#BPUI._windows + 1] = self

        if o.Key and o.Key.Enabled then
            self.holder.Visible = false floatBtn.Visible = false
            buildKeyGate({ Title = o.Title, Note = o.Key.Note, Keys = o.Key.Keys, Validate = o.Key.Validate, GetKeyLink = o.Key.GetKeyLink,
                Accent = self.Theme.Accent, Palette = self.Theme }, function() self.holder.Visible = true floatBtn.Visible = hasTouch self:SetVisible(true) end)
        end
        return self
    end

    return Window
end
M["init"] = function(use, BPUI)
    BPUI.Version = "1.1"
    BPUI._windows = BPUI._windows or {}
    use("theme")
    use("icons")
    use("window")
    function BPUI:Destroy()
        for i = #self._windows, 1, -1 do
            local w = self._windows[i]
            pcall(function() w:Destroy() end)
        end
        self._windows = {}
    end
    return BPUI
end
return use("init")
end)()
