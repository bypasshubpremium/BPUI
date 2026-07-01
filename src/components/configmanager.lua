return function(use, BPUI)
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
