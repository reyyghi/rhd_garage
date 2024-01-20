if not Config.UsePoliceImpound then return end

lib.callback.register("rhd_garage:cb_server:policeImpound.getVehicle", function (_, garage)
    local dataToSend = {}
    local result = MySQL.query.await("SELECT * FROM police_impound WHERE garage = ?", {garage})
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
    local update = MySQL.update.await(DBFormat.getParameters("state_policeImpound_insert"), DBFormat.getValue("state_policeImpound_insert", 2, json.encode(impoundData.prop), json.encode(impoundData.deformation), impoundData.plate))
    return update > 0
end)

lib.callback.register("rhd_garage:cb_server:policeImpound.cekDate", function (_, date )
    local takeout, day = false, 0
    local d, m, y = date:match("(%d+)/(%d+)/(%d+)")
    local currentDate = os.date("*t")
    local targetDate = {year = tonumber(y), month = tonumber(m), day = tonumber(d)}
    day = os.difftime(os.time(targetDate), os.time(currentDate)) / (24 * 60 * 60)
    if os.date('%d/%m/%Y') >= date then takeout = true end
    return takeout, math.ceil(day)
end)

--- events
RegisterNetEvent('rhd_garage:server:removeFromPoliceImpound', function( plate )
    MySQL.query('DELETE FROM police_impound WHERE plate = ?', { plate })
    MySQL.update(DBFormat.getParameters("state_policeImpound_remove"), DBFormat.getValue("state_policeImpound_remove", plate))
end)

RegisterNetEvent('rhd_garage:server:policeImpound.sendBill', function( citizenid, fine, plate )
    local src
    local Player = Framework.server.GetPlayerFromCitizenid(citizenid)
    if not Player then return end
    if Framework.esx() then src = Player.source elseif Framework.qb() then src = Player.PlayerData.source end
    local paid = lib.callback.await("rhd_garage:cb_client:sendFine", src, fine)
    if paid then MySQL.update("UPDATE police_impound SET paid = 1 WHERE plate = ?", { plate }) end
end)