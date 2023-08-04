local CNV = {}

lib.callback.register('getCNV', function(_, plate)
    for i=1, #CNV do
        if CNV[i].plate == plate then
            return CNV[i].vehName
        end
    end
    return false
end)

local saveDataFile = function ()
    if #CNV > 0 then
        SaveResourceFile(GetCurrentResourceName(), 'vehname.json', json.encode(CNV))
    end
end

Framework.server.getCNV = function ( pV )
    local plate = Framework.server.GetVehPlate(pV)
    for i=1, #CNV do
        if CNV[i].plate == plate then
            return CNV[i].vehName
        end
    end
    return false
end

exports('getCNV', function ( plate )
    return Framework.server.getCNV( plate )
end)


CreateThread(function()
    CNV = {}
    local loadFile = LoadResourceFile(GetCurrentResourceName(), 'vehname.json')
    if loadFile then
        CNV = json.decode(loadFile)

        Wait(100)
        if not CNV then
            CNV = {}
        end
    else
        CNV = {}
    end

    while true do
        Wait(60000 * 60 * Config.saveDataInterval)
        saveDataFile()
    end
end)

RegisterNetEvent('rhd_garage:server:saveDataName', function( cnV )
    if Framework.server.removeMoney('cash', Config.changeNamePrice) then
        for i=1, #CNV do
            if CNV[i].plate == cnV.plate then
                table.remove(CNV, i)
            end
        end
        CNV[#CNV+1] = cnV
    end
end)

AddEventHandler('txAdmin:events:serverShuttingDown', function()
    saveDataFile()
end)

AddEventHandler('onResourceStop', function(ResourceName)
    if ResourceName == GetCurrentResourceName() then
        saveDataFile()
    end
end)