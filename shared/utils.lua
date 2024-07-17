---@class OxZone
---@field points vector3[]
---@field thickness number

---@class BlipData
---@field type integer
---@field color integer
---@field label string

---@class GarageData
---@field type? string[]
---@field blip? BlipData
---@field impound? boolean
---@field shared? boolean
---@field interaction? string|{coords: vector4, model:string|integer}
---@field job? table<string, number>
---@field gang? table<string, number>
---@field spawnPoint? vector4[]
---@field spawnPointVehicle? string[]
---@field zones? OxZone

---@class CustomName
---@field name? string

---@class RadialData
---@field id string
---@field label string
---@field icon string
---@field event? string
---@field args {garage: string, type: string[], impound: boolean, shared: boolean, spawnpoint: vector3[]}

---@class GarageVehicleData
---@field garage? string Garage Name
---@field type? string[] Garage Class
---@field impound? boolean Impound Garage|Insurance
---@field shared? boolean Shared Garage
---@field spawnpoint? vector3[] Garage Spawn Point
---@field targetped? boolean Garage Using Ped
---@field depotprice? number Depot Price
---@field props? table Vehicle Properties
---@field deformation? table Vehicle Deformation
---@field body? number Vehicle BodyHealth
---@field engine? number Vehicle EngineHealth
---@field fuel? number Vehicle Fuel Level
---@field plate? string Vehicle Plate
---@field vehName? string Vehicle Name 1
---@field vehicle_name? string Vehicle Name 2
---@field model? string|integer Vehicle Model
---@field coords? vector3|vector4 Vehicle Spawn Coords


utils = {}

local server = IsDuplicityVersion()

---@param rot vector3
local RotationToDirection = function(rot)
    local rotZ = math.rad(rot.z)
    local rotX = math.rad(rot.x)
    local cosOfRotX = math.abs(math.cos(rotX))
    return vector3(-math.sin(rotZ) * cosOfRotX, math.cos(rotZ) * cosOfRotX, math.sin(rotX))
end

---@param string string
---@return string?
string.trim = function ( string )
    if not string then return nil end
    return (string.gsub(string, '^%s*(.-)%s*$', '%1'))
end

---@param string string
---@return string?
string.isEmpty = function (string)
    return string:match("^%s*$")
end

--- Raycast Camera
---@param distance number
---@return boolean|integer
---@return vector3
---@return boolean
---@return vector3
function utils.raycastCam(distance)
    local camRot = GetGameplayCamRot()
    local camPos = GetGameplayCamCoord()
    local dir = RotationToDirection(camRot)
    local dest = camPos + (dir * distance)
    local ray = StartShapeTestRay(camPos, dest, 17, -1, 0)
    local _, hit, endPos = GetShapeTestResult(ray)
    if hit == 0 then endPos = dest end
    local inwater, watercoords = TestProbeAgainstWater(camPos.x, camPos.y, camPos.z, endPos.x, endPos.y, endPos.z)
    return hit, endPos, inwater, watercoords
end

--- Send Notification
---@param msg string
---@param type? string
---@param duration? number
function utils.notify(msg, type, duration)
    lib.notify({
        description = msg,
        type = type,
        duration = duration or 5000
    })
end

--- Show & Hide drawtext
---@param type string
---@param text? string
---@param icon? string
function utils.drawtext (type, text, icon)
    if type == 'show' then
        lib.showTextUI(text,{
            position = "left-center",
            icon = icon or '',
            style = {
                borderRadius= 5,
            }
        })
    elseif type == 'hide' then
        lib.hideTextUI()
    end
end

--- Create context menu
---@param data {id: string, title: string, options: table[]}
function utils.createMenu( data )
    lib.registerContext(data)
    lib.showContext(data.id)
end

--- Create a camera for vehicle review
---@param vehicle integer
function utils.createPreviewCam(vehicle)
    if not DoesEntityExist(vehicle) then return end
    local cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    RenderScriptCams(true, true, 1500,  true,  true)
    local vehpos = GetEntityCoords(vehicle)
    local pos = GetOffsetFromEntityInWorldCoords(vehicle, 0.0, 15.0, 1.0)
    local camF = GetGameplayCamFov()
    SetCamCoord(cam, pos.x, pos.y, pos.z + 4.2)
    PointCamAtCoord(cam, vehpos.x,vehpos.y,vehpos.z + 0.2)
    SetCamFov(cam, camF - 20)
end

--- destroying the camera to review the vehicle
---@param vehicle integer
function utils.destroyPreviewCam(vehicle, enterVehicle)
    if not DoesEntityExist(vehicle) then return end
    local cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    local vehpos = GetEntityCoords(vehicle)
    local pos = GetOffsetFromEntityInWorldCoords(vehicle, 0.0, 5.0, 1.0)
    SetCamCoord(cam, pos.x, pos.y, pos.z + 0.4)
    PointCamAtCoord(cam, vehpos.x,vehpos.y,vehpos.z + 0.2)
    
    if enterVehicle then
        DoScreenFadeOut(500)
        Wait(1000)
        DoScreenFadeIn(500)
        RenderScriptCams(false, true, 1500,  false,  false)
    else
        RenderScriptCams(false, true, 1500,  false,  false)
    end
end

--- Create target ped
---@param model string | integer
---@param coords vector4
---@param options {label: string, icon: string, distance: number, job:string|table, gang:string|table, action: fun(data:table|integer)}
function utils.createTargetPed(model, coords, options)
    local newoptions = {}
    local qbtd = nil --- qb-target distance options
    
    lib.requestModel(model, 1500)
    local ped = CreatePed(0, model, coords.x, coords.y, coords.z - 1, coords.w, false, false)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    FreezeEntityPosition(ped, true)

    if type(options) == "table" and #options > 0 then
        for i=1, #options do
            local data = options[i]
            local opt = {
                name = data.name,
                label = data.label,
                icon = data.icon,
            }
            if Config.Target == "ox" then
                opt.distance = data.distance
                opt.onSelect = function (d)
                    data.action(d)
                end
            elseif Config.Target == "qb" then
                opt.action = function (d)
                    data.action(d)
                end
            end
            qbtd = data.distance
            newoptions[#newoptions+1] = opt
        end
    end

    if #newoptions > 0 then
        if Config.Target == "ox" then
            exports.ox_target:addLocalEntity(ped, newoptions)
        elseif Config.Target == "qb" then
            local param = {
                options = newoptions,
                distance = qbtd
            }
            exports['qb-target']:AddTargetEntity(ped, param)
        end
    end

    return ped
end

--- Remove target ped
---@param entity integer
---@param label string
function utils.removeTargetPed(entity, label)
    if DoesEntityExist(entity) then
        if Config.Target == "ox" then
            exports.ox_target:removeLocalEntity(entity, label)
            DeleteEntity(entity)
        elseif Config.Target == "qb" then
            exports['qb-target']:RemoveTargetEntity(entity, label)
            DeleteEntity(entity)
        end
    end
end

--- Get progress color by level (for fuel, engine, body)
---@param level any
---@return string|false?
function utils.getColorLevel(level)
    if not level then return end
    return level < 25 and "red" or level >= 25 and level < 50 and  "#E86405" or level >= 50 and level < 75 and "#E8AC05" or level >= 75 and "green"
end

--- Get vehicle number plate
---@param vehicle integer
---@return string?
function utils.getPlate ( vehicle )
    if not DoesEntityExist(vehicle) then return end
    return GetVehicleNumberPlateText(vehicle):trim()
end

--- Checking vehicle class
---@param vehType number
---@return string
function utils.getCategoryByClass ( vehType )
    local class = {
        [8] = "motorcycle",
        [13] = "cycles",
        [14] = "boat",
        [15] = "helicopter",
        [16] = "planes",
    }
    return class[vehType] or "car"
end


--- Set vehicle fuel level
---@param vehicle integer
---@param fuel number
function utils.setFuel(vehicle, fuel)
    Wait(100)
    if Config.FuelScript == "ox_fuel" then
        Entity(vehicle).state.fuel = fuel or 100
    else
        exports[Config.FuelScript]:SetFuel(vehicle, fuel or 100)
    end
end

--- Get vehicle fuel level
---@param vehicle integer
---@return number
function utils.getFuel(vehicle)
    local fuelLevel = 0
    if Config.FuelScript == "ox_fuel" then
        fuelLevel = Entity(vehicle).state?.fuel or 100 
    else
        fuelLevel = exports[Config.FuelScript]:GetFuel(vehicle)
    end
    return fuelLevel
end

--- Create vehicle by client side
---@param model string | integer
---@param coords vector4
---@param cb? fun(veh: integer)
---@param network? boolean
---@return integer?
function utils.createPlyVeh ( model, coords, cb, network )
    network = network == nil and true or network
    lib.requestModel(model, 1500)
    local veh = CreateVehicle(model, coords.x, coords.y, coords.z, coords.w, network, false)
    if network then
        local id = NetworkGetNetworkIdFromEntity(veh)
        SetNetworkIdCanMigrate(id, true)
        SetEntityAsMissionEntity(veh, true, true)
    end
    SetVehicleHasBeenOwnedByPlayer(veh, true)
    SetVehicleNeedsToBeHotwired(veh, false)
    SetVehRadioStation(veh, 'OFF')
    SetModelAsNoLongerNeeded(model)
    if cb then cb(veh) else return veh end
end

--- Checking or Get garage type
---@param data table[]
---@return string
function utils.garageType ( data )
    local result = ""
    for i=1, #data do
        local class = data[i]
        result = result .. ("%s%s"):format(class, data[i + 1] and ", " or "")
    end
    return result
end

--- Checking player gang
---@param data table
---@return boolean
function utils.GangCheck ( data )
    local configGang = data.gang
    local playergang = fw.player.gang
    local allowed = false
    if type(configGang) == 'table' then
        local grade = configGang[playergang.name]
        allowed = grade and playergang.grade >= grade
    elseif type(configGang) == 'string' then
        if playergang.name == configGang then
            allowed = true
        end
    end
    return allowed
end

--- Checking player job
---@param data table
---@return boolean
function utils.JobCheck ( data )
    local configJob = data.job
    local playerjob = fw.player.job
    local allowed = false
    if type(configJob) == 'table' then
        local grade = configJob[playerjob.name]
        allowed = grade and playerjob.grade >= grade
    elseif type(configJob) == 'string' then
        if playerjob.name == configJob then
            allowed = true
        end
    end
    return allowed
end

--- Refresh table after removed
---@param t table array | hash
---@return table?
function utils.refreshTable(t)
    local results = {}
    
    if type(t) ~= "table" then
        return
    elseif table.type(t) == "hash" then
        for key, val  in pairs(t) do
            results[key] = val
        end
    elseif table.type(t) == "array" then
        for i=1, #t do
            results[#results+1] = t[i]
        end
    end

    return results
end

--- Merge array tables
---@param o table[]
---@param n table[]
---@return table[]
function utils.mergeArray(o, n)
    local results = {}

    if #o > 0 then
        for i=1, #o do
            results[#results+1] = o[i]
        end
    end

    if #n > 0 then
        for i=1, #n do
            results[#results+1] = n[i]
        end
    end

    return results
end

if server then
    --- Send Notification
    ---@param src number
    ---@param msg string
    ---@param type? string
    ---@param duration? string
    function utils.notify(src, msg, type, duration)
        lib.notify(src, {
            description = msg,
            type = type,
            duration = duration or 5000
        })
    end
end