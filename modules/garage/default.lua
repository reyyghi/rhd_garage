---@class GARAGE : OxClass
local GARAGE = lib.class('GARAGE')

---@class garageZoneBlip
---@field label string     -- The label or name that will appear on the map for this blip.
---@field sprite number    -- The icon or sprite ID used for the blip (e.g., car icon, house icon).
---@field colour number    -- The color ID for the blip, as defined in the game (e.g., blue, red).
---@field coords vector3   -- The 3D coordinates where the blip will be placed on the map (x, y, z).

---@class garageZonePoints
---@field points vector3[]
---@field thickness number

---@class garagePoints
---@field coords vector3
---@field distance number
---@field useMarker boolean

---@class garageTargetPed
---@field model string
---@field coords vector4

---@class cbData
---@field playerId number
---@field playerName string
---@field playerJob string
---@field playerGang string
---@field playerIdentifier string

---@class garageZone
---@field type string
---@field class string|string[]
---@field label string
---@field zones? garageZonePoints
---@field points? table<string, garagePoints>
---@field interaction? string|garageTargetPed
---@field spawnPoint? vector4[]
---@field blip? garageZoneBlip
---@field groups? string|string[]|table<string, number>
---@field canAccess? fun(data?:cbData): boolean

--- @class InputData
--- @field engine number
--- @field body number
--- @field fuel number

--- @class MetadataEntry
--- @field label string
--- @field value number
--- @field progress number
--- @field colorScheme string

local markerColour = {
    {255, 255, 255, 255},  -- White color with full opacity (RGBA: Red, Green, Blue, Alpha)
    {200, 20, 20, 255}     -- Red color with slight variation and full opacity (RGBA: Red, Green, Blue, Alpha)
}

local CLASS_CATEGORY = {
    car = {0, 1, 2, 3, 4, 5, 6, 7},        -- Vehicle class included in the group 'car'
    motorcycle = {8},                      -- Vehicle class included in the group 'motorcycle'
    bicycle = {13},                        -- Vehicle class included in the group 'bicycle'
    truck = {9, 10, 11, 12, 20},           -- Vehicle class included in the group 'truck'
    plane = {16},                          -- Vehicle class included in the group 'plane'
    helicopter = {15},                     -- Vehicle class included in the group 'helicopter'
    boat = {14},                           -- Vehicle class included in the group 'boat'
    train = {21}                           -- Vehicle class included in the group 'train'
}

local VEH_CLASS = {}
for category, class in pairs(CLASS_CATEGORY) do
    for _, id in pairs(class) do
        VEH_CLASS[id] = category
    end
end

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

--- Creates a blip on the map with the specified properties.
--- This function places a blip at the given coordinates, sets its appearance (sprite, scale, color), 
--- and adds a label to it. The blip will be visible on the minimap and its name is set accordingly.
---@param blip garageZoneBlip  -- The data for the blip, including its label, sprite, color, and coordinates.
---@return number  -- The handle of the created blip.
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

---@param category string|string[]  -- The category or categories to check the vehicle against. Can be a single string or an array of strings.
---@param vehicle number|string     -- The vehicle entity or model name to check the class of.
---@return boolean                  -- Returns true if the vehicle's class matches the category, false otherwise.
local function allowedClass(category, vehicle)
    local class

    if DoesEntityExist(vehicle) then
        class = GetVehicleClass(vehicle)
    else
        class = GetVehicleClassFromName(vehicle)
    end

    local vehcategory = VEH_CLASS[class]
    local isArray = lib.array.isArray(category)

    if not isArray then
        return category == vehcategory
    end

    return lib.array.find(category, function (garageClass)
        if garageClass == vehcategory then
            return true
        end
    end)
end

---@param spawnpoint vector4[]  -- An array of vector4 coordinates to check for a free location.
---@return vector4?        -- Returns a vector4 if a free location is found, otherwise returns nil.
local function getFreeLocation(spawnpoint)
    local result
    lib.array.forEach(spawnpoint, function (c)
        local sp = vec(c.x, c.y, c.z, c.w)
        local vehEntity = lib.getClosestVehicle(sp.xyz, 3.0, true)
        if not vehEntity then result = sp return end
    end)
    return result
end

--- Displays a menu for searching a vehicle by plate number. 
--- It prompts the user to enter a vehicle plate number, retrieves the vehicle's location from the server, 
--- sets a waypoint to that location on the map, and notifies the user that the location has been marked.
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

--- Prompts the user to enter a new name for their vehicle and then confirms the change with a dialog.
--- If confirmed, it sends a request to the server to update the vehicle's name and charges the user a fee.
--- Displays a notification upon successful name change.
---@param plate string  -- The plate number of the vehicle whose name is to be changed.
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

--- Generates a list of metadata entries based on the provided data.
--- This function creates metadata entries for engine, body, and fuel if the corresponding data fields are present.
--- Each entry includes a label, value, progress, and color scheme.
--- 
--- @param data InputData  -- The input data containing engine, body, and fuel information.
--- @return MetadataEntry[]  -- An array of metadata entries with information about engine, body, and fuel.
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

--- Constructs a `GARAGE` instance using the provided zone data.
--- Initializes various properties of the garage including label, blip, access control, class, type, groups, spawn points, and interaction settings.
--- Sets up zones or points for the garage based on the provided data and configures the corresponding interactions.
---
--- @param zoneData garageZone  -- The data used to configure the garage, including label, zones, points, blip, access control, class, type, groups, and spawn points
function GARAGE:constructor(zoneData)
    self.label = zoneData.label

    local zone = zoneData.zones
    local points = zoneData.points

    self.blip = zoneData.blip and createBlip({
        label = zoneData.label,
        sprite = zoneData.blip.sprite,
        colour = zoneData.blip.colour,
        coords = zone and zone.points[1] or points and points.take or nil
    })

    self.canAccess = zoneData.canAccess and function ()
        return lib.callback.await('rhd_garage:server:checkAccess', 1500, self.label)
    end or function ()
        return true
    end

    self.class = zoneData.class
    self.type = zoneData.type
    self.groups = zoneData.groups
    self.spawnPoint = zoneData.spawnPoint

    if zone then
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
    elseif points then
        self.points = {
            take = lib.points.new({
                coords = points.take,
                distance = 2.5,
                onEnter = function ()
                    if points.useMarker then
                        self.useMarker = true
                    end

                    self.pointsType = 'take'
                    self.spawnPoint = {points.take}
                end,
                nearby = function (pointsData)
                    self:insideTakePoints(pointsData)
                end,
            }),
            save = lib.points.new({
                coords = points.save,
                distance = 2.5,
                onEnter = function ()
                    if points.useMarker then
                        self.useMarker = true
                    end
                    self.pointsType = 'save'
                end,
                nearby = function (pointsData)
                    self:insideSavePoints(pointsData)
                end,
            }),
        }
        if points.useMarker then
            self.useMarker = true
            self.merkerPos = {
                take = points.take,
                save = points.save
            }
        end
        
    end

    self.interaction = zoneData.interaction

    return self
end

function GARAGE:remove()
    self:removeBlip()

    if self.zones then
        self.zones:remove()
    end

    if self.points then
        for _, points in pairs(self.points) do
            points:remove()
        end
    end
end

--- @param blip garageZoneBlip
function GARAGE:addBlip(blip)
    self.blip = createBlip(blip)
end

function GARAGE:removeBlip()
    if DoesBlipExist(self.blip) then
        RemoveBlip(self.blip)
    end
end

--- @param pointsData table
function GARAGE:insideTakePoints(pointsData)
    if self.useMarker then
        DrawMarker(20,
            pointsData.coords.x,
            pointsData.coords.y,
            pointsData.coords.z,
            0.0, 0.0, 0.0,
            0.0, 0.0, 0.0,
            0.4 --[[scale x]], 0.4 --[[scale y]], 0.4 --[[scale z]],
            markerColour[1][1], markerColour[1][2], markerColour[1][3], markerColour[1][4],
            false, true, 2, false, nil, nil, false
        )
    end

    if pointsData.currentDistance < 1 then
        local isOpen, text = lib.isTextUIOpen()
        local textt = cache.vehicle and self.label or 'E - Access ' .. self.label
        if not isOpen or text ~= textt then
            lib.showTextUI(textt, {
                icon = 'warehouse',
                style = {
                    borderRadius = 2,
                }
            })
        end
        if IsControlJustPressed(0, 38) and self.canAccess() then
            self:getVehicles()
        end
    else
        if lib.isTextUIOpen() then
            lib.hideTextUI()
        end
    end
end

--- @param pointsData table
function GARAGE:insideSavePoints(pointsData)
    if self.useMarker then
        DrawMarker(20,
            pointsData.coords.x,
            pointsData.coords.y,
            pointsData.coords.z,
            0.0, 0.0, 0.0,
            0.0, 0.0, 0.0,
            0.4 --[[scale x]], 0.4 --[[scale y]], 0.4 --[[scale z]],
            markerColour[2][1], markerColour[2][2], markerColour[2][3], markerColour[2][4],
            false, true, 2, false, nil, nil, false
        )
    end

    if pointsData.currentDistance < 1 then
        local isOpen, text = lib.isTextUIOpen()
        local textt = cache.vehicle and 'E - Store Vehicle' or self.label
        if not isOpen or text ~= textt then
            lib.showTextUI(textt, {
                icon = 'warehouse',
                style = {
                    borderRadius = 2,
                }
            })
        end
        if IsControlJustPressed(0, 38) and self.canAccess() then
            self:saveVehicle()
        end
    else
        if lib.isTextUIOpen() then
            lib.hideTextUI()
        end
    end
end

function GARAGE:insideZone()
    if type(self.interaction) == 'table' or self.interaction == 'keypressed' then
        if IsControlJustPressed(0, 38) and self.canAccess() then
            if self.groups and not PLAYER:checkGroups(self.groups) then
                return
            end
            if cache.vehicle and self.type ~= 'impound' then
                self:saveVehicle()
                return
            end
            self:getVehicles()
        end
    end
end


function GARAGE:enterZone()
    local textUI = self.label
    
    if not self.canAccess() then return end
    if self.groups and not PLAYER:checkGroups(self.groups) then return end

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
        local impound = self.type == 'impound'
        local prefix = impound and 'Access ' or 'Store/Access '

        textUI = 'E - ' .. prefix .. self.label
    elseif self.interaction == 'radialmenu' then
        local interactOptions = {
            {
                id = ('access_%s'):format(self.label:gsub("%s+", "")),
                label = ('Access %s'):format(self.label),
                icon = 'warehouse',
                onSelect = function ()
                    self:getVehicles()
                end
            }
        }

        if not self.type == 'impound' then
            interactOptions[2] = {
                id = ('store_%s'):format(self.label:gsub("%s+", "")),
                label = 'Save Vehicle',
                icon = 'parking',
                onSelect = function ()
                    self:saveVehicle()
                end
            }
        end
        self.interactionData = radialmenu:new(interactOptions)
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
    local vehicle = cache.vehicle
    
    if not vehicle then
        return
    end

    if not allowedClass(self.class, vehicle) then
        return utils.notify('Vehicles of this class cannot be stored here.', 'error')
    end

    local deformation = Config.saveDeformation and exports.VehicleDeformation:GetVehicleDeformation(vehicle)

    TaskLeaveVehicle(cache.ped, vehicle, 0)
    Wait(1500)

    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    local props = lib.getVehicleProperties(vehicle)
    local success = lib.callback.await('rhd_garage:server:SaveVehicle', false, {
        garage = self.label,
        props = props,
        netId = netId,
        deformation = deformation
    })

    if success then
        utils.notify('The vehicle has been stored in the garage', 'success', 8000)
    end
end

function GARAGE:takeoutVehicle(veh)
    local spawnLoc = getFreeLocation(self.spawnPoint)

    if not spawnLoc then
        return utils.notify('There is no available space to retrieve the vehicle from the garage.', 'error')
    end

    lib.requestModel(veh.model, 1500)
    local vehicleType = utils.vehicle.getType(veh.model)

    local netId, fuel, deformation = lib.callback.await('rhd_garage:server:SpawnVehicle', false, {
        plate = veh.plate,
        model = veh.model,
        warp = Config.SpawnInVehicle,
        coords = spawnLoc,
        props = veh.mods,
        impound = veh.impound,
        class = vehicleType
    })

    if not netId or netId < 1 then
        return
    end

    local vehicle = NetToVeh(netId)
    
    if DoesEntityExist(vehicle) then
        if DoesEntityExist(vehicle) and Config.saveDeformation and deformation then
            exports.VehicleDeformation:SetVehicleDeformation(vehicle, deformation)
        end
        utils.vehicle.setFuel(vehicle, fuel)
    end
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
        desc = ('Owner: %s \nPlate: %s | Status: %s'):format(veh.owner.name, veh.plate, status)
    elseif impound then
        local class = GetVehicleClassFromName(veh.model)
        desc = ('Fee: $%s \nPlate: %s | Status: %s'):format(
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
    
    if cache.vehicle then
        return
    end
    
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

        if allowedClass(self.class, veh.model) then
            context.options[#context.options+1] = {
                title = label,
                icon = icon,
                description = desc,
                metadata = generateMetadata(veh),
                onSelect = function ()
                    self:createVehicleMenu(veh)
                end
            }
        end
    end)

    utils.context.openMenu(context)
end

return GARAGE