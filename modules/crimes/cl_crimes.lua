SX.Crimes = {}
SX.Modules:Register('Crimes', 20)

local isPolice = false
local lastCrime = {}

local function streetAt(coords)
    local street = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local zone = GetLabelText(GetNameOfZone(coords.x, coords.y, coords.z))
    local name = GetStreetNameFromHashKey(street)
    if zone and zone ~= '' and zone ~= 'NULL' then
        return name ~= '' and (name .. ', ' .. zone) or zone
    end
    return name
end

local function findWitnesses(origin, myPed, myVehicle)
    local witnesses = {}
    for _, ped in ipairs(GetGamePool('CPed')) do
        if ped ~= myPed and not IsPedAPlayer(ped) and not IsEntityDead(ped) and IsPedHuman(ped)
            and GetVehiclePedIsIn(ped, false) ~= myVehicle then
            local distance = #(GetEntityCoords(ped) - origin)
            if distance <= Config.Witness.radius and HasEntityClearLosToEntity(ped, myPed, 17) then
                witnesses[#witnesses + 1] = { ped = ped, distance = distance }
            end
        end
    end
    table.sort(witnesses, function(a, b) return a.distance < b.distance end)
    return witnesses
end

local function phoneCall(ped, duration)
    if not NetworkHasControlOfEntity(ped) then
        NetworkRequestControlOfEntity(ped)
        local timeout = GetGameTimer() + 500
        while not NetworkHasControlOfEntity(ped) and GetGameTimer() < timeout do Wait(0) end
    end
    if NetworkHasControlOfEntity(ped) then
        ClearPedTasks(ped)
        TaskUseMobilePhoneTimed(ped, duration)
    end
end

local function intimidate(ped)
    if NetworkHasControlOfEntity(ped) then
        ClearPedTasks(ped)
        TaskHandsUp(ped, 6000, PlayerPedId(), -1, false)
    end
end

local function runWitness(witness, crime, coords, snapshot, street, state)
    local ped = witness.ped
    local duration = math.random(Config.Witness.callDelay[1], Config.Witness.callDelay[2]) * 1000
    phoneCall(ped, duration)

    local finish = GetGameTimer() + duration
    while GetGameTimer() < finish do
        if not DoesEntityExist(ped) or IsEntityDead(ped) then return false end
        if Config.Witness.intimidation and IsPlayerFreeAimingAtEntity(PlayerId(), ped) then
            intimidate(ped)
            return false
        end
        Wait(200)
    end

    local followUp = state.reported
    state.reported = true
    TriggerServerEvent('sxHeat:crime', crime, coords, Description.SeenBy(snapshot, witness.distance), street, followUp)
    return true
end

function SX.Crimes:Commit(crime)
    local settings = Config.Crimes[crime]
    if isPolice or not settings then return end
    if lastCrime[crime] and lastCrime[crime] > GetGameTimer() then return end
    lastCrime[crime] = GetGameTimer() + settings.cooldown * 1000

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local snapshot = Description.Snapshot(ped)
    local street = streetAt(coords)
    local witnesses = findWitnesses(coords, ped, snapshot.vehicleEntity or 0)
    snapshot.vehicleEntity = nil
    local position = { x = coords.x, y = coords.y, z = coords.z }

    CreateThread(function()
        local state = { reported = false }
        local callers = {}
        for _, witness in ipairs(witnesses) do
            if #callers >= Config.Witness.maxWitnesses then break end
            if math.random() <= Config.Witness.chance then callers[#callers + 1] = witness end
        end

        for index, witness in ipairs(callers) do
            CreateThread(function()
                Wait((index - 1) * 1500)
                runWitness(witness, crime, position, snapshot, street, state)
            end)
        end

        local audible = settings.audible
        if audible and crime == 'shooting' and IsPedCurrentWeaponSilenced(ped) then audible = audible / 3 end
        if #callers == 0 and audible then
            Wait(math.random(4, 9) * 1000)
            TriggerServerEvent('sxHeat:crime', crime, position, nil, street, false)
        end
    end)
end

local function refreshPolice()
    isPolice = TriggerServerCallback('sxHeat:isPolice') == true
    SX.Police:SetActive(isPolice)
end

function SX.Crimes:Initialize()
    AddEventHandler('gameEventTriggered', function(name, args)
        if name ~= 'CEventNetworkEntityDamage' then return end
        local victim, attacker = args[1], args[2]
        local ped = PlayerPedId()
        if attacker ~= ped or victim == ped or not DoesEntityExist(victim) or not IsEntityAPed(victim) then return end
        SX.Crimes:Commit(IsEntityDead(victim) and 'murder' or 'assault')
    end)

    RegisterNetEvent('esx:setJob', function()
        CreateThread(refreshPolice)
    end)

    CreateThread(function()
        Wait(2000)
        while true do
            refreshPolice()
            Wait(60000)
        end
    end)

    CreateThread(function()
        while true do
            local wait = 250
            local ped = PlayerPedId()

            if not isPolice then
                if IsPedArmed(ped, 4 | 2) then
                    wait = 0
                    if IsPedShooting(ped) then
                        SX.Crimes:Commit('shooting')
                    end

                    local aiming, target = GetEntityPlayerIsFreeAimingAt(PlayerId())
                    if aiming and target and IsEntityAPed(target) and not IsPedAPlayer(target) and not IsEntityDead(target) then
                        SX.Crimes:Commit('threat')
                    end
                end

                if IsPedJacking(ped) then
                    SX.Crimes:Commit('carjacking')
                elseif IsPedTryingToEnterALockedVehicle(ped) then
                    SX.Crimes:Commit('vehicle_theft')
                end
            end

            Wait(wait)
        end
    end)
end
