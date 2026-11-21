DescriptionText = {}

function DescriptionText.Rows(description)
    local rows = {}
    description = description or {}

    if description.sex and description.sex ~= 'unknown' then
        rows[#rows + 1] = { type = 'text', label = GetPhrase('desc_sex'), value = GetPhrase('sex_' .. description.sex), icon = 'user-round' }
    end

    local accessories = {}
    for _, key in ipairs({ 'mask', 'hat', 'glasses', 'bag' }) do
        if description[key] then accessories[#accessories + 1] = GetPhrase('acc_' .. key) end
    end
    rows[#rows + 1] = {
        type = 'text',
        label = GetPhrase('desc_outfit'),
        value = (#accessories > 0 and (table.concat(accessories, ', ') .. ' · ') or '') .. (description.outfit or '?'),
        icon = 'shirt',
    }

    if description.vehicle then
        local vehicle = description.vehicle
        rows[#rows + 1] = {
            type = 'text',
            label = GetPhrase('desc_vehicle'),
            value = ('%s %s'):format(vehicle.label or '?', vehicle.color and GetPhrase('color_' .. vehicle.color) or ''),
            icon = 'car-front',
        }
        rows[#rows + 1] = {
            type = 'text',
            label = GetPhrase('desc_plate'),
            value = vehicle.plate or GetPhrase('desc_unknown'),
            icon = 'rectangle-horizontal',
            tone = vehicle.plate and 'accent' or nil,
            scramble = false,
        }
    end

    if description.weapon then
        rows[#rows + 1] = { type = 'text', label = GetPhrase('desc_weapon'), value = GetPhrase('weapon_' .. description.weapon), icon = 'crosshair', tone = 'danger' }
    end

    return rows
end
