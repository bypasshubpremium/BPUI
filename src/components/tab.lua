return function(use, BPUI)
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
