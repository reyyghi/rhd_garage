if not Config.UsePoliceImpound then return end

lib.callback.register("rhd_garage:cb_server:policeImpound.getVehicle", function (_, garage)
    local db = {}
    local dataToSend = {}

    if Framework.qb() then
        db.t = "player_vehicles.deformation"
        db.j = "player_vehicles"
        db.p = "player_vehicles.plate"
    elseif Framework.esx() then
        db.t = "owned_vehicles.deformation"
        db.j = "owned_vehicles"
        db.p = "owned_vehicles.plate"
    end
    
    local result = MySQL.query.await(("SELECT police_impound.citizenid, police_impound.plate, police_impound.vehicle, police_impound.props, police_impound.owner, police_impound.officer, police_impound.date, police_impound.fine, police_impound.paid, police_impound.garage, %s FROM police_impound LEFT JOIN %s ON %s = police_impound.plate WHERE police_impound.garage = ?"):format(
        db.t, db.j, db.p), {garage}
    )

    if result and next(result) then
        for k, v in pairs(result) do
            dataToSend[#dataToSend+1] = {
                citizenid = v.citizenid,
                props = json.decode(v.props),
                deformation = json.decode(v.deformation),
                plate = v.plate,
                vehicle = v.vehicle,
                owner = v.owner,
                officer = v.officer,
                fine = v.fine,
                paid = v.paid,
                date = v.date,
            }
        end
    end

    return dataToSend
end)

lib.callback.register("rhd_garage:cb_server:policeImpound.impoundveh", function (_, impoundData )
    local impounded = MySQL.insert.await('INSERT INTO `police_impound` (citizenid, plate, vehicle, props, owner, officer, date, fine, garage) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)', {
        impoundData.citizenid, impoundData.plate, impoundData.vehicle, json.encode(impoundData.prop), impoundData.owner, impoundData.officer, os.date('%d/%m/%Y', impoundData.date), impoundData.fine, impoundData.garage
    })
    if Framework.esx() then
        MySQL.update('UPDATE owned_vehicles SET stored = ?, vehicle = ?, deformation = ? WHERE plate = ?', { 2, json.encode(impoundData.prop), json.encode(impoundData.deformation), impoundData.plate })
        return
    end

    MySQL.update('UPDATE player_vehicles SET state = ?, mods = ?, deformation = ? WHERE plate = ? or fakeplate = ?', { 2, json.encode(impoundData.prop), json.encode(impoundData.deformation), impoundData.plate, impoundData.plate })
    
    return true
end)

lib.callback.register("rhd_garage:cb_server:policeImpound.cekDate", function (_, date )
    local takeout, day = false, 0

    local d, m, y = date:match("(%d+)/(%d+)/(%d+)")
    local currentDate = os.date("*t")
    local targetDate = {year = tonumber(y), month = tonumber(m), day = tonumber(d)}
    
    day = os.difftime(os.time(targetDate), os.time(currentDate)) / (24 * 60 * 60)

    if os.date('%d/%m/%Y') >= date then
        takeout = true
    end

    return takeout, math.ceil(day)
end)

--- events
RegisterNetEvent("rhd_garage:server:updateState", function ( data )
    local prop = data.prop
    local deformation = data.deformation
    local state = data.state
    local garage = data.garage
    local plate = data.plate
    
    if Framework.esx() then
        MySQL.update('UPDATE owned_vehicles SET stored = ?, vehicle = ?, garage = ?, deformation = ? WHERE plate = ?', { state, json.encode(prop), garage, json.encode(deformation), plate })
        return
    end

    MySQL.update('UPDATE player_vehicles SET state = ?, mods = ?, garage = ?, deformation = ? WHERE plate = ? or fakeplate = ?', { state, json.encode(prop), garage, json.encode(deformation), plate, plate })
end)

RegisterNetEvent('rhd_garage:server:updateState.policeImpound', function( plate )
    MySQL.query('DELETE FROM police_impound WHERE plate = ?', { plate })

    if Framework.esx() then
        MySQL.update('UPDATE owned_vehicles SET stored = ? WHERE plate = ?', { 0, plate })
        return
    end

    MySQL.update('UPDATE player_vehicles SET state = ? WHERE plate = ? or fakeplate = ?', { 0, plate, plate })
end)

RegisterNetEvent('rhd_garage:server:policeImpound.sendBill', function( citizenid, fine, plate )
    local Player = Framework.server.GetPlayerFromCitizenid(citizenid)
    local src

    if not Player then return end

    if Framework.esx() then
        src = Player.source
    elseif Framework.qb() then
        src = Player.PlayerData.source
    end

    local paid = lib.callback.await("rhd_garage:cb_client:sendFine", src, fine)

    if paid then
        MySQL.update('UPDATE police_impound SET paid = ? WHERE plate = ?', { 1, plate })
    end
end)