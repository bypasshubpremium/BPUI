return function(use, BPUI)
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
