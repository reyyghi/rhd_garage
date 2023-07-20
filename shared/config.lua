lib.locale()

Config = {}

Config.RadialMenu = 'qb-radialmenu' --- ox_lib / qb-radialmenu

Config.FuelScript = 'rhd_fuel' --- rhd-fuel / ox_fuel / LegacyFuel / ps-fuel / cdn-fuel

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

Config.Garages = {
    ['Alta Garage'] = {
        type = 'car',
        blip = { type = 357, color = 3 },
        location = {
            vec4(-297.7316, -990.2527, 30.8097, 158.2520),
            vec4(-301.2096, -988.8935, 30.8102, 159.5031)
        },
    },
    ['Legion Square'] = {
        type = 'car',
        blip = { type = 357, color = 3 },
        location = {
            vec4(207.1528, -798.5329, 30.7163, 68.9889),
            vec4(208.1968, -795.8964, 30.6939, 68.2650)
        },
    },
    ['LSPD Garage'] = {
        type = 'car',
        job = 'police',
        location = {
            vec4(446.2076, -1025.0396, 28.2305, 182.7990),
            vec4(442.5884, -1025.7180, 28.3066, 182.4678),
            vec4(438.6816, -1025.8633, 28.3757, 181.9156),
            vec4(434.8838, -1026.4578, 28.4578, 182.7940),
        },
    },
    ['Hayes Depot'] = {
        type = 'car',
        blip = { type = 473, color = 60 },
        location = vec4(480.8937, -1317.1934, 28.9323, 295.1895),
        impound = true
    }
}

Config.policeImpound = {
    ['LSPD Impound'] = {
        type = 'car',
        blip = { type = 357, color = 3 },
        location = {
            vec4(827.9538, -1339.1812, 25.8267, 245.6593),
            vec4(827.6714, -1345.0046, 25.8251, 243.7945)
        },
        minGradeAccess = 3
    }
}

Config.HouseGarages = {}
exports('garageList', function ()
    return Config.Garages
end)
