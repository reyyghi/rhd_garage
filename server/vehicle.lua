-- if GetCurrentResourceName() ~= "rhd_garage" then return end

-- vehFunc = {}

-- --- Get Vehicle Mods By Plate
-- ---@param plate string
-- ---@return table?
-- ---@return table?
-- function vehFunc.gvmbp(plate)
--     local dbval = fw.qb and {plate, plate} or {plate}
--     local format = "SELECT " .. db.mods .. ", deformation FROM " .. db.player_vehicles .. " WHERE " .. db.filter.plate
--     local results = MySQL.single.await(format, dbval)
--     local mods, deformation = {}, {}

--     if results[db.mods] and results.deformation then
--         mods = json.decode(results[db.mods])
--         deformation = json.decode(results.deformation)
--     end

--     return mods, deformation
-- end

-- --- Check Vehicle Owner By PLate
-- ---@param src number
-- ---@param plate string
-- ---@param filter {garage: string, owner: boolean}?
-- function vehFunc.cvobp(src, plate, filter)
--     local identifier = fw.gi(src)
--     if not identifier then return false end
--     local dbval = fw.qb and {plate, plate} or {plate}

--     local format = ([[
--         SELECT pv.%s, %s, %s FROM %s pv LEFT JOIN %s p ON p.%s = pv.%s WHERE (%s)
--     ]]):format(db.owner, db.player_name.first, db.player_name.last, db.player_vehicles, db.players, db.owner, db.identifier, db.filter.plate)

--     if filter then
--         if filter.garage then
--             format = format .. " AND pv.garage = ?"
--             dbval[#dbval+1] = filter.garage
--         end
    
--         if filter.owner then
--             format = format .. " AND pv.".. db.owner .." = ?"
--             dbval[#dbval+1] = identifier
--         end
--     end

--     local results = MySQL.single.await(format, dbval)
--     if not results then return false end
--     local firstname = results[db.player_name.first] or false
--     local lastname = results[db.player_name.last] or false
--     local citizenid = results[db.owner] or false

--     if not firstname or not lastname or not citizenid then
--         return false
--     end

--     return {
--         name = firstname .. " " .. lastname,
--         identifier = citizenid
--     }
-- end

-- --- Get Player Vehicles By Garage
-- ---@param source number
-- ---@param filter {shared: boolean, impound: boolean}?
-- ---@return table | boolean
-- function vehFunc.gpvbg (source, garage, filter)
--     local identifier = fw.gi(source)
--     if not identifier then return false end

--     local format = ([[
--         SELECT %s FROM %s  
--     ]]):format(db.select.vehlist, db.player_name.first, db.player_name.last, db.player_vehicles, db.players, db.owner, db.identifier)

--     local addonFormat = ("WHERE pv.garage = ? AND pv.%s = ?"):format(db.owner)
--     local dbvalue = {garage, identifier}

--     if filter then
--         if filter.impound then
--             addonFormat = ("WHERE pv.%s = ? AND pv.%s = ?"):format(db.state, db.owner)
--             dbvalue = {0, identifier}
--         elseif filter.shared then
--             addonFormat = ("WHERE pv.garage = ? AND pv.%s = ?"):format(db.state)
--             dbvalue = {garage, 1}
--         end
--     end

--     format = format .. addonFormat

--     return MySQL.query.await(format, dbvalue)
-- end

-- RegisterCommand("testaja", function (src)
--     local veh = vehFunc:gpvbg(src, "Motel Parking", {
--         impound = true
--     })

--     print(veh and #veh or false)
-- end, false)

-- function GetAllPlayerVehicleByPlate(source, plate, state)
--     local select_column = DBFormat.selected_column.vehicleList.normal
--     local table_vehicles = DBFormat.table.player_vehicles
--     local owner_column = DBFormat.column.owner
--     local plate_column = DBFormat.column.plate
--     local state_column = DBFormat.column.state
--     local identifier = Framework.server.getIdentifier(source)

--     local param = state and ("%s AND %s AND %s"):format(owner_column, plate_column, state_column) or ("%s AND %s"):format(owner_column, plate_column)
--     local value = state and {identifier, plate, state} or {identifier, plate}
    
--     return MySQL.query.await("SELECT " .. select_column .. " FROM " .. table_vehicles .. " WHERE " .. param, value)
-- end

-- function GetAllDataPlayerVehicles (source)
--     local table_vehicles = DBFormat.table.player_vehicles
--     local owner_column = DBFormat.column.owner
--     local identifier = Framework.server.getIdentifier(source)

--     return MySQL.query.await("SELECT * FROM " .. table_vehicles .. " WHERE " .. owner_column, {identifier})
-- end

-- function GetVehicleOutByPlate(plate)
--     local veh = GetAllVehicles()
--     for i=1, #veh do
--         local entity = veh[i]
--         local Plate = utils.getPlate(entity)
--         if Plate == plate then
--             return entity
--         end
--     end
--     return false
-- end

-- function GetPlayerVehiclesForQBPhone(src)
--     local Vehicles = {}
--     local result = GetAllDataPlayerVehicles(src)
--     if not result[1] then return {} end
--     for i=1, #result do
--         local db = result[i]
--         local VehicleData = IsQB and Framework.server.getSharedVehicle(db.vehicle) or false
--         local mods = json.decode(db[DBFormat.column.properties])
--         local model = mods.model
--         local plate = mods.plate:trim()
--         local VehicleGarage = 'None'
--         local garageLocation = nil
--         local EntityExist = GetVehicleOutByPlate(plate)
--         local inPoliceImpound, inInsurance = false, false
--         local body = mods.bodyHealth and math.floor(mods.bodyHealth) or 100
--         local engine = mods.engineHealth and math.floor(mods.engineHealth) or 100

--         if body > 1000 then
--             body = 1000
--         end
--         if engine > 1000 then
--             engine = 1000
--         end

--         if db.state == 0 then
--             db.state = locale('rhd_garage:phone_veh_out_garage')
--             if not EntityExist then
--                 db.state = locale('rhd_garage:phone_veh_in_impound')
--                 inInsurance = true
--             end
--         elseif db.state == 1 then
--             db.state = locale('rhd_garage:phone_veh_in_garage')
--         elseif db.state == 2 then
--             db.state = locale('rhd_garage:phone_veh_in_policeimpound')
--             inPoliceImpound = true
--         end

--         if db.garage ~= nil then
--             if GarageZone[db.garage] ~= nil then
--                 if db.state ~= 0 and db.state ~= 2 then
--                     VehicleGarage = db.garage
--                     local L = GarageZone[db.garage]?.zones.points
--                     if L and #L > 1 then
--                         for loc=1, #L do
--                             garageLocation = L[loc].xyz
--                         end
--                     end
--                 end
--             else
--                 if db.state == 1 then
--                     local HouseGarage = Config.HouseGarages
--                     for k, v in pairs(HouseGarage) do
--                         if v.label == db.garage then
--                             VehicleGarage = db.garage
--                             local L = v.takeVehicle
--                             garageLocation = vec3(L.x, L.y, L.z)
--                         end
--                     end
--                 end
--             end
--         end

--         if VehicleData and next(VehicleData) then
            
--             local fullname
--             if VehicleData["brand"] ~= nil then
--                 fullname = VehicleData["brand"] .. " " .. VehicleData["name"]
--             else
--                 fullname = VehicleData["name"]
--             end

--             Vehicles[#Vehicles+1] = {
--                 fullname = CNV[plate] and CNV[plate].name or fullname,
--                 brand = VehicleData["brand"],
--                 model = VehicleData["name"],
--                 plate = plate,
--                 garage = VehicleGarage,
--                 state = db.state,
--                 fuel = mods.fuelLevel,
--                 engine = engine,
--                 body = body,
--                 paymentsleft = db.paymentsleft,
--                 garageLocation = garageLocation,
--                 inInsurance = inInsurance,
--                 inPoliceImpound = inPoliceImpound
--             }
--         else
--             VehicleData[#VehicleData+1] = {
--                 plate = plate,
--                 model = model,
--                 garage = VehicleGarage,
--                 state = db.state,
--                 fuel = mods.fuelLevel,
--                 engine = engine,
--                 body = body,
--                 paymentsleft = db.paymentsleft,
--                 garageLocation = garageLocation,
--                 inInsurance = inInsurance,
--                 inPoliceImpound = inPoliceImpound
--             }
--         end
--     end
--     return Vehicles
-- end

-- exports('GetPlayerVehicles', GetPlayerVehicles)
-- exports('GetAllDataPlayerVehicles', GetAllDataPlayerVehicles)
-- exports('GetPlayerVehiclesForPhone', GetPlayerVehiclesForQBPhone)
-- exports('GetAllPlayerVehicleByPlate', GetAllPlayerVehicleByPlate)