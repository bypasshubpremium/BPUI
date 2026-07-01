return function(use, BPUI)
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
