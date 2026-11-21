HelpUI = {}

local Settings = Config.HelpMenu or {}
local PREFIX = 'sxheat_'

function HelpUI.IsEnabled(feature)
    if Settings.enabled == false then return false end
    if feature and Settings.features and Settings.features[feature] == false then return false end
    return GetResourceState('sxHelpMenu') == 'started'
end

local function call(name, ...)
    local args = table.pack(...)
    local ok, result = pcall(function()
        return exports.sxHelpMenu[name](exports.sxHelpMenu, table.unpack(args, 1, args.n))
    end)
    if not ok then
        Logger:error('HELPMENU', ('%s failed: %s'):format(name, tostring(result)))
        return nil
    end
    return result
end

function HelpUI.Id(name)
    return PREFIX .. name
end

function HelpUI.Show(feature, name, menu)
    if not HelpUI.IsEnabled(feature) then return nil end
    menu.id = HelpUI.Id(name)
    menu.position = menu.position or Settings.position
    menu.offset = menu.offset or Settings.offset
    if menu.key == nil then menu.key = false end
    return call('Show', menu)
end

local frameKeys = {}

function HelpUI.ShowThisFrame(feature, name, menu, key)
    if not HelpUI.IsEnabled(feature) then return false end
    local id = HelpUI.Id(name)
    if frameKeys[id] == key and call('ShowThisFrame', id) then return true end

    frameKeys[id] = key
    menu.id = id
    menu.position = menu.position or Settings.position
    menu.offset = menu.offset or Settings.offset
    if menu.key == nil then menu.key = false end
    if call('IsVisible', id) then
        call('Update', id, menu)
        return call('ShowThisFrame', id) ~= nil
    end
    return call('ShowThisFrame', menu) ~= nil
end

function HelpUI.UpdateRow(name, rowId, patch)
    if not HelpUI.IsEnabled() then return end
    call('UpdateRow', HelpUI.Id(name), rowId, patch)
end

function HelpUI.Hide(name)
    if GetResourceState('sxHelpMenu') ~= 'started' then return end
    call('Hide', HelpUI.Id(name))
end

function HelpUI.KeyLabel(control, fallback)
    local button = GetControlInstructionalButton(0, control, true)
    if type(button) == 'string' and button:sub(1, 2) == 't_' then
        return button:sub(3)
    end
    return fallback
end

function HelpUI.Color(rgb)
    if type(rgb) ~= 'table' then return nil end
    return ('#%02x%02x%02x'):format(rgb.r or 255, rgb.g or 255, rgb.b or 255)
end

function HelpUI.Duration(seconds)
    seconds = math.max(0, math.floor(seconds or 0))
    return ('%02d:%02d'):format(seconds // 60, seconds % 60)
end

local function ParseVersion(version)
    local major, minor, patch = tostring(version or ''):match('^(%d+)%.(%d+)%.?(%d*)')
    if not major then return nil end
    return tonumber(major) * 1000000 + tonumber(minor) * 1000 + (tonumber(patch) or 0)
end

function HelpUI.AtLeast(version)
    local current = ParseVersion(GetResourceMetadata('sxHelpMenu', 'version', 0))
    local wanted = ParseVersion(version)
    return current ~= nil and wanted ~= nil and current >= wanted
end
