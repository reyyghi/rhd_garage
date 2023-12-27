# RHD-Garage
The garage system for QBCore and ESX frameworks is created by [dellaaaaaa](https://github.com/dellaaaaaa). We invite you to contribute to this garage script by submitting new features via PR. We're always eager to review and consider new features

# Features
- Public Garage
- House Garage
- Job & Gang Garage
- Custom Blip
- Depot Garage
- Boat Garage
- Aircraft Garage
- Shared Garage
- Save Deformation Damage
- Garage Creator (In Game) ```/creategarage (Admin Only)```
- Garage Editor (In Game) ```/listgarage (Admin Only)```
- Custom Vehicle Name

# Preview
## Garage Creator
![image](https://cdn.discordapp.com/attachments/1027084565602373693/1164986504196673566/image.png?ex=6545353b&is=6532c03b&hm=c15c28f989f64119621201d700bf58e7aca6ee03dfed155d9676f60f1e7951a8&)
![image](https://cdn.discordapp.com/attachments/1027084565602373693/1164986595003346954/image.png?ex=65453550&is=6532c050&hm=be651a6f1bb4109b57665327e36ff8e4b9c78e64565deb6beff881c40d8bfb04&)

## Garage Editor
![image](https://cdn.discordapp.com/attachments/1027084565602373693/1164987595277742110/image.png?ex=6545363f&is=6532c13f&hm=1217bcbf2d335b2dac8d053be7dbb8b9a222e7ce927ca4632d754149937e42ff&)
![image](https://cdn.discordapp.com/attachments/1027084565602373693/1164987705080414218/image.png?ex=65453659&is=6532c159&hm=f9eca35d2609f6fdac5cf7731112f286221dc16ef7f4310f9b407cfafc146281&)


# Dependencies 
**[ox_lib](https://github.com/overextended/ox_lib/releases)**

**[es_extended](https://github.com/esx-framework/esx_core/tree/main/%5Bcore%5D/es_extended) or [qb-core](https://github.com/qbcore-framework/qb-core)**

**[fivem-freecam](https://github.com/Deltanic/fivem-freecam)**

# Configuration
```lua
    return {
        ["Alta Garage"] = { --- Garage Label
            type = "car", --- Type of vehicle
            blip = { type = 357, color = 3 }, --- Garage Blip
            zones = { --- Garage Zone (Use ox_lib zone)
                points = {
                    vec3(-307.01000976562, -894.86999511719, 31.0),
                    vec3(-308.20001220703, -901.0, 31.0),
                    vec3(-315.57998657227, -899.45001220703, 31.0),
                    vec3(-314.23999023438, -893.32000732422, 31.0),
                },
                thickness = "4.0"
            },
            job = nil, --- Jobs Access
            gang = nil, --- Gang Access
            impound = false, --- Change it to true if you want to make it insurance
            shared = false, --- Change it to true if you want to make it a shared garage
        },
    }
```

# Exports 
- open garage
```lua
    exports.rhd_garage:openMenu({
        garage = 'Garage Label',
        impound = false,
        shared = false,
        type = "car"
    })
```
- store vehicle
```lua
    exports.rhd_garage:storeVehicle({
        vehicle = cache.vehicle,
        garage = 'Garage Label',
        shared = false,
        type = "car"
    })
```
- get vehicle data by plate
```lua
    exports.rhd_garage:getvehdataByPlate(plate)
```
- get vehicle data for phone
```lua
    exports.rhd_garage:getvehdataForPhone()
```
- get all garage ( server side )
```lua
    exports.rhd_garage:Garage()
```

### Example
```lua
    RegisterCommand('opengarage', function (src, args)
        exports.rhd_garage:openMenu({
            garage = 'Garage Label',
            impound = false,
            shared = false,
            type = "car"
        })
    end)

    RegisterCommand('savegarage', function ()
        local veh = cache.vehicle
        if not cache.vehicle then
            veh = lib.getClosestVehicle(GetEntityCoords(cache.ped))
        end
        exports.rhd_garage:storeVehicle({
            vehicle = veh,
            garage = 'Garage Label',
            shared = false,
            type = "car"
        })
    end)
```

# Installation 

### ESX
- Run this on your database :
```sql
   ALTER TABLE owned_vehicles CHANGE COLUMN stored stored INT(11) NOT NULL DEFAULT 0;
    
   ALTER TABLE owned_vehicles ADD COLUMN garage LONGTEXT NULL AFTER stored;
    
   ALTER TABLE owned_vehicles ADD COLUMN deformation LONGTEXT NULL
```

### QBCore
- Run this on your database :
```sql
   ALTER TABLE player_vehicles ADD COLUMN deformation LONGTEXT NULL
```

#### qb-phone
- look for this in qb-phone/server/main.lua on line 230:
```lua
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
```lua
    local Garages = exports.rhd_garage:Garage()
    local garageresult = MySQL.query.await('SELECT * FROM player_vehicles WHERE citizenid = ?', {Player.PlayerData.citizenid})
    if garageresult[1] ~= nil then
        for _, v in pairs(garageresult) do
            local vehicleModel = v.vehicle
            if (QBCore.Shared.Vehicles[vehicleModel] ~= nil) and (Garages[v.garage] ~= nil) then
                v.vehicle = QBCore.Shared.Vehicles[vehicleModel].name
                v.brand = QBCore.Shared.Vehicles[vehicleModel].brand
            end

        end
        PhoneData.Garage = garageresult
    end
```


- look for this in qb-phone/client/main.lua on line 302:
```lua
    QBCore.Functions.TriggerCallback('qb-garage:server:GetPlayerVehicles', function(vehicles)
        PhoneData.GarageVehicles = vehicles
    end)
```
- then replace with this: 
```lua
    PhoneData.GarageVehicles = exports.rhd_garage:getvehdataForPhone()
```

#### qb-phone (Renewed-Scripts)
- look for this in qb-phone/client/garage.lua on line 21 - 40:
```lua
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
```lua
    RegisterNUICallback('SetupGarageVehicles', function(_, cb)
        local veh = exports.rhd_garage:getvehdataForPhone()
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
```

#### qb-vehiclesales
- look for this in qb-vehiclesales/client/main.lua on line 270 and 319:
```lua
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
```lua
    line 270:

    local ownerData = exports.rhd_garage:getvehdataByPlate( vehicleData.plate )
    if not ownerData then
        QBCore.Functions.Notify(Lang:t('error.not_your_vehicle'), 'error', 3500)
        return
    end

    if ownerData.balance < 1 then
        TriggerServerEvent('qb-occasions:server:sellVehicleBack', vehicleData)
        QBCore.Functions.DeleteVehicle(vehicle)
    else
        QBCore.Functions.Notify(Lang:t('error.finish_payments'), 'error', 3500)
    end

    line 319:

    local ownerData = exports.rhd_garage:getvehdataByPlate( VehiclePlate )
    if not ownerData then
        QBCore.Functions.Notify(Lang:t('error.not_your_vehicle'), 'error', 3500)
        return
    end

    if ownerData.balance < 1 then
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
```
