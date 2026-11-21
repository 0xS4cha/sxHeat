SX.Police = {}
SX.Modules:Register('Police', 30)

local active = false
local matchCache = {}

function SX.Police:IsActive()
    return active
end

function SX.Police:SetActive(value)
    if active == value then return end
    active = value
    if not active then SearchMap.Clear() end
end

local function showReport(case, isNew)
    local rows = DescriptionText.Rows(case.description)
    table.insert(rows, 1, {
        type = 'text',
        label = GetPhrase('report_place'),
        value = case.street or GetPhrase('desc_unknown'),
        icon = 'map-pin',
        scramble = false,
    })

    local shown = HelpUI.Show('report', 'report_' .. case.id, {
        header = {
            subtitle = GetPhrase(isNew and 'report_new' or 'report_update', case.id),
            title = GetPhrase('crime_' .. tostring(case.lastCrime)),
            watermark = GetPhrase('report_watermark'),
        },
        rows = rows,
        footer = { label = GetPhrase('report_heat'), items = { { value = tostring(case.heat), icon = 'flame', tone = 'danger' } } },
        duration = Config.HelpMenu.reportDuration,
        position = 'top-right',
    })

    if isNew then
        PlaySoundFrontend(-1, 'Event_Message_Purple', 'GTAO_FM_Events_Soundset', true)
    end
    if not shown then
        Bridge.Notify(GetPhrase('notify_report', GetPhrase('crime_' .. tostring(case.lastCrime)), case.street or ''), 'info')
    end
end

local function aimedPlayer()
    local aiming, target = GetEntityPlayerIsFreeAimingAt(PlayerId())
    if not aiming or not target or not IsEntityAPed(target) or not IsPedAPlayer(target) then return nil end
    local player = NetworkGetPlayerIndexFromPed(target)
    return player ~= -1 and GetPlayerServerId(player) or nil
end

local function checkMatch(serverId)
    local cached = matchCache[serverId]
    if cached and cached.time > GetGameTimer() then return cached.result end
    matchCache[serverId] = { time = GetGameTimer() + 1500, result = cached and cached.result or nil }
    CreateThread(function()
        matchCache[serverId].result = TriggerServerCallback('sxHeat:checkMatch', serverId)
    end)
    return matchCache[serverId].result
end

function SX.Police:Initialize()
    RegisterNetEvent('sxHeat:zones', function(list)
        if active then SearchMap.Sync(list) end
    end)

    RegisterNetEvent('sxHeat:report', function(case, isNew)
        if not active or type(case) ~= 'table' then return end
        showReport(case, isNew)
        SearchMap.Set({ id = case.id, x = case.x, y = case.y, radius = case.radius, stale = case.stale })
    end)

    RegisterNetEvent('sxHeat:caseClosed', function(id)
        SearchMap.Remove(id)
        HelpUI.Hide('report_' .. id)
    end)

    RegisterCommand(Config.Police.command, function()
        if active then SX.UI:Open() end
    end, false)
    if Config.Police.key and Config.Police.key ~= '' then
        RegisterKeyMapping(Config.Police.command, GetPhrase('keymap_reports'), 'keyboard', Config.Police.key)
    end

    CreateThread(function()
        while true do
            local wait = 500
            if active and IsPlayerFreeAiming(PlayerId()) then
                wait = 0
                local serverId = aimedPlayer()
                local match = serverId and checkMatch(serverId)
                if match then
                    HelpUI.ShowThisFrame('match', 'match', {
                        header = { subtitle = GetPhrase('match_subtitle', match.id), title = GetPhrase('match_title'), watermark = GetPhrase('match_watermark') },
                        rows = {
                            { type = 'text', label = GetPhrase('match_crime'), value = GetPhrase('crime_' .. tostring(match.crime)), tone = 'danger', icon = 'siren' },
                            { type = 'bar', label = GetPhrase('report_heat'), value = match.heat, max = Config.Heat.max, tone = 'danger' },
                        },
                        position = 'top',
                    }, match.id .. ':' .. match.heat)
                end
            end
            Wait(wait)
        end
    end)
end
