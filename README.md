# RHD-Garage For ESX or QBCore

# Dependencies 
**[ox_lib](https://github.com/overextended/ox_lib/releases)**

**[es_extended](https://github.com/esx-framework/esx_core/tree/main/%5Bcore%5D/es_extended) or [qb-core](https://github.com/qbcore-framework/qb-core)**

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
