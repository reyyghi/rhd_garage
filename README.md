# RHD-Garage For ESX or QBCore

| Garage script By Reyghita Hafizh Firmanda |
|----|

# Dependencies 
**[ox_lib](https://github.com/overextended/ox_lib/releases)**

**[es_extended](https://github.com/esx-framework/esx_core/tree/main/%5Bcore%5D/es_extended) or [qb-core](https://github.com/qbcore-framework/qb-core)**

# Configuration
```
    ['Garage Label'] = {
        type = 'car' --- type of vehicle, can be a car, boat, planes, helicopter
        blip = { type = 357, color 3 } --- you can find it here (https://docs.fivem.net/docs/game-references/blips/), don't use it if you don't want to use the blip 
        location = vec4(-285.6967, -887.9977, 30.8099, 347.6774) or {vec4(-285.6967, -887.9977, 30.8099, 347.6774)} --- this is the location for entering and removing vehicles from the garage 
        impound = false --- change to true if this is impound garage,
        job = 'police' or {['police'] = 1} --- do not use this if it is a public garage, and it won't work if the impound is turned on
        gang = 'ballas' or {['ballas'] = 2} --- do not use this if it is a public garage, and it won't work if the impound is turned on
    }
```

# Exports 
- open garage
```
    exports['rhd-garage']:openMenu({
        garage = 'Garage Label',
        coords = 'location to get the vehicle out of the garage' type(vector4)
    })
```
- store vehicle
```
    exports['rhd-garage']:storeVehicle({
        garage = 'Garage Label',
        vehicle = veh
    })
```

### Example
```
    RegisterCommand('opengarage', function (src, args)
        local plyCoords = GetEntityCoords(cache.ped)
        local plyHeading = GetEntityHeading(cache.ped)
        local coords = vec4(plyCoords.x, plyCoords.y, plyCoords.z, plyHeading)
        exports['rhd-garage']:openMenu({
            garage = 'Garasi Kota',
            coords = coords
        })
    end)

    RegisterCommand('savegarage', function ()
        local veh = cache.vehicle
        if not cache.vehicle then
            veh = lib.getClosestVehicle(GetEntityCoords(cache.ped))
        end
        exports['rhd-garage']:storeVehicle({
            garage = 'Garasi Kota',
            vehicle = veh
        })
    end)
```

# Installation 
### ESX
- edit your owned_vehicles database as below :
```
    CREATE TABLE IF NOT EXISTS `owned_vehicles` (
    `owner` varchar(60) NOT NULL,
    `plate` varchar(50) NOT NULL DEFAULT '',
    `vehicle` longtext DEFAULT NULL,
    `type` varchar(20) NOT NULL DEFAULT 'car',
    `job` varchar(20) DEFAULT NULL,
    `stored` bigint(20) NOT NULL DEFAULT 0,
    `garage` longtext DEFAULT NULL,
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### QBCore
- look for this in qb-phone/server/main.lua on line 230:
```
    local garageresult = MySQL.query.await('SELECT * FROM player_vehicles WHERE citizenid = ?', {Player.PlayerData.citizenid})
    if garageresult[1] ~= nil then
        for _, v in pairs(garageresult) do
            local vehicleModel = v.vehicle
            if (QBCore.Shared.Vehicles[vehicleModel] ~= nil) and (Config.Garages[v.garage] ~= nil) then
                v.garage = Config.Garages[v.garage].label
                v.vehicle = QBCore.Shared.Vehicles[vehicleModel].name
                v.brand = QBCore.Shared.Vehicles[vehicleModel].brand
            end

        end
        PhoneData.Garage = garageresult
    end
```
- then replace with this:
```
    Config.Garages = exports['rhd-garage']:garageList()
    local garageresult = MySQL.query.await('SELECT * FROM player_vehicles WHERE citizenid = ?', {Player.PlayerData.citizenid})
    if garageresult[1] ~= nil then
        for _, v in pairs(garageresult) do
            local vehicleModel = v.vehicle
            if (QBCore.Shared.Vehicles[vehicleModel] ~= nil) and (Config.Garages[v.garage] ~= nil) then
                v.vehicle = QBCore.Shared.Vehicles[vehicleModel].name
                v.brand = QBCore.Shared.Vehicles[vehicleModel].brand
            end

        end
        PhoneData.Garage = garageresult
    end
```

- look for this in qb-phone/client/main.lua:
```
    QBCore.Functions.TriggerCallback('qb-garage:server:GetPlayerVehicles', function(vehicles)
        PhoneData.GarageVehicles = vehicles
    end)
```
- then replace with this: 
```
    PhoneData.GarageVehicles = exports['rhd-garage']:getDataVehicle()
```
