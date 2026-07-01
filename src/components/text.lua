return function(use, BPUI)
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
