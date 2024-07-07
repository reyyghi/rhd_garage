storage = {}

--- Save garage data
---@param garageData table<string, GarageData>
function storage.SaveGarage(garageData)
    GarageZone = garageData
    TriggerClientEvent('rhd_garage:client:syncConfig', -1, GarageZone)
    SaveResourceFile(GetCurrentResourceName(), 'data/garages.json', json.encode(GarageZone), -1)
end

--- Save custom vehicle name data
---@param dataName table<string, CustomName>
function storage.SaveVehicleName(dataName)
    CNV = dataName
    SaveResourceFile(GetCurrentResourceName(), 'data/vehiclesname.json', json.encode(CNV), -1)
end