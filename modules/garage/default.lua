---@class GARAGE : OxClass
local GARAGE = lib.class('GARAGE')

---@class garageZoneBlip
---@field label string
---@field sprite number
---@field colour number
---@field coords? vector3

---@class garageZonePoints
---@field points vector3[]
---@field thickness number

---@class garageTargetPed
---@field model string
---@field coords vector4

---@class garageZone
---@field type string
---@field label string
---@field zones garageZonePoints
---@field interaction string|garageTargetPed
---@field blip? garageZoneBlip
---@field groups? string|string[]|table<string, number>

local interact = require 'modules.garage.interact'

---@param blip garageZoneBlip
local function createBlip(blip)
    local entity = AddBlipForCoord(blip.coords.x, blip.coords.y, blip.coords.z)
    SetBlipSprite(entity, blip.sprite)
    SetBlipScale(entity, 0.9)
    SetBlipColour(entity, blip.colour)
    SetBlipDisplay(entity, 4)
    SetBlipAsShortRange(entity, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(blip.label)
    EndTextCommandSetBlipName(entity)
    return entity
end

local function searchVehicleMenu()

    local input = lib.inputDialog(('%s\'s Vehicles'):format(PLAYER.name), {
        { type = 'input', label = 'Enter vehicle plate number', required = true },
    })

    local plate = input and input[1]

    if not plate then
        return
    end

    if utils.string.isEmpty(plate) then
        return
    end

    local entityCoords = lib.callback.await('rhd_garage:server:getVehicleLocationByPlate', false, plate)
    if not entityCoords then return end

    SetNewWaypoint(entityCoords.x,entityCoords.y)
    utils.notify('Your vehicle\'s location is marked on the map.', 'success', 8000)
end

local function changeVehicleName(plate)
    local input = lib.inputDialog(('%s\'s Vehicles'):format(PLAYER.name), {
        { type = 'input', label = 'Enter a new name for your vehicle', required = true },
    })

    local vehicleName = input and input[1]

    if not vehicleName then
        return
    end

    local question = 'Are you sure you want to change the vehicle name to "%s"? If confirmed, you will be charged $%s.'

    local alert = lib.alertDialog({
        header = 'Confirm Vehicle Name Change',
        content = question:format(vehicleName, lib.math.groupdigits(Config.ChangeVehicleName.price)),
        centered = true,
        cancel = true,
    })

    if alert == 'confirm' then
        local success = lib.callback.await('rhd_garage:server:changeVehicleName', false, {
            name = vehicleName,
            plate = plate,
            price = Config.ChangeVehicleName.price
        })
    end
end

local function generateMetadata(data)
    local results = {}

    if data.engine then
        results[#results+1] = {
            label = 'Engine',
            value = data.engine,
            progress = data.engine,
            colorScheme = utils.context.getColourScheme(data.engine)
        }
    end

    if data.body then
        results[#results+1] = {
            label = 'Body',
            value = data.body,
            progress = data.body,
            colorScheme = utils.context.getColourScheme(data.body)
        }
    end
    
    if data.fuel then
        results[#results+1] = {
            label = 'Fuel',
            value = data.fuel,
            progress = data.fuel,
            colorScheme = utils.context.getColourScheme(data.fuel)
        }
    end

    return results
end


---@param zoneData garageZone
function GARAGE:constructor(zoneData)
    self.label = zoneData.label

    self.blip = zoneData.blip and createBlip({
        label = zoneData.label,
        sprite = zoneData.blip.sprite,
        colour = zoneData.blip.colour,
        coords = zoneData.zones.points[1]
    })

    self.type = zoneData.type
    self.groups = zoneData.groups

    self.zones = lib.zones.poly({
        points = zoneData.zones.points,
        thickness = zoneData.zones.thickness,
        onEnter = function ()
            self:enterZone()
        end,
        inside = function ()
            self:insideZone()
        end,
        onExit = function ()
            self:exitZone()
        end
    })

    self.interaction = zoneData.interaction

    return self
end

function GARAGE:remove()
    self:removeBlip()
    self.zones:remove()
end

---@param blip garageZoneBlip
function GARAGE:addBlip(blip)
    self.blip = createBlip(blip)
end

function GARAGE:removeBlip()
    if DoesBlipExist(self.blip) then
        RemoveBlip(self.blip)
    end
end

function GARAGE:insideZone()
    -- print('masuk zona')
end

function GARAGE:enterZone()
    self.interactionData = interact:new('targetped', {
        model = 'mp_m_freemode_01',
        coords = vec(279.3975, -342.1094, 44.9199, 44.8222),
        icon = 'warehouse',
        label = 'Access ' .. self.label,
        onSelect = function ()
            self:getVehicles()
        end,
        distance = 1.5
    })
end

function GARAGE:exitZone()
    if self.interactionData then
        self.interactionData:remove()
        self.interactionData = nil
    end
end

function GARAGE:createVehicleMenu(veh)
    local icon = utils.context.getVehicleIcon(veh.model)
    local originalName = utils.vehicle.getVehicleLabel(veh.model)
    local label = veh.label or originalName
    local status = veh.engine < 80 and 'Need repair' or 'Good'
    local desc = ('Plate: %s | Status: %s'):format(veh.plate, status)

    local context = {
        id = self.label .. 2,
        title = self.label,
        menu = self.label .. 1,
        onBack = function () end,
        options = {
            {
                title = label,
                icon = icon,
                description = desc,
                metadata = generateMetadata(veh),
                readOnly = true
            }
        }
    }

    if Config.ChangeVehicleName.enable then
        context.options[#context.options+1] = {
            title = 'Change Vehicle Name',
            icon = 'pen-to-square',
            description = 'Allows you to rename your vehicle to a custom name.',
            metadata = {
                price = '$' .. lib.math.groupdigits(Config.ChangeVehicleName.price)
            },
            onSelect = function ()
                changeVehicleName(veh.plate)
            end
        }
    end

    utils.context.openMenu(context)
end

function GARAGE:getVehicles()
    local vehicles = lib.callback.await('rhd_garage:server:getVehicles', false, {
        garage = self.label,
        impound = self.type == 'impound',
        shared = self.type == 'shared'
    })

    local context = {
        id = self.label .. 1,
        title = self.label,
        options = {
            {
                title = 'Find Vehicles',
                icon = 'magnifying-glass',
                description = 'Find where your vehicles are located.',
                onSelect = searchVehicleMenu
            }
        }
    }

    if vehicles then
        lib.array.forEach(vehicles, function (veh)
            local icon = utils.context.getVehicleIcon(veh.model)
            local originalName = utils.vehicle.getVehicleLabel(veh.model)
            local label = veh.label or originalName
            local status = veh.engine < 80 and 'Need repair' or 'Good'
            local desc = ('Plate: %s | Status: %s'):format(veh.plate, status)

            context.options[#context.options+1] = {
                title = label,
                icon = icon,
                description = desc,
                metadata = generateMetadata(veh),
                onSelect = function ()
                    self:createVehicleMenu(veh)
                end
            }
        end)
    end

    if #context.options < 1 then
        context.options[#context.options+1] = {
            title = 'No Vehicles',
            disabled = true
        }
    end

    utils.context.openMenu(context)
end

return GARAGE