---@class GARAGE : OxClass
local GARAGE = lib.class('GARAGE')

local config = require 'config.client'

local markerColour = {
    {255, 255, 255, 255},
    {200, 20, 20, 255}
}

local interact = require 'modules.utils.interact'
local radialmenu = require 'modules.utils.radialmenu'

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
    local isArray = Array.isArray(category)

    if not isArray then
        return category == vehcategory
    end

    return Array.find(category, function (garageClass)
        if garageClass == 'all' or garageClass == vehcategory then
            return true
        end
    end)
end

---@param spawnpoint vector4[]  -- An array of vector4 coordinates to check for a free location.
---@return vector4?        -- Returns a vector4 if a free location is found, otherwise returns nil.
local function getFreeLocation(spawnpoint)
    local result = Array.find(spawnpoint, function (c)
        local sp = vec(c.x, c.y, c.z, c.w)
        local vehEntity = lib.getClosestVehicle(sp.xyz, 3.0, true)
        if not vehEntity then
            return sp
        end
    end)
    return result
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
        label = zoneData.blip.label or zoneData.label,
        sprite = zoneData.blip.sprite,
        colour = zoneData.blip.colour,
        coords = zone and zone.points[1] or points and points.take or nil
    })

    self.hasAccess = true
    self.class = zoneData.class
    self.type = zoneData.type
    self.groups = zoneData.groups
    self.spawnPoint = zoneData.spawnPoint

    if zone then
        self.zones = lib.zones.poly({
            points = zoneData.zones.points,
            thickness = zoneData.zones.thickness,
            onEnter = function ()
                if zoneData.canAccess then
                    self.hasAccess = lib.callback.await('rhd_garage:server:checkAccess', 1500, self.label)
                end

                if self.groups then
                    self.hasAccess = PLAYER:checkGroups(self.groups)
                end

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
                    self.spawnPoint = {points.save}
                    
                    if zoneData.canAccess then
                        self.hasAccess = lib.callback.await('rhd_garage:server:checkAccess', 1500, self.label)
                    end
    
                    if self.groups then
                        self.hasAccess = PLAYER:checkGroups(self.groups)
                    end
                end,
                nearby = function (pointsData)
                    self:insideTakePoints(pointsData)
                end,
                onExit = function ()
                    lib.hideTextUI()
                end
            }),
        }

        if self.type ~= 'depot' then
            self.points.save = lib.points.new({
                coords = points.save,
                distance = 2.5,
                onEnter = function ()
                    if points.useMarker then
                        self.useMarker = true
                    end
                    
                    self.pointsType = 'save'
                    if zoneData.canAccess then
                        self.hasAccess = lib.callback.await('rhd_garage:server:checkAccess', 1500, self.label)
                    end
    
                    if self.groups then
                        self.hasAccess = PLAYER:checkGroups(self.groups)
                    end
                end,
                nearby = function (pointsData)
                    self:insideSavePoints(pointsData)
                end,
                onExit = function ()
                    lib.hideTextUI()
                end
            })
        end

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

    if not self.hasAccess then
        return
    end

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
        if IsControlJustPressed(0, 38) then
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

    if not self.hasAccess then
        return
    end

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
        if IsControlJustPressed(0, 38) then
            self:saveVehicle()
        end
    else
        if lib.isTextUIOpen() then
            lib.hideTextUI()
        end
    end
end

function GARAGE:insideZone()

    if not self.hasAccess then
        return
    end

    if type(self.interaction) == 'table' or self.interaction == 'keypressed' then
        if IsControlJustPressed(0, 38) then
            if cache.vehicle and self.type ~= 'depot' then
                self:saveVehicle()
                return
            end
            self:getVehicles()
        end
    end
end


function GARAGE:enterZone()
    local textUI = self.label
    
    if not self.hasAccess then
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
        local depot = self.type == 'depot'
        local prefix = depot and 'Access ' or 'Store/Access '

        textUI = 'E - ' .. prefix .. self.label
    elseif self.interaction == 'radialmenu' then
        local interactOptions = {
            {
                id = ('garage_access_%s'):format(self.label:gsub("%s+", "")),
                label = ('Access %s'):format(self.label),
                icon = 'warehouse',
                onSelect = function ()
                    self:getVehicles()
                end
            }
        }

        if self.type ~= 'depot' then
            interactOptions[2] = {
                id = ('garage_save_%s'):format(self.label:gsub("%s+", "")),
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

    if not self.hasAccess then
        return
    end

    if self.interactionData then
        self.interactionData:remove()
        self.interactionData = nil
    end
    lib.hideTextUI()
end

function GARAGE:saveVehicle()
    local vehicle = cache.vehicle
    
    if not vehicle then
        vehicle = lib.getClosestVehicle(cache.coords.xyz)
        
        if not vehicle then
            return
        end
    end

    if not allowedClass(self.class, vehicle) then
        return utils.notify('Vehicles of this class cannot be stored here.', 'error')
    end

    local deformation = config.saveDeformation and exports.VehicleDeformation:GetVehicleDeformation(vehicle)

    TaskLeaveVehicle(cache.ped, vehicle, 0)
    Wait(1500)

    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    local props = lib.getVehicleProperties(vehicle)
    local label = Entity(vehicle).state.label or utils.vehicle.getVehicleLabel(props.model)
    local success = lib.callback.await('rhd_garage:server:SaveVehicle', false, {
        garage = self.label,
        props = props,
        netId = netId,
        deformation = deformation,
        label = label
    })

    if success then
        utils.notify('The vehicle has been stored in the garage', 'success', 8000)
    end
end

function GARAGE:takeoutVehicle(veh, payment)
    local spawnLoc = getFreeLocation(self.spawnPoint)

    if not spawnLoc then
        return utils.notify('There is no available space to retrieve the vehicle from the garage.', 'error')
    end

    lib.requestModel(veh.model, 1500)
    local vehicleType = utils.vehicle.getType(veh.model)

    local netId, fuel, deformation = lib.callback.await('rhd_garage:server:SpawnVehicle', false, {
        plate = veh.plate,
        model = veh.model,
        warp = config.spawnInVehicle,
        coords = spawnLoc,
        depot = payment,
        class = vehicleType
    })

    if not netId or netId < 1 then
        return
    end

    local vehicle = NetToVeh(netId)
    
    if DoesEntityExist(vehicle) then
        if DoesEntityExist(vehicle) and config.saveDeformation and deformation then
            exports.VehicleDeformation:SetVehicleDeformation(vehicle, deformation)
        end
        utils.vehicle.setFuel(vehicle, fuel)
    end
end


function GARAGE:getVehicles()
    
    if cache.vehicle then
        return
    end
    
    local vehicles = lib.callback.await('rhd_garage:server:getVehicles', false, {
        garage = self.label,
        depot = self.type == 'depot',
        shared = self.type == 'shared'
    })

    if not vehicles then
        lib.print.info('No Vehicles')
        return
    end

    local tablePos = 1
    local vehicleList = {}

    Array.forEach(vehicles, function (veh)
        local icon = utils.getVehicleIcon(veh.model)
        local originalName = utils.vehicle.getVehicleLabel(veh.model)
        local label = veh.label or originalName
        local class = GetVehicleClassFromName(veh.model)

        local outside
        local metadata = {}
        local depotPrice = DepotPriceByClass[class]

        if self.type == 'depot' then
            outside = utils.vehicle.isOutside(veh.plate)
            metadata = {
                ['Depot Price'] = '$'..lib.math.groupdigits(depotPrice, ','),
                Plate = veh.plate,
                Status = outside and 'Out Garage' or 'In Depot'
            }
        else
            metadata = {
                Plate = veh.plate,
                Status = 'In Garage'
            }
            if self.type == 'shared' then
                metadata['Owner'] = veh.owner.name
            end
        end

        if allowedClass(self.class, veh.model) then
            vehicleList[tablePos] = {
                id = tablePos,
                name = label,
                plate = veh.plate,
                icon = icon,
                engine = veh.engine,
                fuel = veh.fuel,
                body = veh.body,
                depotPrice = depotPrice,
                metadata = metadata,
                outside = outside,
                logs = veh.logs
            }

            UI.Action[veh.plate] = {
                takeOutVeh = function (payment)
                    self:takeoutVehicle(veh, payment)
                end,
                changeName = function (newName)
                    local success = lib.callback.await('rhd_garage:server:changeVehicleName', 1500, {
                        name = newName,
                        plate = veh.plate,
                    })
                    
                    if success then
                        utils.notify(('Vehicle name successfully changed to %s'):format(newName), 'success')
                    end
                end,
                swapGarage = function (newGarage)
                    if newGarage == '' then
                        lib.print.info('No Garage Selected')
                        return
                    end

                    local success = lib.callback.await('rhd_garage:server:changeGarage', 1500, {
                        garage = newGarage,
                        plate = veh.plate,
                    })
                    
                    if success then
                        utils.notify(('Your vehicle has been moved to %s'):format(newGarage), 'success')
                    end
                end
            }
            
            tablePos += 1
        end
    end)

    UI.sendMessage({
        label = self.label,
        type = self.type,
        vehicles = vehicleList
    })
end

return GARAGE