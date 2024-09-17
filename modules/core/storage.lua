local storage = {}

local function generateVehicleData(t)
    if not Array.isArray(t) then
        return
    end

    local pos = 1
    local results = {}

    Array.forEach(t, function (veh)
        local plate = veh.plate and utils.string.trim(veh.plate)
        local properties = veh.properties and json.decode(veh.properties) or {}
        local logs = veh.logs and json.decode(veh.logs) or {}

        results[pos] = {
            label = veh.label,
            properties = properties,
            model = tonumber(veh.model),
            plate = plate,
            garage = veh.garage,
            fuel = veh.fuel,
            engine = veh.engine and math.floor(veh.engine / 10),
            body = veh.body and math.floor(veh.body / 10),
            state = veh.state,
            owner = {
                name = veh.owner_name,
                identifier = veh.identifier
            },
            logs = logs
        }
        pos += 1
    end)
    
    return results
end

---@class updateRequest
---@field owner? string
---@field plate? string
---@field vehicle? table[]
---@field vehicle_name? string
---@field type? string
---@field job? string
---@field stored? number
---@field garage? string
---@field fuel? number
---@field engine? number
---@field body? number

---@class filterRequest
---@field identifier string|boolean
---@field plate string
---@field garage string
---@field stored number

---@class requestData
---@field update updateRequest
---@field filter filterRequest
---@field ownerData boolean


local function generateQuery(request, limit)
    if not request then return end

    local query = ''
    local clausePos, placeholderPos = 1, 1
    local whereClause = {} local updateClause = {} local placeHolders = {}
    local FILTER = request.filter local SELECT = request.select local UPDATE = request.update

    if SELECT then
        local format = SELECT[1] and table.concat(SELECT, ', ') or SELECT
        query = ('SELECT %s FROM user_vehicles WHERE %s'):format(format, limit and '%s LIMIT ' .. limit or '%s')
    elseif UPDATE and next(UPDATE) then
        
        for column, value in pairs(UPDATE) do
            updateClause[clausePos] = ('%s = ?'):format(column)
            placeHolders[placeholderPos] = value
            clausePos += 1
            placeholderPos += 1
        end
        
        clausePos = 1
        query = ('UPDATE user_vehicles SET %s WHERE %s'):format(table.concat(updateClause, ', '), '%s')
    end
    
    if FILTER.identifier then
        whereClause[clausePos] = 'identifier = ?'
        placeHolders[placeholderPos] = FILTER.identifier
        clausePos += 1 placeholderPos += 1
    end

    if FILTER.plate then
        whereClause[clausePos] = 'plate = ?'
        placeHolders[placeholderPos] = FILTER.plate
        clausePos += 1 placeholderPos += 1
    end

    if FILTER.garage then
        whereClause[clausePos] = 'garage = ?'
        placeHolders[placeholderPos] = FILTER.garage
        clausePos += 1 placeholderPos += 1
    end
    
    if FILTER.state then
        whereClause[clausePos] = 'state = ?'
        placeHolders[placeholderPos] = FILTER.state
    end

    query = query:format(table.concat(whereClause, ' AND '))

    return query, placeHolders
end

function storage.getVehicles(request)
    local query, placeHolder = generateQuery(request)
    local results = MySQL.query.await(query, placeHolder)
    return results[1] and generateVehicleData(results) or false
end

function storage.getVehicleData(request)
    local query, placeHolder = generateQuery(request, 1)
    local results = MySQL.single.await(query, placeHolder)
    return results or {}
end

function storage.updateVehicle(request)
    local query, placeHolder = generateQuery(request)
    local results = MySQL.update.await(query, placeHolder)
    return results > 0
end

return storage