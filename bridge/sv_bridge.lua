Bridge = {}
Bridge.Name = 'standalone'

local ESX = nil

local function detectFramework()
    if Config.Framework == 'standalone' then return 'standalone' end

    if Config.Framework == 'esx' or GetResourceState('es_extended') ~= 'missing' then
        local ok, obj = pcall(function()
            return exports.es_extended:getSharedObject()
        end)
        if ok and obj then
            ESX = obj
            return 'esx'
        end
        Logger:error('BRIDGE', 'es_extended could not be loaded, running standalone')
    end

    return 'standalone'
end

Bridge.Name = detectFramework()
Logger:info('BRIDGE', 'Framework:', Bridge.Name)

local function esxPlayer(source)
    return ESX and ESX.GetPlayerFromId(source) or nil
end

function Bridge.GetIdentifier(source)
    local xPlayer = esxPlayer(source)
    if xPlayer then return xPlayer.getIdentifier() end
    return GetPlayerIdentifierByType(source, 'license')
end

function Bridge.GetName(source)
    local xPlayer = esxPlayer(source)
    if xPlayer and xPlayer.getName then
        local ok, name = pcall(xPlayer.getName)
        if ok and name then return name end
    end
    return GetPlayerName(source) or ('#' .. tostring(source))
end

function Bridge.IsPolice(source)
    if Config.Police.ace and IsPlayerAceAllowed(source, Config.Police.ace) then return true end

    local xPlayer = esxPlayer(source)
    if not xPlayer then return false end
    local job = xPlayer.getJob and xPlayer.getJob() or xPlayer.job
    if not job then return false end
    local minGrade = Config.Police.jobs[job.name]
    return minGrade ~= nil and (tonumber(job.grade) or 0) >= minGrade
end

function Bridge.Notify(source, message, kind)
    TriggerClientEvent('sxHeat:notify', source, message, kind or 'info')
end
