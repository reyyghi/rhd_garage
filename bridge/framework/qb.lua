if GetResourceState('qb-core') == "missing" then return end

local QBCore = exports['qb-core']:GetCoreObject()
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
    return vd?.name or GetDisplayNameFromVehicleModel(model)
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
    ---@param pleaseUpdate { mods: table, deformation: table, fuel: number, engine: number, body: number }
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
                mods = ?, fuel = ?, engine = ?, body = ?, deformation = ? WHERE plate = ? OR fakeplate = ?
            ]], {
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
            FROM player_vehicles pv LEFT JOIN players p ON pv.citizenid = p.citizenid WHERE plate = ? OR fakeplate = ?    
        ]], {plate, plate})

        local vehicles = {}
        if results and results[1] then
            for i=1, #results do
                local data = results[i]
                local charinfo = json.decode(data.charinfo)
                local mods = json.decode(data.mods)
                vehicles[#vehicles+1] = {
                    owner = {
                        name = ("%s %s"):format(charinfo.firstname, charinfo.lastname),
                        citizenid = data.citizenid,
                    },
                    mods = mods,
                    vehicle = data.vehicle,
                    model = joaat(data.vehicle),
                    plate = data.plate,
                    fakeplate = data.fakeplate,
                    garage = data.garage,
                    fuel = data.fuel,
                    engine = data.engine,
                    body = data.body,
                    state = data.state,
                    depotprice = data.depotprice,
                    balance = data.balance
                }
            end
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
                    SELECT vehicle, mods, state, depotprice, plate, fakeplate, fuel, engine, body, deformation FROM player_vehicles WHERE citizenid = ? AND state = 0
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