if Config.RadialMenu ~= "qb" then return end

radFunc = {}
local radaial = {}
local utils = lib.load("modules.utils")

function radFunc.create(data)
    local id = data.id:gsub("%s+", "")
    radaial[id] = exports['qb-radialmenu']:AddOption({
        id = id,
        title = data.label,
        icon = data.icon == "parking" and "square-parking" or data.icon,
        type = 'client',
        event = data.event,
        garage = data.garage,
        shouldClose = true
    }, radaial[id])
    return radaial[id]
end

function radFunc.remove(id)
    if radaial[id] then
        exports['qb-radialmenu']:RemoveOption(radaial[id])
    end
end


---@param self table
RegisterNetEvent("rhd_garage:radial:open", function (self)
    if not cache.vehicle then
        exports.rhd_garage:openMenu( {garage = self.garage.label, impound = self.garage.impound, shared = self.garage.shared, type = self.garage.type} )
    end
end)

---@param self table
RegisterNetEvent("rhd_garage:radial:store", function (self)
    exports.rhd_garage:storeVehicle({
        garage = self.garage.label,
        shared = self.garage.shared
    })
end)

RegisterNetEvent('rhd_garage:radial:open_policeimpound', function(self)
    if not cache.vehicle then
        exports.rhd_garage:openpoliceImpound( self.garage )
    end
end)
