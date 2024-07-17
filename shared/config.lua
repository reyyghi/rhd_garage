Config = {}

GarageZone = lib.loadJson('data.garages') ---@type table<string, GarageData>
CNV = lib.loadJson('data.vehiclesname') ---@type table<string, CustomName>

Config.Target = 'ox' -- ox / qb
Config.RadialMenu = 'rhd' --- ox / qb / rhd
Config.FuelScript = 'rhd_fuel' --- rhd_fuel / ox_fuel / LegacyFuel / ps-fuel / cdn-fuel
Config.changeNamePrice = 15000 --- price for changing the name of the vehicle in the garage
Config.SpawnInVehicle = true --- change this to true if you want the player to immediately enter the vehicle when the vehicle is taken out of the garage

--- Additional: (Requires ox_target or qb-target resource)
Config.UseJobVechileShop = true --- Change this to false if you do not want to use the work vehicle shop system from rhd
Config.UsePoliceImpound = true --- change it to false if you don't want to use the police impound system from rhd

Config.InDevelopment = true --- Turn this off when you have finished setting up this garage

Config.TransferVehicle = {
    enable = true,
    price = 100
}

Config.SwapGarage = {
    enable = true,
    price = 500
}

Config.IconAnimation = "fade"
Config.Icons = {
    [8] = "motorcycle",
    [13] = "bicycle",
    [14] = "sailboat",
    [15] = "helicopter",
    [16] = "plane",
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
    Target = {
        groups = {
            police = 0
        }
    },
    location = {
        [1] = {
            blip = {
                enable = true,
                sprite = 473,
                colour = 40
            },
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
        }
    }
}

Config.JobVehicleShop = {
    {
        job = 'police',
        label = 'Police Vehicle Shop',
        ped = {
            model = 'csb_trafficwarden',
            coords = vec(457.9160, -1026.4635, 28.4376, 57.2678)
        },
        spawn = vec(443.9391, -1021.4270, 28.2857, 92.6928),
        vehicle = {
            police = {
                price = 500,
                label = 'Police 1',
                prefixPlate = 'POL', -- Don't have more than 3 letters
                forRank = {
                    [0] = true,
                    [1] = true,
                    [2] = true
                }
            },
            police2 = {
                price = 500,
                label = 'Police 2',
                prefixPlate = 'POL', -- Don't have more than 3 letters
                forRank = {
                    [0] = true,
                    [1] = true,
                    [2] = true
                }
            }
        },
    }
}

Config.HouseGarages = {}
