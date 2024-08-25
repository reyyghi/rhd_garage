
local vehStorage = {}

local function generateVehicleData(t)
    if not lib.array.isArray(t) then
        return
    end

    local pos = 1
    local results = {}

    lib.array.forEach(t, function (veh)
        local plate = veh.plate and utils.string.trim(veh.plate)
        local mods = veh.vehicle and json.decode(veh.vehicle) or {}

        results[pos] = {
            label = veh.vehicle_name,
            mods = mods,
            vehicle = mods.model,
            model = mods.model,
            plate = plate,
            garage = veh.garage,
            fuel = veh.fuel,
            engine = veh.engine and math.floor(veh.engine / 10),
            body = veh.body and math.floor(veh.body / 10),
            state = veh.stored and veh.stored > 0,
        }
        if veh.firstname and veh.lastname then
            results[pos].owner = {
                name = ("%s %s"):format(veh.firstname, veh.lastname),
                identifier = veh.identifier,
            }
        end
    end)
    
    return results
end

---@param request requestData
---@return table?
local function generateQuery(request, queryType)
    if not request then
        return
    end

    local query = ''
    local stringPos = 1
    local filter = request.filter
    local whereClause = {} local updateClause = {} local placeHolders = {}


    if queryType == 'select' then
        query = [[
                SELECT
                    ov.owner, ov.plate, ov.vehicle, ov.vehicle_name, ov.stored, ov.garage,
                        ov.fuel, ov.engine, ov.body, ov.deformation FROM owned_vehicles ov WHERE %s
        ]]
    
        if request.ownerData then
            query = [[
                SELECT
                    u.firstname, u.lastname, ov.owner, ov.plate, ov.vehicle, ov.vehicle_name, ov.stored, ov.garage,
                        ov.fuel, ov.engine, ov.body, ov.deformation FROM owned_vehicles ov LEFT JOIN users u ON ov.owner = u.identifier WHERE %s
            ]]
        end
    elseif queryType == 'update' then

        query = [[
            UPDATE owned_vehicles ov SET %s WHERE %s
        ]]

        for column, value in pairs(request.update) do
            updateClause[stringPos] = ('ov.%s = ?'):format(column)
            placeHolders[stringPos] = value
            stringPos += 1
        end

        stringPos = 1
        query = query:format(table.concat(updateClause, ', '), '%s')
    end

    if filter.identifier then
        whereClause[stringPos] = 'ov.owner = ?'
        placeHolders[stringPos] = filter.identifier
        stringPos += 1
    end

    if filter.plate then
        whereClause[stringPos] = 'ov.plate = ?'
        placeHolders[stringPos] = filter.plate
        stringPos += 1
    end

    if filter.garage then
        whereClause[stringPos] = 'ov.garage = ?'
        placeHolders[stringPos] = filter.garage
        stringPos += 1
    end
    
    if filter.stored then
        whereClause[stringPos] = 'ov.stored = ?'
        placeHolders[stringPos] = filter.stored
    end

    return {
        query = query:format(table.concat(whereClause, ' AND ')),
        placeholder = placeHolders
    }
end

function vehStorage.fetchPlayerVehicles(request, queryType)
    local results = generateQuery(request, queryType)
    
    if not results then
        return
    end

    local vehicles = MySQL.query.await(results.query, results.placeholder)
    return vehicles[1] and generateVehicleData(vehicles) or false
end

function vehStorage.updatePlayerVehicles(request, queryType)
    local results = generateQuery(request, queryType)
    
    if not results then
        return
    end

    print(results.query, json.encode(results.placeholder, {indent = true}))
    local success = MySQL.update.await(results.query, results.placeholder)
    return success > 0
end

function vehStorage.getGarageByPlate(plate)
    local results = MySQL.single.await('SELECT stored, garage FROM owned_vehicles WHERE plate = ?', {plate})
    return results and results.stored > 0 and results.garage or 'impounded'
end

_ENV.vehStorage = vehStorage