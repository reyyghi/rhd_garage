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
---@field spawnpoint vector4[]
---@field blip? garageZoneBlip
---@field groups? string|string[]|table<string, number>

--- @class InputData
--- @field engine number
--- @field body number
--- @field fuel number

--- @class MetadataEntry
--- @field label string
--- @field value number
--- @field progress number
--- @field colorScheme string

local impoundFee = {
    [0] = 15000,  --- Price for compact cars
    [1] = 15000,  --- Price for sedans
    [2] = 15000,  --- Price for SUVs
    [3] = 15000,  --- Price for coupes
    [4] = 15000,  --- Price for muscle cars
    [5] = 15000,  --- Price for sports classics
    [6] = 15000,  --- Price for sports cars
    [7] = 15000,  --- Price for super cars
    [8] = 15000,  --- Price for motorcycles
    [9] = 15000,  --- Price for off-road vehicles
    [10] = 15000, --- Price for industrial vehicles
    [11] = 15000, --- Price for utility vehicles
    [12] = 15000, --- Price for vans
    [13] = 15000, --- Price for cycles
    [14] = 15000, --- Price for boats
    [15] = 15000, --- Price for helicopters
    [16] = 15000, --- Price for planes
    [17] = 15000, --- Price for service vehicles
    [18] = 0,     --- Price for emergency vehicles
    [19] = 15000, --- Price for military vehicles
    [20] = 15000, --- Price for commercial vehicles
    [21] = 0      --- Price for trains (not applicable)
}

local interact = require 'modules.garage.interact'
local radialmenu = require 'modules.garage.radialmenu'

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

local function getFreeLocation(spawnpoint)
    local result
    lib.array.forEach(spawnpoint, function (c)
        local sp = vec(c.x, c.y, c.z, c.w)
        local vehEntity = lib.getClosestVehicle(sp.xyz, 3.0, true)
        if not vehEntity then result = sp return end
    end)
    return result
end

local function searchVehicleMenu()

    local input = lib.inputDialog(('%s\'s Vehicles'):format(PLAYER.name), {
        { type = 'input', label = 'Enter vehicle plate number', required = true },
    })

    local plate = input and input[1]
    if not plate then return end

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
    if not vehicleName then return end

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
        
        if success then
            utils.notify(('Vehicle name successfully changed to %s'):format(vehicleName), 'success')
        end
    end
end

--- @param data InputData
--- @return MetadataEntry[]
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
    self.spawnPoint = zoneData.spawnPoint

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
    if self.interaction == 'keypressed' then
        if IsControlJustPressed(0, 38) then
            if self.groups and not PLAYER:checkGroups(self.groups) then
                return
            end
            if cache.vehicle then
                self:saveVehicle()
                return
            end
            self:getVehicles()
        end
    end
end

function GARAGE:enterZone()
    local textUI = self.label

    if self.groups and not PLAYER:checkGroups(self.groups) then
        return
    end

    if type(self.interaction) == 'table' then
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
    elseif self.interaction == 'keypressed' then
        textUI = 'E - Store/Access ' .. self.label
    elseif self.interaction == 'radialmenu' then
        self.interactionData = radialmenu:new({
            {
                id = ('access_%s'):format(self.label:gsub("%s+", "")),
                label = ('Access %s'):format(self.label),
                icon = 'warehouse',
                onSelect = function ()
                    self:getVehicles()
                end
            },
            {
                id = ('store_%s'):format(self.label:gsub("%s+", "")),
                label = 'Save Vehicle',
                icon = 'parking',
                onSelect = function ()
                    print('storred')
                end
            }
        })
    end

    lib.showTextUI(textUI, {
        icon = 'warehouse',
        style = {
            borderRadius = 2,
        }
    })
end

function GARAGE:exitZone()
    if self.interactionData then
        self.interactionData:remove()
        self.interactionData = nil
    end

    lib.hideTextUI()
end

function GARAGE:saveVehicle()
    local netId = NetworkGetNetworkIdFromEntity(cache.vehicle)
    local props = lib.getVehicleProperties(cache.vehicle)
    lib.callback.await('rhd_garage:server:SaveVehicle', false, {
        garage = self.label,
        props = props,
        netId = netId,
        deformation = {}
    })
end

function GARAGE:takeoutVehicle(veh)
    local spawnLoc = getFreeLocation(self.spawnPoint)
    
    if not spawnLoc then
        return utils.notify('There is no available space to retrieve the vehicle from the garage.', 'error')
    end

    lib.requestModel(veh.model, 1500)
    local netId = lib.callback.await('rhd_garage:server:SpawnVehicle', false, {
        plate = veh.plate,
        model = veh.model,
        warp = Config.SpawnInVehicle,
        coords = spawnLoc,
        props = veh.mods,
        impound = veh.impound
    })

    if not netId or netId < 1 then
        return
    end

    local vehicle = NetToVeh(netId)
end

function GARAGE:createVehicleMenu(veh)
    local icon = utils.context.getVehicleIcon(veh.model)
    local originalName = utils.vehicle.getVehicleLabel(veh.model)
    local label = veh.label or originalName
    local status = veh.engine < 80 and 'Need repair' or 'Good'
    local desc = ('Plate: %s | Status: %s'):format(veh.plate, status)

    local shared = self.type == 'shared'
    local impound = self.type == 'impound'
    
    if shared then
        desc = ('Owner: %s  \nPlate: %s | Status: %s'):format(veh.owner.name, veh.plate, status)
    elseif impound then
        local class = GetVehicleClassFromName(veh.model)
        desc = ('Fee: $%s   \nPlate: %s | Status: %s'):format(
        lib.math.groupdigits(impoundFee[class]), veh.plate, status)
        veh.impound = impoundFee[class]
    end

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

    if not shared and not impound then
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

    context.options[#context.options+1] = {
        title = 'Take Out Vehicle',
        icon = 'car-rear',
        description = 'Retrieve a vehicle from the garage.',
        onSelect = function ()
            self:takeoutVehicle(veh)
        end
    }

    utils.context.openMenu(context)
end

function GARAGE:getVehicles()
    if cache.vehicle then return end
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

    if not vehicles then
        context.options[#context.options+1] = {
            title = 'No Vehicles',
            disabled = true
        }
        return utils.context.openMenu(context)
    end

    lib.array.forEach(vehicles, function (veh)
        local icon = utils.context.getVehicleIcon(veh.model)
        local originalName = utils.vehicle.getVehicleLabel(veh.model)
        local label = veh.label or originalName
        local status = veh.engine < 80 and 'Need repair' or 'Good'
        
        local desc = ('Plate: %s | Status: %s'):format(
            veh.plate, status
        )

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

    utils.context.openMenu(context)
end

return GARAGE