Config = {}

Config.Framework = 'auto'

Config.Police = {
    jobs = { police = 0, sheriff = 0 },
    ace = 'sxheat.police',
    command = 'reports',
    key = 'F10',
}

-- heat: points added to the suspect, audible: radius in meters where the crime is reported even without a witness
Config.Crimes = {
    shooting = { heat = 25, audible = 120.0, cooldown = 20 },
    murder = { heat = 40, cooldown = 10 },
    assault = { heat = 10, cooldown = 15 },
    threat = { heat = 8, cooldown = 30 },
    carjacking = { heat = 20, cooldown = 30 },
    vehicle_theft = { heat = 12, cooldown = 45 },
}

Config.Witness = {
    radius = 45.0,
    maxWitnesses = 3,
    chance = 0.7,
    callDelay = { 8, 16 },
    plateDistance = 18.0,
    intimidation = true,
}

Config.Heat = {
    max = 100,
    decayPerTick = 1.5,
    staleMultiplier = 3.0,
    sightingHeat = 2,
}

Config.Search = {
    tick = 5,
    startRadius = 260.0,
    minRadius = 60.0,
    maxRadius = 600.0,
    growPerTick = 6.0,
    sightDistance = 60.0,
    points = 28,
}

Config.HelpMenu = {
    enabled = true,
    position = 'bottom-right',
    offset = nil,
    features = {
        report = true,
        suspect = true,
        match = true,
    },
    reportDuration = 12000,
}
