if Config.RadialMenu ~= "rhd" then return end

radFunc = {}

function radFunc.create(data)
    exports.rhd_radialmenu:addRadialItem({
        id = data.id,
        label = data.label,
        icon = data.icon,
        action = function ()
            if data.id == "open_garage" and not cache.vehicle then
                exports.rhd_garage:openMenu({
                    garage = data.garage.label,
                    impound = data.garage.impound,
                    shared = data.garage.shared,
                    type = data.garage.type
                })
            elseif data.id == "store_veh" then
                exports.rhd_garage:storeVehicle({garage = data.garage.label, shared = data.garage.shared})
            end
        end
    })
end

function radFunc.remove(id)
    exports.rhd_radialmenu:removeRadialItem(id)
end
