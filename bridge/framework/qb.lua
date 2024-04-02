if GetResourceState('qb-core') == "missing" then return end

QBCore = exports['qb-core']:GetCoreObject()
local Utils = require "modules.utils"
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
    qb = true
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
    local vd = QBCore.Shared.Vehicles[model]
    local makename = GetMakeNameFromVehicleModel(model)
    local displayname = GetDisplayNameFromVehicleModel(model)

    local vm = vd?.brand or makename
    local vn = vd?.name or displayname
    return ("%s %s"):format(vm, vn)
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    local PlayerData = QBCore.Functions.GetPlayerData()
    local charinfo = PlayerData.charinfo

    local Job = PlayerData.job
    local Gang = PlayerData.gang
    local Money = PlayerData.money

    fw.player.name = charinfo.firstname .. " " .. charinfo.lastname
    fw.player.money = Money

    fw.player.job = {
        name = Job.name,
        grade = Job.grade.level
    }
    fw.player.gang = {
        name = Gang.name,
        grade = Gang.grade.level
    }
end)

RegisterNetEvent('QBCore:Player:SetPlayerData', function(PlayerData)
    local Job = PlayerData.job
    local Gang = PlayerData.gang
    local Money = PlayerData.money
    local Charinfo = PlayerData.charinfo

    fw.player.name = Charinfo.firstname .. " " .. Charinfo.lastname
    fw.player.money = Money

    fw.player.job = {
        name = Job.name,
        grade = Job.grade.level
    }
    fw.player.gang = {
        name = Gang.name,
        grade = Gang.grade.level
    }
end)

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
        local citizenid, license = pData?.citizenid, withLicense and pData?.license or false
        return citizenid or false, license
    end

    --- Get Player By Identifier
    ---@param identifier string
    ---@return table | boolean
    function fw.gpbi(identifier)
        local p = QBCore.Functions.GetPlayerByCitizenId(identifier)
        return p and p.PlayerData or false
    end

    --- Player Remove Money
    ---@param src number playerid
    ---@param type string cash | bank
    ---@param amount number amount of money
    ---@return boolean
    function fw.rm(src, type, amount)
        local p = QBCore.Functions.GetPlayer(src)
        if not p then return false end
        return p.Functions.RemoveMoney(type, amount, '')
    end

    --- Get Player Name
    ---@param src number
    ---@return string
    function fw.gn(src)
        local idstr = tostring(src)
        local charinfo = xPlayer[idstr]?.charinfo or {}
        return next(charinfo) and ("%s %s"):format(charinfo.firstname, charinfo.lastname) or "Unkown Players"
    end

    --- Get Shared Vehicle
    ---@param model string
    ---@return table
    function fw.gsv(model)
        return QBCore.Shared.Vehicles[model] or {}
    end

    --- Get Vehicle Mods & Deformation By Plate
    ---@param plate any
    function fw.gmdbp(plate)
        local results = MySQL.single.await("SELECT mods, deformation FROM player_vehicles WHERE plate = ? OR fakeplate = ?", {plate, plate})
        if not results then return {prop = {}, deformation = {},} end
        return {prop = json.decode(results.mods), deformation = json.decode(results.deformation)}
    end

    --- Update Vehicle State
    ---@param plate string
    ---@param state number
    ---@param garage string
    ---@return boolean
    function fw.uvs(plate, state, garage)
        local Update = MySQL.update.await("UPDATE player_vehicles SET state = ?, garage = ? WHERE plate = ? OR fakeplate = ?", {state, garage, plate, plate})
        return Update > 0
    end

    --- Update Vehicle State Police Impound
    ---@param plate string
    ---@param state number
    ---@return boolean
    function fw.uvspi(plate, state)
        local update = MySQL.update.await([[
            UPDATE
                player_vehicles SET state = ? WHERE plate = ? OR fakeplate = ?
        ]], {state, plate, plate})
        return update > 0
    end

    --- Swap Vehicle Garage
    ---@param newgarage string
    ---@param plate string
    ---@return boolean
    function fw.svg(newgarage, plate)
        local update = MySQL.update.await("UPDATE player_vehicles SET garage = ? WHERE plate = ? OR fakeplate = ?", {newgarage, plate, plate})
        return update > 0
    end

    --- Update Vehicle Owner
    ---@param plate string
    ---@param oldOwner table
    ---@param newOwner table
    function fw.uvo(oldOwner, newOwner, plate)
        local update = MySQL.update.await("UPDATE player_vehicles SET license = ?, citizenid = ? WHERE citizenid = ? AND plate = ? OR fakeplate = ?", {
            newOwner.license,
            newOwner.citizenid,
            oldOwner.citizenid,
            plate,
            plate
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
                pv.vehicle,
                p.charinfo
            FROM player_vehicles pv LEFT JOIN players p ON pv.citizenid = p.citizenid
                WHERE
                    pv.plate = ? OR pv.fakeplate = ?
        ]]
        local value = {plate, plate}

        if filter and filter.onlyOwner then
            format = [[
                SELECT
                    pv.vehicle,
                    p.charinfo
                FROM player_vehicles pv LEFT JOIN players p ON pv.citizenid = p.citizenid
                    WHERE
                        pv.plate = ? OR pv.fakeplate = ? AND pv.citizenid = ?
            ]]
            value = {plate, plate, identifier}
        end

        local results = MySQL.single.await(format, value)
        if not results then return false end
        local charinfo = json.decode(results.charinfo)
        local ownername = ("%s %s"):format(charinfo.firstname, charinfo.lastname)

        if pleaseUpdate then
            MySQL.update([[
                UPDATE
                    player_vehicles
                        SET
                    vehicle_name = ?, mods = ?, fuel = ?, engine = ?, body = ?, deformation = ? WHERE plate = ? OR fakeplate = ?
            ]], {
                pleaseUpdate.vehicle_name,
                json.encode(pleaseUpdate.mods),
                math.floor(pleaseUpdate.fuel),
                math.floor(pleaseUpdate.engine),
                math.floor(pleaseUpdate.body),
                json.encode(pleaseUpdate.deformation),
                plate,
                plate
            })
        end

        return {
            vehmodel = results.vehicle,
            ownername = ownername
        }
    end

    --- Get Player Vehicle By Plate
    ---@param plate string
    ---@return table
    function fw.gpvbp(plate)
        local results = MySQL.single.await([[
            SELECT 
                pv.citizenid,
                pv.vehicle,
                pv.vehicle_name,
                pv.mods,
                pv.plate,
                pv.fakeplate,
                pv.garage,
                pv.fuel,
                pv.engine,
                pv.body,
                pv.state,
                pv.depotprice,
                pv.balance,
                p.charinfo
            FROM player_vehicles pv LEFT JOIN players p ON pv.citizenid = p.citizenid WHERE pv.plate = ? OR pv.fakeplate = ?    
        ]], {plate, plate})

        local vehicles = {}
        if results then
            local v = results
            local charinfo = json.decode(v.charinfo)
            local mods = json.decode(v.mods)
            vehicles = {
                owner = {
                    name = ("%s %s"):format(charinfo.firstname, charinfo.lastname),
                    citizenid = v.citizenid,
                },
                vehicle_name = v.vehicle_name,
                mods = mods,
                vehicle = v.vehicle,
                model = joaat(v.vehicle),
                plate = v.plate,
                fakeplate = v.fakeplate,
                garage = v.garage,
                fuel = v.fuel,
                engine = v.engine,
                body = v.body,
                state = v.state,
                depotprice = v.depotprice,
                balance = v.balance
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
                vehicle,
                vehicle_name,
                mods,
                state,
                depotprice,
                plate,
                fakeplate,
                fuel,
                engine,
                body,
                deformation
            FROM player_vehicles WHERE citizenid = ? AND garage = ? AND state = ?
        ]]

        local value = {Identifier, garage, 1}
        if filter then
            if not filter.impound then
                if filter.shared then
                    format = [[
                        SELECT
                            pv.vehicle,
                            pv.vehicle_name,
                            pv.mods,
                            pv.state,
                            pv.depotprice,
                            pv.plate,
                            pv.fakeplate,
                            pv.fuel,
                            pv.engine,
                            pv.body,
                            pv.deformation,
                            p.charinfo
                        FROM player_vehicles pv LEFT JOIN players p ON p.citizenid = pv.citizenid WHERE pv.garage = ? AND pv.state = ?
                    ]]
                    value = {garage, 1}
                end
            else
                format = [[
                    SELECT
                        vehicle,
                        vehicle_name,
                        mods,
                        state,
                        depotprice,
                        plate,
                        fakeplate,
                        fuel,
                        engine,
                        body,
                        deformation FROM player_vehicles WHERE citizenid = ? AND state = 0
                ]]
                value = {Identifier}
            end
        end

        local vehicles = {}
        local results = MySQL.query.await(format, value)

        if results and #results > 0 then
            for i=1, #results do
                local data = results[i]
                local mods = json.decode(data.mods)
                local deformation = json.decode(data.deformation)
                local state = data.state
                local model = data.vehicle
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
                    depotprice = depotprice,
                    deformation = deformation
                }

                if filter.shared then
                    local charinfo = json.decode(data.charinfo)
                    local ownername = ("%s %s"):format(charinfo.firstname, charinfo.lastname)
                    vehicles[#vehicles].owner = ownername
                end
            end
        end
        return vehicles
    end

    --- Get Vehicles For Phone
    ---@param src any
    ---@return table
    function fw.gvfp(src)
        local idstr = tostring(src)
        local citizenid = xPlayer[idstr]?.citizenid or false
        if not citizenid then return end
        
        local results = MySQL.query.await([[
                SELECT
                    vehicle,
                    plate,
                    garage,
                    fuel,
                    engine,
                    body,
                    state,
                    paymentsleft
                FROM player_vehicles WHERE citizenid = ?
        ]], {citizenid})

        local vehicles = {}
        if results and results[1] then
            for i=1, #results do
                local v = results[i]
                local plate = v.plate
                local vd = QBCore.Shared.Vehicles[v.vehicle]
                local brand = vd?.brand
                local name = vd?.name
                local defaultname = brand and ("%s %s"):format(brand, name)
                local customName = CNV[v.plate:trim()] and CNV[v.plate:trim()].name
                local vehname = customName or defaultname

                local stateText = locale('rhd_garage:phone_veh_in_garage')

                if v.state == 0 then
                    stateText = vehFuncS.govbp(plate:trim()) and locale('rhd_garage:phone_veh_out_garage') or locale('rhd_garage:phone_veh_in_impound')
                elseif v.state == 2 then
                    stateText = locale('rhd_garage:phone_veh_in_policeimpound')
                end

                local inInsurance = v.state == 0
                local inPoliceImpound = v.state == 2

                local engine = v.engine > 1000 and 1000 or v.engine
                local body = v.body > 1000 and 1000 or v.body

                vehicles[#vehicles+1] = {
                    fullname = vehname,
                    brand = brand or '',
                    model = name or '',
                    plate = v.plate,
                    garage = v.garage,
                    state = stateText,
                    fuel = v.fuel,
                    engine = engine,
                    body = body,
                    paymentsleft = v.paymentsleft,
                    disableTracking = inInsurance or inPoliceImpound,
                }
            end
        end
        return vehicles
    end

    RegisterNetEvent('QBCore:Player:SetPlayerData', function(PlayerData)
        local src = PlayerData.source
        local idstr = tostring(src)
        xPlayer[idstr] = PlayerData
    end)

    RegisterNetEvent('QBCore:Server:PlayerLoaded', function(player)
        local src = player.PlayerData.source
        local idstr = tostring(src)
        xPlayer[idstr] = player.PlayerData
        Utils.print("success", ("Register new cache for %s"):format(GetPlayerName(src)))
    end)

    AddEventHandler("playerDropped", function ()
        local src = source
        local idstr = tostring(src)
        xPlayer[idstr] = nil
        Utils.print("success", ("Remove cache from %s"):format(GetPlayerName(src)))
    end)

    RegisterCommand("reloadcache", function (src)
        local p = QBCore.Functions.GetPlayer(src)
        if not p then return false end
        local idstr = tostring(src)
        xPlayer[idstr] = p.PlayerData
    end, false)
end