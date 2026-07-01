local BPUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/USER/REPO/main/BPUI/dist/BPUI.lua"))()

BPUI:AddTheme("Carbon", {
    Bg = Color3.fromRGB(18, 18, 20), Bg2 = Color3.fromRGB(13, 13, 15),
    Panel = Color3.fromRGB(26, 26, 30), Panel2 = Color3.fromRGB(34, 34, 40),
    Stroke = Color3.fromRGB(52, 52, 60), Text = Color3.fromRGB(240, 240, 244),
    Sub = Color3.fromRGB(150, 150, 160), Accent = Color3.fromRGB(0, 200, 160),
})

local Window = BPUI:Window({
    Name = "BPUI_Showcase",
    Title = "BPUI",
    Subtitle = "Component Showcase",
    Logo = "spark",
    Theme = "Blue",
    Size = UDim2.fromOffset(780, 510),
    MinSize = UDim2.fromOffset(460, 320),
    Acrylic = false,
    Resizable = true,
    ToggleKey = Enum.KeyCode.RightShift,
    ConfigSave = { Enabled = true, Folder = "Showcase", File = "demo" },
})

local filterDrawer = Window:Flyout({ Title = "Filters", Icon = "filter", Side = "right", Width = 300 })
filterDrawer:Section({ Title = "Refine", Desc = "Slides in over the content" })
filterDrawer:Toggle({ Title = "In Stock Only", Default = true, Flag = "fd1" })
filterDrawer:Slider({ Title = "Max Price", Min = 0, Max = 1000, Default = 500, Step = 10, Suffix = "$", Flag = "fd2" })
filterDrawer:Dropdown({ Title = "Category", Items = { "All", "Weapons", "Armor", "Potions" }, Default = "All", Flag = "fd3" })
filterDrawer:Buttons({ Items = {
    { Title = "Apply", Variant = "primary", Callback = function() filterDrawer:Close() Window:Notify({ Title = "Filters applied", Type = "success" }) end },
    { Title = "Reset", Variant = "default" },
} })

local Home = Window:Tab({ Title = "Home", Icon = "home", Group = "General" })
Home:Paragraph({ Title = "Welcome", Body = "BPUI is a generic, fully customizable UI toolkit for mobile and PC. Hover the left rail to expand it, drag the title bar, drag the bottom-right corner to resize, press Right Shift to toggle, press Ctrl+K (or the magnifier) to open the command palette, and the dash button to minimize to a floating pill." })
Home:Section({ Title = "Metrics", Desc = "Live counters and quick actions" })
local stat = Home:Stat({ Title = "Active Players", Value = "0", Icon = "users" })
Home:Buttons({ Items = {
    { Title = "Refresh", Icon = "refresh", Variant = "primary", Callback = function() stat:SetValue(math.random(1, 99)) end },
    { Title = "Reset", Variant = "default", Callback = function() stat:SetValue(0) end },
    { Title = "Clear", Variant = "default", Callback = function() stat:SetValue("--") end },
} })
Home:Section("Progress")
local prog = Home:Progress({ Title = "Loading", Default = 0.25, Tooltip = "Driven by the button below" })
Home:Button({ Title = "Advance Progress", Callback = function() prog:Set((prog:Get() + 0.2) % 1.01) end })

local Controls = Window:Tab({ Title = "Controls", Icon = "settings", Group = "General" })
Controls:Section("Switches")
Controls:Toggle({ Title = "Basic Toggle", Desc = "On / off switch", Default = false, Flag = "t1", Tooltip = "A simple boolean", Callback = function(v) print("t1", v) end })
Controls:Toggle({ Title = "Toggle With Keybind", Default = false, Keybind = "F", Flag = "t2", Callback = function(v) print("t2", v) end })
Controls:Section("Choice")
Controls:Segmented({ Title = "Quality", Desc = "Pick one", Options = { "Low", "Medium", "High" }, Default = "Medium", Flag = "seg1", Callback = function(v) print("quality", v) end })
Controls:Radio({ Title = "Mode", Options = { "Safe", { Title = "Balanced", Desc = "recommended" }, "Aggressive" }, Default = "Balanced", Flag = "r1", Callback = function(v) print("mode", v) end })
Controls:Section("Numbers")
Controls:Slider({ Title = "Volume", Min = 0, Max = 100, Default = 60, Step = 1, Suffix = "%", Flag = "s1", Callback = function(v) print("vol", v) end })
Controls:Stepper({ Title = "Retry Count", Min = 1, Max = 10, Step = 1, Default = 3, Suffix = "x", Flag = "st1", Callback = function(v) print("retries", v) end })
Controls:RangeSlider({ Title = "Price Range", Desc = "Drag either handle", Min = 0, Max = 1000, Step = 10, DefaultMin = 200, DefaultMax = 800, Suffix = "$", Flag = "rng1", Callback = function(lo, hi) print("range", lo, hi) end })
Controls:Section({ Title = "Dependencies", Desc = "Disabled children follow their master" })
Controls:Toggle({ Title = "Enable Module", Default = true, Flag = "master", Callback = function(v) print("master", v) end })
Controls:Slider({ Title = "Module Power", Min = 0, Max = 100, Default = 50, Suffix = "%", Flag = "depPow", Depends = "master" })
Controls:Dropdown({ Title = "Module Target", Items = { "A", "B", "C" }, Default = "A", Flag = "depTgt", Depends = "master" })
Controls:Toggle({ Title = "Only When Aggressive", Desc = "Depends on the Mode radio above", Default = false, Flag = "depAggro", Depends = "r1", DependsValue = "Aggressive" })
Controls:Section("Text & Keys")
Controls:Input({ Title = "Name", Placeholder = "Type here...", Flag = "in1", Callback = function(s) print("name", s) end })
Controls:Keybind({ Title = "Action Key", Default = "E", Flag = "kb1", Callback = function() print("action") end, ChangedCallback = function(k) print("key=", k) end })

local Lists = Window:Tab({ Title = "Lists", Icon = "box", Group = "Data" })
Lists:Section("Dropdowns")
Lists:Dropdown({ Title = "Single Select", Items = { "Option A", "Option B", "Option C", "Option D" }, Default = "Option A", Flag = "d1", Callback = function(v) print("single", v) end })
Lists:Dropdown({ Title = "Multi Select", Items = { "Red", "Green", "Blue", "Yellow", "Purple" }, Multi = true, Default = { "Red", "Blue" }, Flag = "d2", Callback = function(t) print("multi", #t) end })
Lists:Dropdown({ Title = "Searchable (auto >8)", Items = { "Apple", "Banana", "Cherry", "Date", "Fig", "Grape", "Kiwi", "Lemon", "Mango", "Orange", "Peach", "Plum" }, Flag = "d3", Callback = function(v) print("fruit", v) end })
Lists:Section("Accordion")
local adv = Lists:Accordion({ Title = "Advanced Options", Desc = "Collapsible — holds any components", Icon = "settings", Open = false })
adv:Toggle({ Title = "Nested Toggle", Desc = "Inside the accordion", Default = true, Flag = "ac1", Callback = function(v) print("nested", v) end })
adv:Slider({ Title = "Nested Slider", Min = 0, Max = 100, Default = 40, Suffix = "%", Flag = "ac2", Callback = function(v) print("nested slider", v) end })
adv:Buttons({ Items = {
    { Title = "Apply", Variant = "primary", Callback = function() Window:Notify({ Title = "Applied", Type = "success" }) end },
    { Title = "Reset", Variant = "default", Callback = function() end },
} })
local faq = Lists:Accordion({ Title = "What is BPUI?", Icon = "info", Open = false })
faq:Paragraph({ Body = "BPUI is a generic Roblox UI toolkit. Accordions let you tuck advanced settings or FAQ entries away until needed." })
Lists:Section("Table")
local lb = Lists:Table({
    Title = "Leaderboard",
    Columns = { { Title = "Player", Weight = 2 }, { Title = "Score", Align = "right" }, { Title = "Status", Align = "right" } },
    Rows = {
        { "Alice", "12,480", "Online" },
        { "Bob", "9,210", "Idle" },
        { Cells = { "Carol", "7,005", "Offline" }, Color = Color3.fromRGB(150, 150, 160) },
    },
    OnRow = function(row, i) Window:Notify({ Title = "Row " .. i, Content = tostring(row[1] or (row.Cells and row.Cells[1])), Type = "info" }) end,
})
Lists:Button({ Title = "Add Random Row", Callback = function()
    lb:AddRow({ "Player" .. math.random(1, 99), tostring(math.random(1000, 9999)), "Online" })
end })
Lists:Section("Flyout / Drawer")
Lists:Button({ Title = "Open Filters Drawer", Desc = "Side panel that holds any components", Icon = "filter", Callback = function() filterDrawer:Open() end })

local Media = Window:Tab({ Title = "Media", Icon = "image", Group = "Data" })
Media:Section("Pickers")
Media:Colorpicker({ Title = "Highlight Color", Default = Color3.fromRGB(255, 120, 80), Flag = "c1", Callback = function(c) print("color", c) end })
Media:Colorpicker({ Title = "Live Accent", Default = Color3.fromRGB(120, 160, 255), Flag = "c2", Callback = function(c) Window:SetTheme(c) end })
Media:Section("Image")
Media:Image({ Title = "Your Avatar", Avatar = (game.Players.LocalPlayer and game.Players.LocalPlayer.UserId) or 1, Height = 100 })
Media:Section("Icon Gallery")
Media:IconGallery({ Title = "Built-in Icons", Height = 220, OnSelect = function(name)
    Window:Notify({ Title = "Icon: " .. name, Content = "Name copied to clipboard.", Type = "success", Icon = name })
end })

local Theming = Window:Tab({ Title = "Theming", Icon = "palette", Group = "Appearance" })
Theming:Section("Accent")
Theming:Dropdown({ Title = "Accent", Items = { "Blue", "Teal", "Green", "Purple", "Magenta", "Orange", "Amber", "Red", "Pink", "Slate" }, Default = "Blue",
    Callback = function(v) Window:SetTheme(v) end })
Theming:Section("Theme")
Theming:Segmented({ Title = "Base", Options = { "Dark", "Light", "Oled" }, Default = "Dark", Callback = function(v)
    if v == "Light" then Window:SetTheme("Light") elseif v == "Oled" then Window:SetTheme("Oled") else Window:SetTheme(BPUI.Palette) end
end })
Theming:Button({ Title = "Apply Carbon Theme", Desc = "Registered via BPUI:AddTheme", Callback = function() Window:SetTheme("Carbon") end })
Theming:Button({ Title = "Apply Inline Palette", Desc = "Pass a palette table to SetTheme", Callback = function()
    Window:SetTheme({ Accent = Color3.fromRGB(255, 80, 160), Panel = Color3.fromRGB(30, 22, 30), Bg = Color3.fromRGB(20, 14, 22) })
end })

local Feedback = Window:Tab({ Title = "Feedback", Icon = "bell", Group = "Appearance" })
Feedback:Section("Notifications")
Feedback:Buttons({ Items = {
    { Title = "Info", Variant = "default", Callback = function() Window:Notify({ Title = "Info", Content = "Just so you know.", Type = "info" }) end },
    { Title = "Success", Variant = "primary", Callback = function() Window:Notify({ Title = "Success", Content = "Saved successfully.", Type = "success" }) end },
    { Title = "Error", Variant = "danger", Callback = function() Window:Notify({ Title = "Error", Content = "Something went wrong.", Type = "error" }) end },
} })
Feedback:Button({ Title = "Action Notification", Desc = "Notification with buttons", Callback = function()
    Window:Notify({ Title = "Update Available", Content = "A new build is ready.", Type = "info", Buttons = {
        { Title = "Install", Variant = "primary", Callback = function() Window:Notify({ Title = "Installing...", Type = "success" }) end },
        { Title = "Later" },
    } })
end })
Feedback:Button({ Title = "Loading Notification", Desc = "Indeterminate then progress", Callback = function()
    local n = Window:Notify({ Title = "Downloading", Content = "Fetching assets...", Type = "loading" })
    task.spawn(function()
        for p = 0, 1, 0.2 do task.wait(0.4) n:SetProgress(p) end
        n:SetContent("Done.") task.wait(0.6) n:Close()
    end)
end })
Feedback:Section("Dialog")
Feedback:Button({ Title = "Confirm Dialog", Callback = function()
    Window:Dialog({
        Title = "Are you sure?",
        Content = "This is a generic modal dialog. Wire each button to your own logic.",
        Buttons = {
            { Title = "Confirm", Variant = "primary", Callback = function() Window:Notify({ Title = "Confirmed", Type = "success" }) end },
            { Title = "Delete", Variant = "danger", Callback = function() Window:Notify({ Title = "Deleted", Type = "error" }) end },
            { Title = "Cancel", Variant = "default" },
        },
    })
end })

local Sys = Window:Tab({ Title = "System", Icon = "power", Group = "Appearance" })
Sys:Section({ Title = "Actions", Desc = "Window controls" })
Sys:Button({ Title = "Open Command Palette", Desc = "Same as Ctrl+K", Icon = "search", Callback = function() Window:Palette() end })
Sys:Button({ Title = "Minimize", Desc = "Collapse to a floating pill", Callback = function() Window:Minimize() end })
Sys:Button({ Title = "Unload UI", Desc = "Tears down the window and all connections", Icon = "trash", Callback = function() Window:Destroy() end })
Sys:Section({ Title = "Config Profiles", Desc = "Save / load / share named configs" })
Sys:ConfigManager({})

Window:Notify({ Title = "BPUI v" .. BPUI.Version, Content = "Showcase loaded. Right Shift toggles, Ctrl+K searches.", Type = "success", Duration = 5 })

Window:loadConfig()
