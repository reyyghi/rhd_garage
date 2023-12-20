GarageZone = require "data.garage"
CNV = require "data.customname"

Config = {}

Config.RadialMenu = 'qb' --- ox / qb / rhd
Config.FuelScript = 'LegacyFuel' --- rhd-fuel / ox_fuel / LegacyFuel / ps-fuel / cdn-fuel

Config.changeNamePrice = 15000 --- $

Config.defaultBlip = {
    garage = {
        car = {
            type = 357,
            color = 3
        },
        boat = {
            type = 356,
            color = 3
        },
        helicopter = {
            type = 360,
            color = 3
        },
        planes = {
            type = 359,
            color = 3
        }
    },
    insurance = {
        car = {
            type = 473,
            color = 60
        },
        boat = {
            type = 529,
            color = 60
        },
        helicopter = {
            type = 557,
            color = 60
        },
        planes = {
            type = 557,
            color = 60
        }
    }
}

Config.ImpoundPrice = {
    [0] = 15000, -- Compacts
    [1] = 15000, -- Sedans
    [2] = 15000, -- SUVs
    [3] = 15000, -- Coupes
    [4] = 15000, -- Muscle
    [5] = 15000, -- Sports Classics
    [6] = 15000, -- Sports
    [7] = 15000, -- Super
    [8] = 15000, -- Motorcycles
    [9] = 15000, -- Off-road
    [10] = 15000, -- Industrial
    [11] = 15000, -- Utility
    [12] = 15000, -- Vans
    [13] = 15000, -- Cylces
    [14] = 15000, -- Boats
    [15] = 15000, -- Helicopters
    [16] = 15000, -- Planes
    [17] = 15000, -- Service
    [18] = 0, -- Emergency
    [19] = 15000, -- Military
    [20] = 15000, -- Commercial
    [21] = 0 -- Trains (lol)
}

Config.PoliceImpound = {
    enable = true,
    targetUsed = "qb", -- qb or ox
    location = {
        [1] = {
            label = "Police Impound 1",
            zones = {
                points = {
                    vec3(824.69000244141, -1334.0200195312, 26.0),
                    vec3(831.70001220703, -1337.2700195312, 26.0),
                    vec3(831.73999023438, -1354.0300292969, 26.0),
                    vec3(832.10998535156, -1355.4799804688, 26.0),
                    vec3(824.72998046875, -1352.0400390625, 26.0),
                },
                thickness = 4.0,
            },
            grade = 3
        }
    }
}

Config.HouseGarages = {}
