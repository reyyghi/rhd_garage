
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
    local filter = request.filter
    local whereClause = {} local updateClause = {} local placeHolders = {}

    local clausePos, placeholderPos = 1, 1

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
            updateClause[clausePos] = ('ov.%s = ?'):format(column)
            placeHolders[placeholderPos] = value
        end

        clausePos = 1
        placeholderPos += 1
        query = query:format(table.concat(updateClause, ', '), '%s')
    end

    if filter.identifier then
        whereClause[clausePos] = 'ov.owner = ?'
        placeHolders[placeholderPos] = filter.identifier
        clausePos += 1 placeholderPos += 1
    end

    if filter.plate then
        whereClause[clausePos] = 'ov.plate = ?'
        placeHolders[placeholderPos] = filter.plate
        clausePos += 1 placeholderPos += 1
    end

    if filter.garage then
        whereClause[clausePos] = 'ov.garage = ?'
        placeHolders[placeholderPos] = filter.garage
        clausePos += 1 placeholderPos += 1
    end
    
    if filter.stored then
        whereClause[clausePos] = 'ov.stored = ?'
        placeHolders[placeholderPos] = filter.stored
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

    local success = MySQL.update.await(results.query, results.placeholder)
    return success > 0
end

function vehStorage.getGarageByPlate(plate)
    local results = MySQL.single.await('SELECT stored, garage FROM owned_vehicles WHERE plate = ?', {plate})
    return results and results.stored > 0 and results.garage or 'impounded'
end

function vehStorage.getProperties(plate)
    local results = MySQL.single.await('SELECT vehicle, deformation FROM owned_vehicles WHERE plate = ?', {plate})
    return results and json.decode(results.vehicle), json.decode(results.deformation)
end

_ENV.vehStorage = vehStorage