return function(use, BPUI)
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
