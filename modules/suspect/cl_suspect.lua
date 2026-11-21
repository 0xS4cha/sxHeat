SX.Suspect = {}
SX.Modules:Register('Suspect', 30)

local MENU = 'suspect'
local current = nil
local lastAppearance = nil

local function heatTone(heat, max)
    local ratio = heat / max
    if ratio >= 0.66 then return 'danger' end
    if ratio >= 0.33 then return 'warning' end
    return 'accent'
end

function SX.Suspect:SetStatus(status)
    local previous = current
    current = status

    if not status then
        HelpUI.Hide(MENU)
        if previous then Bridge.Notify(GetPhrase('notify_cleared'), 'success') end
        return
    end

    local shown = HelpUI.Show('suspect', MENU, {
        header = { subtitle = GetPhrase('suspect_subtitle'), title = GetPhrase('suspect_title'), watermark = GetPhrase('suspect_watermark') },
        rows = {
            {
                type = 'bar',
                label = GetPhrase('suspect_heat'),
                value = status.heat,
                max = status.max,
                display = ('%d%%'):format(math.floor(status.heat / status.max * 100 + 0.5)),
                tone = heatTone(status.heat, status.max),
            },
            {
                type = 'text',
                label = GetPhrase('suspect_description'),
                value = status.stale and GetPhrase('suspect_stale') or GetPhrase('suspect_matching'),
                tone = status.stale and 'safe' or 'danger',
                icon = status.stale and 'user-check' or 'user-search',
                scramble = false,
            },
            {
                type = 'text',
                label = GetPhrase('suspect_vehicle'),
                value = status.vehicle and GetPhrase('suspect_vehicle_known') or GetPhrase('suspect_vehicle_unknown'),
                tone = status.vehicle and 'warning' or nil,
                icon = 'car-front',
                scramble = false,
            },
        },
        footer = { label = GetPhrase('suspect_hint') },
    })

    if not shown and not previous then
        Bridge.Notify(GetPhrase('notify_reported'), 'error')
    end
end

local function reportAppearance()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    local data = {
        outfit = Description.Outfit(ped),
        plate = vehicle ~= 0 and Description.Plate(vehicle) or nil,
    }
    local key = data.outfit .. '|' .. (data.plate or '')
    if key ~= lastAppearance then
        lastAppearance = key
        TriggerServerEvent('sxHeat:appearance', data)
    end
end

function SX.Suspect:Initialize()
    RegisterNetEvent('sxHeat:status', function(status)
        SX.Suspect:SetStatus(status)
    end)

    CreateThread(function()
        while true do
            reportAppearance()
            Wait(3000)
        end
    end)
end
