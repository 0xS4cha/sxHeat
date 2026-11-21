Description = {}

local WEAPON_GROUPS = {
    [joaat('GROUP_PISTOL')] = 'pistol',
    [joaat('GROUP_SMG')] = 'smg',
    [joaat('GROUP_RIFLE')] = 'rifle',
    [joaat('GROUP_MG')] = 'mg',
    [joaat('GROUP_SHOTGUN')] = 'shotgun',
    [joaat('GROUP_SNIPER')] = 'sniper',
    [joaat('GROUP_HEAVY')] = 'heavy',
    [joaat('GROUP_MELEE')] = 'melee',
    [joaat('GROUP_THROWN')] = 'thrown',
}

local function hashString(value)
    local hash = 5381
    for i = 1, #value do
        hash = ((hash * 33) + value:byte(i)) & 0xFFFFFF
    end
    return ('%06X'):format(hash)
end

local function colorName(r, g, b)
    local max, min = math.max(r, g, b), math.min(r, g, b)
    local light = (max + min) / 2 / 255
    local delta = max - min
    if delta < 28 then
        if light < 0.2 then return 'black' end
        if light > 0.8 then return 'white' end
        return 'grey'
    end

    local hue
    if max == r then
        hue = ((g - b) / delta) % 6
    elseif max == g then
        hue = (b - r) / delta + 2
    else
        hue = (r - g) / delta + 4
    end
    hue = hue * 60

    if light < 0.25 and (hue < 45 or hue > 330) then return 'brown' end
    if hue < 15 or hue >= 330 then return 'red' end
    if hue < 40 then return 'orange' end
    if hue < 70 then return 'yellow' end
    if hue < 170 then return 'green' end
    if hue < 260 then return 'blue' end
    return 'purple'
end

function Description.Outfit(ped)
    local parts = {}
    for _, component in ipairs({ 1, 3, 4, 6, 8, 11 }) do
        parts[#parts + 1] = GetPedDrawableVariation(ped, component) .. ':' .. GetPedTextureVariation(ped, component)
    end
    parts[#parts + 1] = 'p' .. GetPedPropIndex(ped, 0)
    return hashString(GetEntityModel(ped) .. '|' .. table.concat(parts, '|'))
end

function Description.Plate(vehicle)
    return (GetVehicleNumberPlateText(vehicle) or ''):upper():gsub('^%s+', ''):gsub('%s+$', '')
end

local function partialPlate(plate, distance)
    local revealed = 0
    if distance <= Config.Witness.plateDistance then
        revealed = #plate - 1
    elseif distance <= Config.Witness.plateDistance * 2 then
        revealed = 3
    end
    if revealed <= 0 then return nil end

    local positions = {}
    for i = 1, #plate do
        if plate:sub(i, i) ~= ' ' then positions[#positions + 1] = i end
    end
    local shown = {}
    for _ = 1, math.min(revealed, #positions) do
        local index = table.remove(positions, math.random(#positions))
        shown[index] = true
    end

    local out = {}
    for i = 1, #plate do
        local char = plate:sub(i, i)
        out[i] = (char == ' ' or shown[i]) and char or '*'
    end
    return table.concat(out)
end

function Description.Snapshot(ped)
    local model = GetEntityModel(ped)
    local data = {
        sex = model == joaat('mp_f_freemode_01') and 'female' or model == joaat('mp_m_freemode_01') and 'male' or 'unknown',
        outfit = Description.Outfit(ped),
        hat = GetPedPropIndex(ped, 0) ~= -1,
        glasses = GetPedPropIndex(ped, 1) ~= -1,
        mask = GetPedDrawableVariation(ped, 1) > 0,
        bag = GetPedDrawableVariation(ped, 5) > 0,
    }

    local _, weapon = GetCurrentPedWeapon(ped, true)
    if weapon and weapon ~= joaat("WEAPON_UNARMED") then
        data.weapon = WEAPON_GROUPS[GetWeapontypeGroup(weapon)] or 'other'
    end

    local vehicle = GetVehiclePedIsIn(ped, false)
    if vehicle ~= 0 then
        local vehicleModel = GetEntityModel(vehicle)
        local r, g, b = GetVehicleColor(vehicle)
        data.vehicleEntity = vehicle
        data.vehicle = {
            model = vehicleModel,
            label = GetLabelText(GetDisplayNameFromVehicleModel(vehicleModel)),
            color = colorName(r, g, b),
            plate = Description.Plate(vehicle),
        }
    end

    return data
end

function Description.SeenBy(snapshot, distance)
    local seen = {}
    for key, value in pairs(snapshot) do
        if key ~= 'vehicle' and key ~= 'vehicleEntity' then seen[key] = value end
    end

    if snapshot.vehicle then
        seen.vehicle = {
            model = snapshot.vehicle.model,
            label = snapshot.vehicle.label,
            color = snapshot.vehicle.color,
            plate = partialPlate(snapshot.vehicle.plate, distance),
        }
        seen.mask = nil
        seen.bag = nil
    end

    if distance > Config.Witness.radius * 0.6 then
        seen.glasses = nil
        seen.bag = nil
    end

    return seen
end
