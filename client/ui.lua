UI = {
    Action = {}
}

local zones = lib.load('config.garages')

RegisterNUICallback('getGarageList', function (_, cb)
    local garageList = {}
    Array.forEach(zones, function (data)
        garageList[#garageList+1] = data.label
    end)
    cb(garageList)
end)

RegisterNUICallback('onClose', function (_, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('triggerAction', function (vehicle, cb)
    local data = UI.Action[vehicle.plate]
    if data and data[vehicle.action] then
        data[vehicle.action](vehicle.args)
        table.wipe(UI.Action)
    end
    cb('ok')
end)

function UI.sendMessage(garageData)
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'setVisible',
        data = {
            visible = true,
            garage = garageData
        }
    })
end