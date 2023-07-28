# RHD-Garage For ESX or QBCore

| Made with love By Reyghita Hafizh & Della Kholida |
|----|

# Preview
**[Garage](https://youtu.be/SGB9riBBz-g)**

**[Police Impound](https://youtu.be/YdUdLlCLJpg)**

# Features
- Public Garage
- House Garage
- Job & Gang Garage
- Custom Blip
- Depot Garage
- Boat Garage
- Aircraft Garage
- Police Impound Garage
- Vehicle confiscation for the police
- Shared Garage

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
        shared = false --- change to true if you want this garage to be a shared garage. not recommended for public garages
    }
```

# Exports 
- open garage
```
    exports.rhd_garage:openMenu({
        garage = 'Garage Label',
        coords = 'location to get the vehicle out of the garage' type(vector4)
    })
```
- store vehicle
```
    exports.rhd_garage:storeVehicle({
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
        exports.rhd_garage:openMenu({
            garage = 'Garasi Kota',
            coords = coords
        })
    end)

    RegisterCommand('savegarage', function ()
        local veh = cache.vehicle
        if not cache.vehicle then
            veh = lib.getClosestVehicle(GetEntityCoords(cache.ped))
        end
        exports.rhd_garage:storeVehicle({
            garage = 'Garasi Kota',
            vehicle = veh
        })
    end)
```

# Installation 

### ESX
- edit your owned_vehicles database as below :
```
    CREATE TABLE `owned_vehicles` (
    	`owner` VARCHAR(60) NOT NULL,
    	`plate` varchar(12) NOT NULL,
    	`vehicle` longtext,
    	`type` VARCHAR(20) NOT NULL DEFAULT 'car',
    	`job` VARCHAR(20) NULL DEFAULT NULL,
        `stored` bigint(20) NOT NULL DEFAULT 0,
        `garage` longtext DEFAULT NULL,
    
    	PRIMARY KEY (`plate`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### QBCore
#### qb-phone
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
    Config.Garages = exports.rhd_garage:garageList()
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


- look for this in qb-phone/client/main.lua on line 302:
```
    QBCore.Functions.TriggerCallback('qb-garage:server:GetPlayerVehicles', function(vehicles)
        PhoneData.GarageVehicles = vehicles
    end)
```
- then replace with this: 
```
    PhoneData.GarageVehicles = exports.rhd_garage:getDataVehicle()
```

#### qb-phone (Renewed-Scripts) 
- look for this in qb-phone/client/garage.lua on line 21 - 40:
```
    RegisterNUICallback('SetupGarageVehicles', function(_, cb)
        QBCore.Functions.TriggerCallback('qb-phone:server:GetGarageVehicles', function(vehicles)
            cb(vehicles)
        end)
    end)
    
    RegisterNUICallback('gps-vehicle-garage', function(data, cb)
        local veh = data.veh
        if veh.state == 'In' then
            if veh.parkingspot then
                SetNewWaypoint(veh.parkingspot.x, veh.parkingspot.y)
                QBCore.Functions.Notify("Your vehicle has been marked", "success")
            end
        elseif veh.state == 'Out' and findVehFromPlateAndLocate(veh.plate) then
            QBCore.Functions.Notify("Your vehicle has been marked", "success")
        else
            QBCore.Functions.Notify("This vehicle cannot be located", "error")
        end
        cb("ok")
    end)
```
- then replace with this:
```
    RegisterNUICallback('SetupGarageVehicles', function(_, cb)
        local veh = exports.rhd_garage:getDataVehicle()
        cb(veh)
    end)
    
    RegisterNUICallback('gps-vehicle-garage', function(data, cb)
        local veh = data.veh
        if veh.inInsurance then return QBCore.Functions.Notify("This vehicle cannot be located", "error") end
        if veh.inPoliceImpound then return QBCore.Functions.Notify("This vehicle cannot be located", "error") end
        local location = json.decode(veh.garageLocation)
        if location then
            SetNewWaypoint(vec2(location.x, location.y))
            QBCore.Functions.Notify("Your vehicle has been marked", "success")
        else
            if exports.rhd_garage:trackOutVeh( veh.plate ) then
                QBCore.Functions.Notify("Your vehicle has been marked", "success")
            else
                QBCore.Functions.Notify("This vehicle cannot be located", "error")
            end
        end
    
        cb("ok")
    end)

#### qb-vehiclesales
- look for this in qb-vehiclesales/client/main.lua on line 270 and 319:
```
    line 270:
    QBCore.Functions.TriggerCallback('qb-garage:server:checkVehicleOwner', function(owned, balance)
        if owned then
            if balance < 1 then
                TriggerServerEvent('qb-occasions:server:sellVehicleBack', vehicleData)
                QBCore.Functions.DeleteVehicle(vehicle)
            else
                QBCore.Functions.Notify(Lang:t('error.finish_payments'), 'error', 3500)
            end
        else
            QBCore.Functions.Notify(Lang:t('error.not_your_vehicle'), 'error', 3500)
        end
    end, vehicleData.plate)

    line 319:
    QBCore.Functions.TriggerCallback('qb-garage:server:checkVehicleOwner', function(owned, balance)
        if owned then
            if balance < 1 then
                QBCore.Functions.TriggerCallback('qb-occasions:server:getVehicles', function(vehicles)
                    if vehicles == nil or #vehicles < #Config.Zones[Zone].VehicleSpots then
                        openSellContract(true)
                    else
                        QBCore.Functions.Notify(Lang:t('error.no_space_on_lot'), 'error', 3500)
                    end
                end)
            else
                QBCore.Functions.Notify(Lang:t('error.finish_payments'), 'error', 3500)
            end
        else
            QBCore.Functions.Notify(Lang:t('error.not_your_vehicle'), 'error', 3500)
        end
    end, VehiclePlate)
```
- then replace with this: 
```
    line 270:
    exports.rhd_garage:isPlyVeh(vehicleData.plate, function (owned, balance)
        if owned then
            if balance < 1 then
                TriggerServerEvent('qb-occasions:server:sellVehicleBack', vehicleData)
                QBCore.Functions.DeleteVehicle(vehicle)
            else
                QBCore.Functions.Notify(Lang:t('error.finish_payments'), 'error', 3500)
            end
        else
            QBCore.Functions.Notify(Lang:t('error.not_your_vehicle'), 'error', 3500)
        end
    end)

    line 319:
    exports.rhd_garage:isPlyVeh(VehiclePlate, function (owned, balance)
        if owned then
            if balance < 1 then
                QBCore.Functions.TriggerCallback('qb-occasions:server:getVehicles', function(vehicles)
                    if vehicles == nil or #vehicles < #Config.Zones[Zone].VehicleSpots then
                        openSellContract(true)
                    else
                        QBCore.Functions.Notify(Lang:t('error.no_space_on_lot'), 'error', 3500)
                    end
                end)
            else
                QBCore.Functions.Notify(Lang:t('error.finish_payments'), 'error', 3500)
            end
        else
            QBCore.Functions.Notify(Lang:t('error.not_your_vehicle'), 'error', 3500)
        end
    end, VehiclePlate)
```
