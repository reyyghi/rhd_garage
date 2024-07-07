local spawnPoint = {}

local vehicleList = {
    'kuruma',
    'guardian',
    'jetmax',
    'swift2'
}

local vehCreated = {}

local curVehicle = nil
local busy = false
local glm = require "glm"
local glm_polygon_contains = glm.polygon.contains
local debugzone = require 'modules.debugzone'

local function CancelPlacement()
    busy = false
    DeleteVehicle(curVehicle)

    for i=1, #vehCreated do
        local entity = vehCreated[i]
        DeleteEntity(entity)
    end

    curVehicle = nil
end

---@param table vector3[]
local function tovec3(table)
    local results = {}
    for i=1, #table do
        local c = table[i]
        results[#results+1] = vec3(c.x, c.y, c.z)
    end
    return results
end

---@param coords vector3
local function closestVP(coords)
    local results = false
    for i=1, #vehCreated do
        local entity = vehCreated[i]
        local vc = GetEntityCoords(entity)
        local dist = #(coords - vc)
        if dist < 3 then
            results = true
            break
        end
    end
    return results
end

---@param model string|integer
---@param coords vector4
local function createPV(model, coords)
    local vm = model
    lib.requestModel(vm)
    local pv = CreateVehicle(vm, coords.x, coords.y, coords.z, coords.w, false, false)
    SetVehicleDoorsLocked(pv, 2)
    SetEntityAlpha(pv, 150, true)
    SetEntityCollision(pv, false, false)
    FreezeEntityPosition(pv, true)
    return pv
end

--- Create Spawn Points
---@param zone OxZone
---@param required boolean
---@return promise?
function spawnPoint.create(zone, required, existingPoint)
    if not zone then return end
    if busy then return end
    local vehIndex = 1
    local vehicle = vehicleList[vehIndex]
    local points = tovec3(zone.points)

    local polygon = glm.polygon.new(points)

    local text = [[
    [X]: Close
    [Enter]: Confirm
    [Spacebar]: Add Points
    [Arrow Up/Down]: Height
    [Arrow Right/Left]: Rotate Vehicle
    [Mouse Scroll Up/Down]: Change Vehicle
    ]]

    utils.drawtext('show', text)
    lib.requestModel(vehicle, 1500)
    curVehicle = CreateVehicle(vehicle, 1.0, 1.0, 1.0, 0, false, false)
    SetEntityAlpha(curVehicle, 150, true)
    SetEntityCollision(curVehicle, false, false)
    FreezeEntityPosition(curVehicle, true)

    if existingPoint and #existingPoint>0 then
        for i=1, #existingPoint do
            local vc = existingPoint[i]
            local pv = createPV(vehicle, vc)
            vehCreated[#vehCreated+1] = pv
        end
    end

    local vc = {}
    local heading = 0.0
    local prefixZ = 0.0
    
    local results = promise.new()
    CreateThread(function()
        busy = true

        while busy do
            local hit, coords, inwater, wcoords = utils.raycastCam(20.0)

            CurrentCoords = GetEntityCoords(curVehicle)
            
            local inZone = glm_polygon_contains(polygon, CurrentCoords, zone.thickness / 4)
            local debugColor = inZone and {r = 10, g = 244, b = 115, a = 50} or {r = 240, g = 5, b = 5, a = 50}
            debugzone.start(polygon, zone.thickness, debugColor)

            if hit == 1 and not inwater then
                SetEntityCoords(curVehicle, coords.x, coords.y, coords.z + prefixZ, false, false, false, false)
            elseif inwater then
                SetEntityCoords(curVehicle, wcoords.x, wcoords.y, wcoords.z + prefixZ, false, false, false, false)
            end

            DisableControlAction(0, 174, true)
            DisableControlAction(0, 175, true)
            DisableControlAction(0, 73, true)
            DisableControlAction(0, 176, true)
            DisableControlAction(0, 14, true)
            DisableControlAction(0, 15, true)
            DisableControlAction(0, 172, true)
            DisableControlAction(0, 173, true)
            DisableControlAction(0, 21, true)
            DisableControlAction(0, 22, true)
            
            if IsDisabledControlPressed(0, 174) then
                heading = heading + 0.5
                if heading > 360 then heading = 0.0 end
            end
    
            if IsDisabledControlPressed(0, 175) then
                heading = heading - 0.5
                if heading < 0 then heading = 360.0 end
            end

            if IsDisabledControlJustPressed(0, 172) then
                prefixZ += 0.1
            end
    
            if IsDisabledControlJustPressed(0, 173) then
                prefixZ -= 0.1
            end

            if IsDisabledControlJustPressed(0, 14) then
                local newIndex = vehIndex+1
                local newModel = vehicleList[newIndex]
                if newModel then
                    DeleteEntity(curVehicle)
                    local veh = createPV(newModel, vec(1.0, 1.0, 1.0, 0))
                    curVehicle = veh
                    vehIndex = newIndex
                    object = newModel
                end
            end

            if IsDisabledControlJustPressed(0, 15) then
                local newIndex = vehIndex-1

                if newIndex >= 1 then
                    local newModel = vehicleList[newIndex]
                    if newModel then
                        DeleteEntity(curVehicle)
                        local veh = createPV(newModel, vec(1.0, 1.0, 1.0, 0))
                        curVehicle = veh
                        vehIndex = newIndex
                        object = newModel
                    end
                end
            end
            
            if IsDisabledControlJustPressed(0, 73) then
                vc = {}
                CancelPlacement()
                results:resolve(false)
                utils.notify('Spawn point creation cancelled!', 'error', 8000)
            end

            SetEntityHeading(curVehicle, heading)

            if IsDisabledControlJustPressed(0, 176) then
                if required and #vc < 1 then
                    utils.notify("You must create at least x1 spawn points", "error", 8000)
                else
                    results:resolve(#vc > 0 and vc or false)
                    CancelPlacement()
                end
            end

            if IsDisabledControlJustPressed(0, 22) then
                if hit == 1 then
                    local closestVeh = closestVP(CurrentCoords.xyz)

                    if closestVeh then
                        utils.notify("Look for another place", "error", 8000)
                        goto next
                    end

                    if inZone then
                        local rc = vec4(CurrentCoords.x, CurrentCoords.y, CurrentCoords.z, heading)
                        local vm = vehicleList[vehIndex]
                        local pv = createPV(vm, rc)
                        
                        vc[#vc+1] = rc
                        vehCreated[#vehCreated+1] = pv
                        utils.notify("location successfully created " .. #vc, "success", 8000)
                    else
                        utils.notify("cannot add spawn points outside the zone", "error", 8000)
                    end

                    ::next::
                end
            end
            Wait(1)
        end
        utils.drawtext('hide')
    end)

    return Citizen.Await(results)
end

AddEventHandler('onResourceStop', function(resource)
   if resource == GetCurrentResourceName() then
    lib.hideTextUI()
    DeleteVehicle(curVehicle)
    for i=1, #vehCreated do
        local entity = vehCreated[i]
        DeleteEntity(entity)
    end
   end
end)

return spawnPoint