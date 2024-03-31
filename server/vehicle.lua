if GetCurrentResourceName() ~= "rhd_garage" then return end

function GetPlayerVehicles (source)
    local select_column = DBFormat.selected_column.vehicleList.normal
    local table_vehicles = DBFormat.table.player_vehicles
    local owner_column = DBFormat.column.owner
    local identifier = Framework.server.getIdentifier(source)
    
    return MySQL.query.await("SELECT " .. select_column .. " FROM " .. table_vehicles .. " WHERE " .. owner_column, {identifier})
end

function GetAllPlayerVehicleByPlate(source, plate, state)
    local select_column = DBFormat.selected_column.vehicleList.normal
    local table_vehicles = DBFormat.table.player_vehicles
    local owner_column = DBFormat.column.owner
    local plate_column = DBFormat.column.plate
    local state_column = DBFormat.column.state
    local identifier = Framework.server.getIdentifier(source)

    local param = state and ("%s AND %s AND %s"):format(owner_column, plate_column, state_column) or ("%s AND %s"):format(owner_column, plate_column)
    local value = state and {identifier, plate, state} or {identifier, plate}
    
    return MySQL.query.await("SELECT " .. select_column .. " FROM " .. table_vehicles .. " WHERE " .. param, value)
end

function GetAllDataPlayerVehicles (source)
    local table_vehicles = DBFormat.table.player_vehicles
    local owner_column = DBFormat.column.owner
    local identifier = Framework.server.getIdentifier(source)

    return MySQL.query.await("SELECT * FROM " .. table_vehicles .. " WHERE " .. owner_column, {identifier})
end

function GetVehicleOutByPlate(plate)
    local veh = GetAllVehicles()
    for i=1, #veh do
        local entity = veh[i]
        local Plate = utils.getPlate(entity)
        if Plate == plate then
            return entity
        end
    end
    return false
end

function GetPlayerVehiclesForQBPhone(src)
    local Vehicles = {}
    local result = GetAllDataPlayerVehicles(src)
    if not result[1] then return {} end
    for i=1, #result do
        local db = result[i]
        local VehicleData = IsQB and Framework.server.getSharedVehicle(db.vehicle) or false
        local mods = json.decode(db[DBFormat.column.properties])
        local model = mods.model
        local plate = mods.plate:trim()
        local VehicleGarage = 'None'
        local garageLocation = nil
        local EntityExist = GetVehicleOutByPlate(plate)
        local inPoliceImpound, inInsurance = false, false
        local body = mods.bodyHealth and math.floor(mods.bodyHealth) or 100
        local engine = mods.engineHealth and math.floor(mods.engineHealth) or 100

        if body > 1000 then
            body = 1000
        end
        if engine > 1000 then
            engine = 1000
        end

        if db.state == 0 then
            db.state = locale('rhd_garage:phone_veh_out_garage')
            if not EntityExist then
                db.state = locale('rhd_garage:phone_veh_in_impound')
                inInsurance = true
            end
        elseif db.state == 1 then
            db.state = locale('rhd_garage:phone_veh_in_garage')
        elseif db.state == 2 then
            db.state = locale('rhd_garage:phone_veh_in_policeimpound')
            inPoliceImpound = true
        end

        if db.garage ~= nil then
            if GarageZone[db.garage] ~= nil then
                if db.state ~= 0 and db.state ~= 2 then
                    VehicleGarage = db.garage
                    local L = GarageZone[db.garage]?.zones.points
                    if L and #L > 1 then
                        for loc=1, #L do
                            garageLocation = L[loc].xyz
                        end
                    end
                end
            else
                if db.state == 1 then
                    local HouseGarage = Config.HouseGarages
                    for k, v in pairs(HouseGarage) do
                        if v.label == db.garage then
                            VehicleGarage = db.garage
                            local L = v.takeVehicle
                            garageLocation = vec3(L.x, L.y, L.z)
                        end
                    end
                end
            end
        end

        if VehicleData and next(VehicleData) then
            
            local fullname
            if VehicleData["brand"] ~= nil then
                fullname = VehicleData["brand"] .. " " .. VehicleData["name"]
            else
                fullname = VehicleData["name"]
            end

            Vehicles[#Vehicles+1] = {
                fullname = CNV[plate] and CNV[plate].name or fullname,
                brand = VehicleData["brand"],
                model = VehicleData["name"],
                plate = plate,
                garage = VehicleGarage,
                state = db.state,
                fuel = mods.fuelLevel,
                engine = engine,
                body = body,
                paymentsleft = db.paymentsleft,
                garageLocation = garageLocation,
                inInsurance = inInsurance,
                inPoliceImpound = inPoliceImpound
            }
        else
            VehicleData[#VehicleData+1] = {
                plate = plate,
                model = model,
                garage = VehicleGarage,
                state = db.state,
                fuel = mods.fuelLevel,
                engine = engine,
                body = body,
                paymentsleft = db.paymentsleft,
                garageLocation = garageLocation,
                inInsurance = inInsurance,
                inPoliceImpound = inPoliceImpound
            }
        end
    end
    return Vehicles
end

exports('GetPlayerVehicles', GetPlayerVehicles)
exports('GetAllDataPlayerVehicles', GetAllDataPlayerVehicles)
exports('GetPlayerVehiclesForPhone', GetPlayerVehiclesForQBPhone)
exports('GetAllPlayerVehicleByPlate', GetAllPlayerVehicleByPlate)