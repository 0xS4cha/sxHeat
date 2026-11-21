SX.UI = {}
SX.Modules:Register('UI', 5)

local isOpen = false

function SX.UI:Send(action, data)
    SendNUIMessage({ action = action, data = data or {} })
end

function SX.UI:Open()
    if isOpen then return end
    local locale = GetPreferredLanguageId()
    isOpen = true
    SetNuiFocus(true, true)
    self:Send('setTranslations', { locale = locale, translations = GetLanguageTable(locale) })
    self:Send('setLocale', { locale = locale })
    self:Send('setVisible', { visible = true })
end

function SX.UI:Close()
    if not isOpen then return end
    isOpen = false
    SetNuiFocus(false, false)
    self:Send('setVisible', { visible = false })
end

function SX.UI:IsOpen()
    return isOpen
end

function SX.UI:Initialize()
    RegisterNUICallback('nuiReady', function(_, cb) cb({ ok = true }) end)
    RegisterNUICallback('close', function(_, cb)
        SX.UI:Close()
        cb({ ok = true })
    end)

    RegisterNUICallback('getCases', function(_, cb)
        cb(TriggerServerCallback('sxHeat:getCases') or { ok = false, error = 'timeout' })
    end)

    RegisterNUICallback('closeCase', function(data, cb)
        cb(TriggerServerCallback('sxHeat:closeCase', data and data.id) or { ok = false, error = 'timeout' })
    end)

    RegisterNUICallback('setWaypoint', function(data, cb)
        if data and tonumber(data.x) and tonumber(data.y) then
            SetNewWaypoint(tonumber(data.x) + 0.0, tonumber(data.y) + 0.0)
        end
        cb({ ok = true })
    end)

    CreateThread(function()
        while true do
            if isOpen then
                DisableControlAction(0, 1, true)
                DisableControlAction(0, 2, true)
                DisableControlAction(0, 142, true)
                DisableControlAction(0, 24, true)
                DisableControlAction(0, 25, true)
                Wait(0)
            else
                Wait(500)
            end
        end
    end)
end
