return function(use, BPUI)
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
