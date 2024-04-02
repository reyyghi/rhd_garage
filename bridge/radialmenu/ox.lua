if Config.RadialMenu == "qb" or Config.RadialMenu == "rhd" then return end

radFunc = {}
function radFunc.create(data)
    return lib.addRadialItem({
        {
            id = data.id,
            label = data.label,
            icon = data.icon,
            onSelect = function ()
                exports.rhd_garage:openMenu({
                    garage = data.label,
                    impound = data.garage.impound,
                    shared = data.garage.shared,
                    type = data.garage.type
                })
            end
        },
    })
end

function radFunc.remove(id)
    return lib.removeRadialItem(id)
end
