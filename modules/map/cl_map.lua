SearchMap = {}

local overlay = 0
local zones = {}

local function load()
    if overlay ~= 0 then return end
    overlay = AddMinimapOverlay('core/MINIMAP_LOADER.gfx')
    while not HasMinimapOverlayLoaded(overlay) do Wait(0) end
    SetMinimapOverlayDisplay(overlay, 0.0, 0.0, 100.0, 100.0, 100.0)
end

local function method(name, ...)
    load()
    CallMinimapScaleformFunction(overlay, name)
    for _, arg in ipairs({ ... }) do
        if type(arg) == 'string' then
            ScaleformMovieMethodAddParamPlayerNameString(arg)
        elseif type(arg) == 'boolean' then
            ScaleformMovieMethodAddParamBool(arg)
        elseif math.type(arg) == 'integer' then
            ScaleformMovieMethodAddParamInt(arg)
        else
            ScaleformMovieMethodAddParamFloat(arg + 0.0)
        end
    end
    EndScaleformMovieMethod()
end

local function addPoint(name, x, y)
    load()
    CallMinimapScaleformFunction(overlay, 'ADD_POINT_TO_TERRITORY')
    ScaleformMovieMethodAddParamPlayerNameString(name)
    ScaleformMovieMethodAddParamFloat(x + 0.0)
    ScaleformMovieMethodAddParamFloat(-y + 0.0)
    EndScaleformMovieMethod()
end

function SearchMap.Set(zone)
    local name = 'heat_' .. zone.id
    if not zones[zone.id] then
        method('ADD_TERRITORY', name, 100)
    end
    zones[zone.id] = true

    local r, g, b = 255, 90, 79
    if zone.stale then r, g, b = 255, 201, 77 end
    if zone.spotted then r, g, b = 255, 40, 40 end

    method('RESET_TERRITORY_POINTS', name)
    local points = Config.Search.points
    for i = 0, points - 1 do
        local angle = (i / points) * math.pi * 2
        addPoint(name, zone.x + math.cos(angle) * zone.radius, zone.y + math.sin(angle) * zone.radius)
    end
    method('SET_TERRITORY_COLOR', name, r, g, b)
    method('SET_TERRITORY_ALPHA', name, zone.spotted and 90 or 60)
    method('DRAW_TERRITORY', name, 0xffffff, 3)
    method('SET_TERRITORY_VISIBLE', name, true)
end

function SearchMap.Remove(id)
    if not zones[id] then return end
    local name = 'heat_' .. id
    method('RESET_TERRITORY_POINTS', name)
    method('DRAW_TERRITORY', name, 0xffffff, 0)
    method('SET_TERRITORY_VISIBLE', name, false)
    zones[id] = nil
end

function SearchMap.Sync(list)
    local keep = {}
    for _, zone in ipairs(list or {}) do
        keep[zone.id] = true
        SearchMap.Set(zone)
    end
    for id in pairs(zones) do
        if not keep[id] then SearchMap.Remove(id) end
    end
end

function SearchMap.Clear()
    for id in pairs(zones) do SearchMap.Remove(id) end
end
