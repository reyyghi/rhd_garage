DBFormat = {
    player_vehicles = IsQB and "player_vehicles" or "owned_vehicles",
    players = IsQB and "players" or "users",
    owner = IsQB and "citizenid" or "owner",
    state = IsQB and "state" or "stored"
}

DBFormat = {
    table = {
        player_vehicles = IsQB and "player_vehicles" or "owned_vehicles",
        players = IsQB and "players" or "users"
    },
    column = {
        owner = IsQB and "citizenid" or "owner",
        state = IsQB and "state" or "stored",
        plate = IsQB and "plate, fakeplate" or "plate",
        properties = IsQB and "mods" or "vehicle",
        identifier = IsQB and "citizenid" or "identifier"
    },
    selected_column = {
        vehicleList = {
            shared = IsQB and "vehicle, mods, state, depotprice, plate, fakeplate, deformation, charinfo" or "vehicle, plate, stored, deformation, firstname, lastname",
            normal = IsQB and "vehicle, mods, state, depotprice, plate, fakeplate, deformation" or "vehicle, plate, stored, deformation",
        },
        vehicleData = IsQB and "player_vehicles.citizenid, vehicle, mods, deformation, balance, charinfo" or "owner, vehicle, plate, owner, deformation, firstname, lastname"
    },
    placeholder = {
        owner = IsQB and "citizenid = ?" or "owner = ?",
        plate = IsQB and "plate = ? OR fakeplate = ?" or "plate = ?",
        state = IsQB and "state = ?" or "stored = ?",
        properties = IsQB and "mods = ?" or "vehicle = ?"
    }
}

function DBFormat.getParameters(type, ...)
    local args = {...}
    if type == "vehiclelist" then
        local result = {
            impound = ("SELECT %s FROM %s WHERE %s AND %s"):format(DBFormat.selected_column.vehicleList.normal, DBFormat.table.player_vehicles, DBFormat.placeholder.state, DBFormat.placeholder.owner),
            shared = ("SELECT %s FROM %s LEFT JOIN %s ON %s = %s WHERE garage = ?"):format(DBFormat.selected_column.vehicleList.shared, DBFormat.table.player_vehicles, DBFormat.table.players, ("%s.%s"):format(DBFormat.table.players, DBFormat.column.identifier), ("%s.%s"):format(DBFormat.table.player_vehicles, DBFormat.column.owner)),
            normal = ("SELECT %s FROM %s WHERE garage = ? AND %s"):format(DBFormat.selected_column.vehicleList.normal, DBFormat.table.player_vehicles, DBFormat.placeholder.owner)
        }
        return result[args[1]]
    elseif type == "getowner" then
        local result = {
            shared = ("SELECT 1 FROM %s WHERE %s"):format(DBFormat.table.player_vehicles, DBFormat.placeholder.plate),
            normal = ("SELECT 1 FROM %s WHERE %s AND %s"):format(DBFormat.table.player_vehicles, DBFormat.placeholder.owner, DBFormat.placeholder.plate)
        }
        return result[args[1]]
    elseif type == "createvehicle" then
        return ("SELECT %s, deformation FROM %s WHERE %s"):format(DBFormat.column.properties, DBFormat.table.player_vehicles, DBFormat.placeholder.plate)
    elseif type == "vehicledata" then
        return ("SELECT %s FROM %s LEFT JOIN %s ON %s.%s = %s.%s WHERE %s"):format(DBFormat.selected_column.vehicleData, DBFormat.table.player_vehicles, DBFormat.table.players, DBFormat.table.players, DBFormat.column.identifier, DBFormat.table.player_vehicles, DBFormat.column.owner, DBFormat.placeholder.plate)
    elseif type == "swapgarage" then
        return ("UPDATE %s SET garage = ? WHERE %s AND %s"):format(DBFormat.table.player_vehicles, DBFormat.placeholder.owner, DBFormat.placeholder.plate)
    elseif type == "transfervehicle" then
        return ("UPDATE %s SET %s WHERE %s AND %s"):format(DBFormat.table.player_vehicles, DBFormat.placeholder.owner, DBFormat.placeholder.plate, DBFormat.placeholder.owner)
    elseif type == "state_garage" then
        return ("UPDATE %s SET %s, %s, garage = ?, deformation = ? WHERE %s"):format(DBFormat.table.player_vehicles, DBFormat.placeholder.state, DBFormat.placeholder.properties, DBFormat.placeholder.plate)
    elseif type == "state_policeImpound_insert" then
        return ("UPDATE %s SET %s, %s, deformation = ? WHERE %s"):format(DBFormat.table.player_vehicles, DBFormat.placeholder.state, DBFormat.placeholder.properties, DBFormat.placeholder.plate)
    elseif type == "state_policeImpound_remove" then
        return ("UPDATE %s SET %s WHERE %s"):format(DBFormat.table.player_vehicles, DBFormat.placeholder.state, DBFormat.placeholder.plate)
    end
end

function DBFormat.getValue(type, ...)
    local args = {...}
    if type == "vehiclelist" then
        local result = {
            normal = {args[2], args[3]},
            impound = {0, args[3]},
            shared = {args[2]},
        }
        return result[args[1]]
    elseif type == "getowner" then
        local result = {
            shared = IsQB and {args[3], args[3]} or {args[3]},
            normal = IsQB and {args[2], args[3], args[3]} or {args[2], args[3]}
        }
        return result[args[1]]
    elseif type == "createvehicle" then
        return IsQB and {args[1], args[1]} or {args[1]}
    elseif type == "vehicledata" then
        return IsQB and {args[1], args[1]} or {args[1]}
    elseif type == "swapgarage" then
        return IsQB and {args[1], args[2], args[3], args[3]} or {args[1], args[2], args[3]}
    elseif type == "transfervehicle" then
        return IsQB and {args[1], args[2], args[2], args[3]} or {args[1], args[2], args[3]}
    elseif type == "state_garage" then
        return IsQB and {args[1], args[2], args[3], args[4], args[5], args[5]} or {args[1], args[2], args[3], args[4], args[5]}
    elseif type == "state_policeImpound_insert" then
        return IsQB and {args[1], args[2], args[3], args[4], args[4]} or {args[1], args[2], args[3], args[4]}
    elseif type == "state_policeImpound_remove" then
        return IsQB and {0, args[1], args[1]} or {0, args[1]}
    end
end
