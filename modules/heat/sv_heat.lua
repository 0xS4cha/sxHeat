SX.Heat = {}
SX.Modules:Register('Heat', 10)

local cases = {}
local bySource = {}
local appearance = {}
local cooldowns = {}
local nextId = 0

local function now()
    return os.time()
end

local function jitter(coords, amount)
    local angle = math.random() * math.pi * 2
    local distance = math.random() * amount
    return vector3(coords.x + math.cos(angle) * distance, coords.y + math.sin(angle) * distance, coords.z)
end

local function mergePlate(known, seen)
    if not seen or seen == '' then return known end
    if not known or #known ~= #seen then return seen end
    local merged = {}
    for i = 1, #seen do
        local a, b = known:sub(i, i), seen:sub(i, i)
        merged[i] = (b ~= '*' and b) or a
    end
    return table.concat(merged)
end

local function mergeDescription(target, seen)
    if type(seen) ~= 'table' then return end
    for _, key in ipairs({ 'sex', 'outfit', 'hat', 'glasses', 'mask', 'bag', 'weapon' }) do
        if seen[key] ~= nil then target[key] = seen[key] end
    end
    if type(seen.vehicle) == 'table' then
        local vehicle = target.vehicle or {}
        vehicle.model = seen.vehicle.model or vehicle.model
        vehicle.label = seen.vehicle.label or vehicle.label
        vehicle.color = seen.vehicle.color or vehicle.color
        vehicle.plate = mergePlate(vehicle.plate, seen.vehicle.plate)
        target.vehicle = vehicle
    end
end

local function plateMatches(known, current)
    if not known or not current or #known ~= #current then return false end
    local seen = 0
    for i = 1, #known do
        local a = known:sub(i, i)
        if a ~= '*' then
            if a ~= current:sub(i, i) then return false end
            seen = seen + 1
        end
    end
    return seen >= 4
end

local function isStale(case)
    local current = appearance[case.source]
    if not current then return false end
    if case.description.outfit and current.outfit == case.description.outfit then return false end
    local vehicle = case.description.vehicle
    if vehicle and current.plate and plateMatches(vehicle.plate, current.plate) then return false end
    return true
end

local function publicCase(case)
    return {
        id = case.id,
        crimes = case.crimes,
        lastCrime = case.lastCrime,
        heat = math.floor(case.heat + 0.5),
        description = case.description,
        x = case.center.x,
        y = case.center.y,
        radius = case.radius,
        street = case.street,
        createdAt = case.createdAt,
        lastSeen = case.lastSeen,
        stale = case.stale,
    }
end

function SX.Heat:GetPolice()
    local list = {}
    for _, playerId in ipairs(GetPlayers()) do
        local source = tonumber(playerId)
        if Bridge.IsPolice(source) then list[#list + 1] = source end
    end
    return list
end

function SX.Heat:SendStatus(case)
    if not case then return end
    TriggerClientEvent('sxHeat:status', case.source, {
        heat = math.floor(case.heat + 0.5),
        max = Config.Heat.max,
        stale = case.stale,
        vehicle = case.description.vehicle ~= nil,
        crime = case.lastCrime,
    })
end

function SX.Heat:Clear(case, reason)
    if not case then return end
    cases[case.id] = nil
    bySource[case.source] = nil
    TriggerClientEvent('sxHeat:status', case.source, nil)
    for _, police in ipairs(self:GetPolice()) do
        TriggerClientEvent('sxHeat:caseClosed', police, case.id)
    end
    TriggerEvent('sxHeat:cleared', case.id, case.source, reason)
end

function SX.Heat:FollowUp(source, crime, description)
    local case = self:GetCaseBySource(source)
    if not case or case.lastCrime ~= crime or now() - case.lastSeen > 90 then return end
    mergeDescription(case.description, description)
    case.stale = isStale(case)
    local data = publicCase(case)
    for _, police in ipairs(self:GetPolice()) do
        TriggerClientEvent('sxHeat:report', police, data, false)
    end
end

function SX.Heat:Report(source, crime, coords, description, street)
    local settings = Config.Crimes[crime]
    if not settings or Bridge.IsPolice(source) then return nil end

    local key = source .. ':' .. crime
    if cooldowns[key] and cooldowns[key] > GetGameTimer() then return nil end
    cooldowns[key] = GetGameTimer() + settings.cooldown * 1000

    local ped = GetPlayerPed(source)
    local position = GetEntityCoords(ped)
    coords = coords and vector3(coords.x + 0.0, coords.y + 0.0, (coords.z or position.z) + 0.0) or position
    if #(coords - position) > 200.0 then coords = position end

    local case = bySource[source] and cases[bySource[source]]
    local isNew = case == nil
    if isNew then
        nextId = nextId + 1
        case = {
            id = nextId,
            source = source,
            identifier = Bridge.GetIdentifier(source),
            heat = 0,
            crimes = {},
            description = {},
            radius = Config.Search.startRadius,
            createdAt = now(),
        }
        cases[case.id] = case
        bySource[source] = case.id
    end

    case.heat = math.min(Config.Heat.max, case.heat + settings.heat)
    case.crimes[crime] = (case.crimes[crime] or 0) + 1
    case.lastCrime = crime
    mergeDescription(case.description, description)
    case.center = jitter(coords, Config.Search.startRadius * 0.35)
    case.radius = Config.Search.startRadius
    case.lastSeen = now()
    case.street = type(street) == 'string' and street:sub(1, 80) or case.street
    case.stale = isStale(case)

    local data = publicCase(case)
    for _, police in ipairs(self:GetPolice()) do
        TriggerClientEvent('sxHeat:report', police, data, isNew)
    end
    self:SendStatus(case)
    TriggerEvent('sxHeat:reported', case.id, source, crime)
    Logger:info('HEAT', ('Case #%d, %s reported for %s (heat %d)'):format(case.id, GetPlayerName(source) or source, crime, case.heat))
    return case.id
end

function SX.Heat:Tick()
    local police = self:GetPolice()
    local zones = {}

    for _, case in pairs(cases) do
        if not GetPlayerName(case.source) then
            self:Clear(case, 'dropped')
        else
            case.stale = isStale(case)
            local suspectCoords = GetEntityCoords(GetPlayerPed(case.source))
            local spotted = false

            if not case.stale then
                for _, officer in ipairs(police) do
                    if #(GetEntityCoords(GetPlayerPed(officer)) - suspectCoords) <= Config.Search.sightDistance then
                        spotted = true
                        break
                    end
                end
            end

            if spotted then
                case.center = jitter(suspectCoords, 15.0)
                case.radius = Config.Search.minRadius
                case.lastSeen = now()
                case.heat = math.min(Config.Heat.max, case.heat + Config.Heat.sightingHeat)
            else
                case.radius = math.min(Config.Search.maxRadius, case.radius + Config.Search.growPerTick)
                local decay = Config.Heat.decayPerTick * (case.stale and Config.Heat.staleMultiplier or 1.0)
                case.heat = case.heat - decay
            end

            if case.heat <= 0 then
                self:Clear(case, 'cooled')
            else
                zones[#zones + 1] = { id = case.id, x = case.center.x, y = case.center.y, radius = case.radius, heat = math.floor(case.heat + 0.5), stale = case.stale, spotted = spotted }
                self:SendStatus(case)
            end
        end
    end

    for _, officer in ipairs(police) do
        TriggerClientEvent('sxHeat:zones', officer, zones)
    end
end

function SX.Heat:GetCases()
    local list = {}
    for _, case in pairs(cases) do list[#list + 1] = publicCase(case) end
    table.sort(list, function(a, b) return a.lastSeen > b.lastSeen end)
    return list
end

function SX.Heat:GetCaseBySource(source)
    return bySource[source] and cases[bySource[source]] or nil
end

function SX.Heat:CloseCase(source, id)
    if not Bridge.IsPolice(source) then return { ok = false, error = 'not_police' } end
    local case = cases[tonumber(id)]
    if not case then return { ok = false, error = 'not_found' } end
    self:Clear(case, 'closed')
    return { ok = true }
end

function SX.Heat:Initialize()
    RegisterNetEvent('sxHeat:crime', function(crime, coords, description, street, followUp)
        if followUp then
            SX.Heat:FollowUp(source, crime, description)
        else
            SX.Heat:Report(source, crime, coords, description, street)
        end
    end)

    RegisterNetEvent('sxHeat:appearance', function(data)
        if type(data) ~= 'table' then return end
        appearance[source] = { outfit = tostring(data.outfit or ''), plate = data.plate and tostring(data.plate) or nil }
    end)

    RegisterServerCallback('sxHeat:isPolice', function(source)
        return Bridge.IsPolice(source)
    end)

    RegisterServerCallback('sxHeat:getCases', function(source)
        if not Bridge.IsPolice(source) then return { ok = false, error = 'not_police' } end
        return { ok = true, data = SX.Heat:GetCases() }
    end)

    RegisterServerCallback('sxHeat:closeCase', function(source, id)
        return SX.Heat:CloseCase(source, id)
    end)

    RegisterServerCallback('sxHeat:checkMatch', function(source, target)
        if not Bridge.IsPolice(source) then return nil end
        local case = SX.Heat:GetCaseBySource(tonumber(target))
        if not case or case.stale then return nil end
        local distance = #(GetEntityCoords(GetPlayerPed(source)) - GetEntityCoords(GetPlayerPed(case.source)))
        if distance > 80.0 then return nil end
        return { id = case.id, crime = case.lastCrime, heat = math.floor(case.heat + 0.5) }
    end)

    AddEventHandler('playerDropped', function()
        local case = SX.Heat:GetCaseBySource(source)
        if case then SX.Heat:Clear(case, 'dropped') end
        appearance[source] = nil
    end)
end

function SX.Heat:InitializeAsync()
    while true do
        Wait(Config.Search.tick * 1000)
        local ok, err = pcall(self.Tick, self)
        if not ok then Logger:error('HEAT', 'Tick failed:', err) end
    end
end
