return function(use, BPUI)
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
