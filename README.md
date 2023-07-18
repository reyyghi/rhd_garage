# RHD-Garage For ESX or QBCore

# Installation 
### ESX
- edit database owned_vehicles anda seperti di bawah ini :
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
- cari ini di qb-phone/server/main.lua di baris 230:
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
- lalu ganti dengan ini:
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

- cari ini di qb-phone/client/main.lua
```
    QBCore.Functions.TriggerCallback('qb-garage:server:GetPlayerVehicles', function(vehicles)
        PhoneData.GarageVehicles = vehicles
    end)
```
- lalu ganti dengan ini 
```
    PhoneData.GarageVehicles = exports['rhd-garage']:getDataVehicle()
```
