local vehImpound = {}

local saveDataFile = function ()
    if vehImpound then
        SaveResourceFile(GetCurrentResourceName(), 'policeimpound.json', json.encode(vehImpound))
    end
end

lib.callback.register('rhd_garage:cb:getDataPoliceImpound', function(_)
    local dataVeh = {}
    if vehImpound and #vehImpound > 0 then
        for i=1, #vehImpound do
            local prop = json.decode(vehImpound[i].vehprop)
            local date = os.date('%d-%m-%Y', vehImpound[i].date)
            dataVeh[#dataVeh+1] = {
                plate = vehImpound[i].plate,
                vehName = vehImpound[i].vehName,
                owner = vehImpound[i].owner,
                reason = vehImpound[i].reason,
                date = date,
                vehprop = prop
            }
        end
    else
       return false
    end
    return dataVeh
end)

lib.callback.register('rhd_garage:cb:cekDate', function (_, date)
    if os.date('%d-%m-%Y') >= date then
        return true
    end
    return false
end)

RegisterNetEvent('rhd_garage:server:removeData', function( plate )
    if vehImpound and #vehImpound > 0 then
        for i=1, #vehImpound do
            if vehImpound[i].plate == plate then
                table.remove(vehImpound, i)
            end
        end
    end
end)

RegisterNetEvent('rhd_garage:policeimpound:saveData', function ( data )
    if data then

        if vehImpound and #vehImpound > 0 then
            for i=1, #vehImpound do
                if vehImpound[i].plate == data.plate then
                    table.remove(vehImpound, i)
                end
            end
        end

        vehImpound[#vehImpound+1] = data
        saveDataFile()
    end
end)


CreateThread(function()
    vehImpound = {}
    local loadFile = LoadResourceFile(GetCurrentResourceName(), 'policeimpound.json')
    if loadFile then
        vehImpound = json.decode(loadFile)
    else
        vehImpound = {}
    end

    while true do
        Wait(60000 * 1)
        saveDataFile()
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