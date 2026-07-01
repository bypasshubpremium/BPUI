return function(use, BPUI)
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
