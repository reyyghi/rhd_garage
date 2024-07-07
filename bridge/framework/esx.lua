if GetResourceState('es_extended') == "missing" then return end

ESX = exports["es_extended"]:getSharedObject()
local isServer = IsDuplicityVersion()

fw = {
    player = {
        name = "Unkown Players",
        money = {
            cash = 0,
            bank = 0
        },
        job = {
            name = "none",
            grade = 0
        },
        gang = {
            name = "none",
            grade = 0
        }
    },
    esx = true,
    playerLoaded = false
}

--- Get Money
---@param type string
---@return integer
function fw.gm(type)
    return fw.player.money?[type] or 0    
end

---@return string
function fw.gn()
    return fw.player.name
end

--- Get Vehicle Name
---@param model string
function fw.gvn(model)
    local makename = GetMakeNameFromVehicleModel(model)
    local displayname = GetDisplayNameFromVehicleModel(model)
    return ("%s %s"):format(makename, displayname)
end

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(playerData)
    
    if not playerData or type(playerData) ~= "table" then
        return
    end

    for i=1, #playerData.accounts do
        local data = playerData.accounts[i]
        if data.name == "money" then
            fw.player.money.cash = data.money
        end

        if data.name == "bank" then
            fw.player.money.bank = data.money
        end
    end

    fw.player.job = {
        name = playerData.job.name,
        grade = playerData.job.grade
    }

    fw.player.name = playerData.name
    fw.playerLoaded = true
end)

RegisterNetEvent("esx:setAccountMoney")
AddEventHandler("esx:setAccountMoney", function(account)
    if type(account) ~= "table" then return end
    if account.name == "money" then fw.player.money.cash = account.money end
    if account.name == "bank" then fw.player.money.bank = account.money end
end)

RegisterNetEvent("esx:setJob")
AddEventHandler("esx:setJob", function(Job)
    if type(Job) ~= "table" then return end
    fw.player.job = {name = Job.name, grade = Job.grade}
end)

if Config.InDevelopment then
    RegisterCommand("loaded", function ()
        fw.playerLoaded = true
    end, false)
end

if isServer then
    local xPlayer = {}

    --- Get Player
    ---@param src number
    ---@return table | boolean
    function fw.gp(src)
        if not xPlayer then return false end
        return xPlayer[tostring(src)] or false
    end

    --- Get Identifier
    ---@param src number
    ---@param withLicense boolean?
    ---@return string | boolean
    ---@return string | boolean
    function fw.gi(src, withLicense)
        local pData = xPlayer[tostring(src)]
        local citizenid, license = pData?.identifier, withLicense and pData?.identifier or false
        return citizenid or false, license
    end

    --- Get Player By Identifier
    ---@param identifier string
    ---@return table | boolean
    function fw.gpbi(identifier)
        local p = ESX.GetPlayerFromIdentifier(identifier)
        return p and p or false
    end

    --- Player Remove Money
    ---@param src number playerid
    ---@param type string cash | bank
    ---@param amount number amount of money
    ---@return boolean?
    function fw.rm(src, type, amount)
        local p = ESX.GetPlayerFromId(src)
        if not p then return false end
        type = type == "cash" and "money" or type
        if p.getAccount(type).money >= amount then
            p.removeAccountMoney(type, amount, '')
            return true
        end
        return false
    end

    --- Get Player Name
    ---@param src number
    ---@return string
    function fw.gn(src)
        local idstr = tostring(src)
        local playername = xPlayer[idstr]?.name or false
        return playername or "Unkown Players"
    end

    --- Get Shared Vehicle
    ---@param model string
    ---@return table
    function fw.gsv(model)
        return {}
    end

    --- Get Vehicle Mods & Deformation By Plate
    ---@param plate any
    function fw.gmdbp(plate)
        local results = MySQL.single.await("SELECT vehicle, deformation FROM owned_vehicles WHERE plate = ?", {plate})
        if not results then return {prop = {}, deformation = {},} end
        return {prop = json.decode(results.vehicle), deformation = json.decode(results.deformation)}
    end

    --- Update Vehicle State
    ---@param plate string
    ---@param state number
    ---@param garage string
    ---@return boolean
    function fw.uvs(plate, state, garage)
        local Update = MySQL.update.await("UPDATE owned_vehicles SET stored = ?, garage = ? WHERE plate = ?", {state, garage, plate})
        return Update > 0
    end

    --- Update Vehicle State Police Impound
    ---@param plate string
    ---@param state number
    ---@return boolean
    function fw.uvspi(plate, state)
        local update = MySQL.update.await([[
            UPDATE
                owned_vehicles SET stored = ? WHERE plate = ?
        ]], {state, plate})
        return update > 0
    end

    --- Swap Vehicle Garage
    ---@param newgarage string
    ---@param plate string
    ---@return boolean
    function fw.svg(newgarage, plate)
        local update = MySQL.update.await("UPDATE owned_vehicles SET garage = ? WHERE plate = ?", {newgarage, plate})
        return update > 0
    end

    --- Update Vehicle Owner
    ---@param plate string
    ---@param oldOwnerId table
    ---@param newOwnerId table
    function fw.uvo(oldOwnerId, newOwnerId, plate)
        local mp = fw.gp(oldOwnerId)
        local tp = fw.gp(newOwnerId)
        if not mp then return end
        if not tp then return false, locale("notify.error.player_offline", newOwnerId) end
        
        local update = MySQL.update.await("UPDATE owned_vehicles SET owner = ? WHERE owner = ? AND plate = ?", {
            tp.identifier,
            mp.identifier,
            plate,
        })
        return update > 0
    end

    ---- Get Vehicle Owner By Plate
    ---@param src number
    ---@param plate string
    ---@param filter {onlyOwner: boolean}
    ---@param pleaseUpdate {vehicle_name:string, mods: table, deformation: table, fuel: number, engine: number, body: number}
    ---@return table | boolean
    function fw.gvobp(src, plate, filter, pleaseUpdate)
        local identifier = fw.gi(src)
        if not identifier then return false end

        local format = [[
            SELECT
                ov.vehicle,
                u.firstname,
                u.lastname
            FROM owned_vehicles ov LEFT JOIN users u ON ov.owner = u.identifier
                WHERE
                    ov.plate = ?
        ]]
        local value = {plate}

        if filter and filter.onlyOwner then
            format = [[
                SELECT
                    ov.vehicle,
                    u.firstname,
                    u.lastname
                FROM owned_vehicles ov LEFT JOIN users u ON ov.owner = u.identifier
                    WHERE
                        ov.plate = ? AND ov.owner = ?
            ]]
            value = {plate, identifier}
        end

        local results = MySQL.single.await(format, value)
        if not results then return false end
        local vehicles = json.decode(results.vehicle)
        local ownername = ("%s %s"):format(results.firstname, results.lastname)
        local vehmodel = vehicles.model

        if pleaseUpdate then
            MySQL.update([[
                UPDATE
                    owned_vehicles
                        SET
                    vehicle_name = ?, vehicle = ?, fuel = ?, engine = ?, body = ?, deformation = ? WHERE plate = ?
            ]], {
                pleaseUpdate.vehicle_name,
                json.encode(pleaseUpdate.mods),
                math.floor(pleaseUpdate.fuel),
                math.floor(pleaseUpdate.engine),
                math.floor(pleaseUpdate.body),
                json.encode(pleaseUpdate.deformation),
                plate
            })
        end

        return {
            vehmodel = vehmodel,
            ownername = ownername
        }
    end

    --- Get Player Vehicle By Plate
    ---@param plate string
    ---@return table
    function fw.gpvbp(plate)
        local results = MySQL.single.await([[
            SELECT 
                ov.owner,
                ov.plate,
                ov.vehicle,
                ov.vehicle_name,
                ov.stored,
                ov.garage,
                ov.fuel,
                ov.engine,
                ov.body,
                u.firstname,
                u.lastname
            FROM owned_vehicles ov LEFT JOIN users u ON ov.owner = u.identifier WHERE ov.plate = ?   
        ]], {plate})

        local vehicles = {}
        if results then
            local v = results
            local mods = json.decode(v.vehicle)
            vehicles = {
                owner = {
                    name = ("%s %s"):format(v.firstname, v.lastname),
                    citizenid = v.owner,
                },
                vehicle_name = v.vehicle_name,
                mods = mods,
                vehicle = mods.model,
                model = mods.model,
                plate = v.plate,
                fakeplate = v.fakeplate,
                garage = v.garage,
                fuel = v.fuel,
                engine = v.engine,
                body = v.body,
                state = v.stored,
                depotprice = v.depotprice or 0,
                balance = v.balance or 0
            }
        end

        return vehicles
    end

    --- Get Player Vehicles By Garage
    ---@param src string
    ---@param garage string
    ---@param filter {impound: boolean, shared: boolean}
    function fw.gpvbg(src, garage, filter)
        local Identifier = fw.gi(src)
        if not Identifier then return {} end
        local format = [[
            SELECT 
                plate,
                vehicle,
                vehicle_name,
                stored,
                garage,
                fuel,
                engine,
                body,
                deformation
            FROM owned_vehicles WHERE owner = ? AND garage = ? AND stored = ?
        ]]

        local value = {Identifier, garage, 1}
        if filter then
            if not filter.impound then
                if filter.shared then
                    format = [[
                        SELECT
                            ov.plate,
                            ov.vehicle,
                            ov.vehicle_name,
                            ov.stored,
                            ov.garage,
                            ov.fuel,
                            ov.engine,
                            ov.body,
                            ov.deformation,
                            u.firstname,
                            u.lastname
                        FROM owned_vehicles ov LEFT JOIN users u ON ov.owner = u.identifier WHERE ov.garage = ? AND ov.stored = ?
                    ]]
                    value = {garage, 1}
                end
            else
                format = [[
                    SELECT
                        plate,
                        vehicle,
                        vehicle_name,
                        stored,
                        garage,
                        fuel,
                        engine,
                        body,
                        deformation FROM owned_vehicles WHERE owner = ? AND stored = 0
                ]]
                value = {Identifier}
            end
        end

        local vehicles = {}
        local results = MySQL.query.await(format, value)

        if results and #results > 0 then
            for i=1, #results do
                local data = results[i]
                local mods = json.decode(data.vehicle)
                local deformation = json.decode(data.deformation)
                local state = data.stored
                local model = mods.model
                local plate = data.plate
                local depotprice = data.depotprice
                local fakeplate = data.fakeplate
                
                vehicles[#vehicles+1] = {
                    vehicle = mods,
                    vehicle_name = data.vehicle_name,
                    fuel = data.fuel or 100,
                    engine = data.engine,
                    body = data.body,
                    state = state,
                    model = model,
                    plate = plate,
                    fakeplate = fakeplate,
                    depotprice = depotprice or 0,
                    deformation = deformation
                }

                if filter.shared then
                    local ownername = ("%s %s"):format(data.firstname, data.lastname)
                    vehicles[#vehicles].owner = ownername
                end
            end
        end
        return vehicles
    end

    --- Get Vehicles For Phone
    ---@param src any
    ---@return table?
    function fw.gvfp(src)
        local idstr = tostring(src)
        local citizenid = xPlayer[idstr]?.identifier or false
        if not citizenid then return end
        
        local results = MySQL.query.await([[
                SELECT
                    plate
                    vehicle,
                    vehicle_name
                    stored,
                    garage,
                    fuel,
                    engine,
                    body,
                    paymentsleft
                FROM owned_vehicles WHERE owner = ?
        ]], {
            citizenid
        })

        local vehicles = {}
        if results and results[1] then
            for i=1, #results do
                local v = results[i]
                local plate = v.plate
                local defaultname = v.vehicle_name or "Unkown Vehicles"
                local customName = CNV[v.plate:trim()] and CNV[v.plate:trim()].name
                local vehname = customName or defaultname

                local stateText = locale('status.in')

                if v.stored == 0 then
                    stateText = vehFuncS.govbp(plate:trim()) and locale('status.out') or locale('status.insurance')
                elseif v.stored == 2 then
                    stateText = locale('status.confiscated')
                end

                local inInsurance = v.stored == 0
                local inPoliceImpound = v.stored == 2

                local engine = v.engine > 1000 and 1000 or v.engine
                local body = v.body > 1000 and 1000 or v.body

                vehicles[#vehicles+1] = {
                    fullname = vehname,
                    brand = '',
                    model = '',
                    plate = v.plate,
                    garage = v.garage,
                    state = stateText,
                    fuel = v.fuel,
                    engine = engine,
                    body = body,
                    paymentsleft = v.paymentsleft or 0,
                    disableTracking = inInsurance or inPoliceImpound,
                }
            end
        end
        return vehicles
    end

    RegisterNetEvent('esx:playerLoaded', function(player, playerData)
        local src = playerData.source
        local idstr = tostring(src)
        xPlayer[idstr] = playerData
        lib.print.info(("Register new cache for %s"):format(GetPlayerName(src)))
    end)

    AddEventHandler("playerDropped", function ()
        local src = source
        local idstr = tostring(src)
        xPlayer[idstr] = nil
        lib.print.info(("Remove cache from %s"):format(GetPlayerName(src)))
    end)

    if Config.InDevelopment then
        RegisterCommand("reloadcache", function (src)
            local p = ESX.GetPlayerFromId(src)
            if not p then return false end
            local idstr = tostring(src)
            xPlayer[idstr] = p
        end, false)
    end
end