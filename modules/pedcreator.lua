local pedcreator = {}

local pedlist = lib.load('data.pedlist')

local curPed = nil
local busycreate = false
local glm = require "glm"

local function CancelPlacement()
    DeletePed(curPed)
    busycreate = false
    curPed = nil
end

local RotationToDirection = function(rot)
    local rotZ = math.rad(rot.z)
    local rotX = math.rad(rot.x)
    local cosOfRotX = math.abs(math.cos(rotX))
    return vector3(-math.sin(rotZ) * cosOfRotX, math.cos(rotZ) * cosOfRotX, math.sin(rotX))
end

local function RayCastGamePlayCamera(distance)
    local camRot = GetGameplayCamRot()
    local camPos = GetGameplayCamCoord()
    local dir = RotationToDirection(camRot)
    local dest = camPos + (dir * distance)
    local ray = StartShapeTestRay(camPos, dest, 17, -1, 0)
    local _, hit, endPos, surfaceNormal, entityHit = GetShapeTestResult(ray)
    if hit == 0 then endPos = dest end
    return hit, endPos, entityHit, surfaceNormal
end

function pedcreator.start(zone)
    if not zone then return end
    if busycreate then return end
    local pedIndex = 1
    local pedmodels = pedlist[pedIndex]
    local polygon = glm.polygon.new(zone.points)

    local text = [[
    [X]: Cancel
    [Enter]: Confirm
    [Arrow Right/Left]: Rotate Ped
    [Mouse Scroll Up/Down]: Change Ped
    ]]

    lib.showTextUI(text)
    lib.requestModel(pedmodels, 1500)
    curPed = CreatePed(0, pedmodels, 1.0, 1.0, 1.0, 0.0, false, false)
    SetEntityAlpha(curPed, 150, false)
    SetEntityCollision(curPed, false, false)
    FreezeEntityPosition(curPed, true)

    local notif = false
    local pc = nil
    local heading = 0.0

    local results = promise.new()
    CreateThread(function()
        busycreate = true

        while busycreate do
            local hit, coords, entity = RayCastGamePlayCamera(20.0)
            CurrentCoords = GetEntityCoords(curPed)
            
            local inZone = glm.polygon.contains(polygon, CurrentCoords, zone.thickness / 4)
            
            if hit == 1 then
                SetEntityCoords(curPed, coords.x, coords.y, coords.z)
            end

            DisableControlAction(0, 174, true)
            DisableControlAction(0, 175, true)
            DisableControlAction(0, 73, true)
            DisableControlAction(0, 176, true)
            DisableControlAction(0, 14, true)
            DisableControlAction(0, 15, true)
            DisableControlAction(0, 172, true)
            DisableControlAction(0, 173, true)
            
            if IsDisabledControlPressed(0, 174) then
                heading = heading + 0.5
                if heading > 360 then heading = 0.0 end
            end
    
            if IsDisabledControlPressed(0, 175) then
                heading = heading - 0.5
                if heading < 0 then heading = 360.0 end
            end

            if IsDisabledControlJustPressed(0, 14) then
                local newIndex = pedIndex+1
                local newModel = pedlist[newIndex]
                if newModel then
                    DeleteEntity(curPed)
                    lib.requestModel(newModel)
                    local newped = CreatePed(0, newModel, 1.0, 1.0, 1.0, 0.0, false, false)
                    SetEntityAlpha(newped, 150, false)
                    SetEntityCollision(newped, false, false)
                    FreezeEntityPosition(newped, true)
                    curPed = newped
                    pedIndex = newIndex
                end
            end

            if IsDisabledControlJustPressed(0, 15) then
                local newIndex = pedIndex-1

                if newIndex >= 1 then
                    local newModel = pedlist[newIndex]
                    if newModel then
                        DeleteEntity(curPed)
                        lib.requestModel(newModel)
                        local newped = CreatePed(0, newModel, 1.0, 1.0, 1.0, 0.0, false, false)
                        SetEntityAlpha(newped, 150, false)
                        SetEntityCollision(newped, false, false)
                        FreezeEntityPosition(newped, true)
                        curPed = newped
                        pedIndex = newIndex
                    end
                end
            end
            
            SetEntityHeading(curPed, heading)

            if IsDisabledControlJustPressed(0, 176) then
                if hit == 1 then
                    if inZone then
                        pc = {
                            model = pedlist[pedIndex],
                            coords = vec(CurrentCoords.x, CurrentCoords.y, CurrentCoords.z, heading)
                        }
                        utils.notify("Ped location successfully set", "success", 8000)
                        CancelPlacement()
                        if notif then notif = false end
                    else
                        if not notif then
                            utils.notify("Can only be in the zone !", "error", 8000)
                            notif = true
                        end
                    end
                end
            end
            
            Wait(1)
        end

        results:resolve(pc)
        lib.hideTextUI()
    end)

    return results
end

return pedcreator