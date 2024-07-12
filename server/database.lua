local rhd_garages_query = [[
    CREATE TABLE IF NOT EXISTS `rhd_garages` (
    `label` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
    `garageData` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`garageData`)),
    PRIMARY KEY (`label`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
]]

lib.callback.register('rhd_garage:server:fetchGarages', function()
    local garageDB = MySQL.query.await("SHOW TABLES LIKE 'rhd_garages'")
    if #garageDB < 1 then
        print("Creating rhd_garages table")
        MySQL.query.await(rhd_garages_query)

        local resourceFile = LoadResourceFile(GetCurrentResourceName(), 'data/garages.json')
        local jsonGarages = json.decode(resourceFile) ---@type table<string, GarageData>
        if jsonGarages then
            for label, garageData in next, jsonGarages do
                MySQL.query.await("INSERT INTO rhd_garages (label, garageData) VALUES (?, ?)", { label, json.encode(garageData) })
            end
        end
    end
    local res = MySQL.query.await("SELECT * FROM rhd_garages")
    local garages = {}

    if res then
        for i = 1, #res do
            local row = res[i]
            garages[row.label] = json.decode(row.garageData)
        end
    end
    return garages
end)


RegisterNetEvent("rhd_garage:server:saveGarageZone", function(fileData)
    if GetInvokingResource() then return end
    if type(fileData) ~= "table" or type(fileData) == "nil" then return end
    local data = fileData --[[@as table<string, GarageData>]]

    local garages = MySQL.query.await("SELECT label FROM rhd_garages")
    local deleteLabels = {}
    for i = 1, #garages do
        deleteLabels[garages[i].label] = true
    end

    for label, garageData in next, data do
        deleteLabels[label] = false

        local res = MySQL.query.await("INSERT INTO rhd_garages (label, garageData) VALUES (?, ?) ON DUPLICATE KEY UPDATE garageData = ?", {
            label,
            json.encode(garageData),
            json.encode(garageData)
        })

        if not res then
            warn("Failed to save garage data for label: " .. label)
        end
    end

    for label, bool in next, deleteLabels do
        if not bool then goto continue end

        if GetResourceState('qb-core') ~= "missing" then
            MySQL.query.await("UPDATE player_vehicles SET garage = ? WHERE garage = ?", { Config.DefaultDatabaseGarage, label })
        end

        local res = MySQL.query.await("DELETE FROM rhd_garages WHERE label = ?", { label })
        if not res then
            warn("Failed to delete garage data for label: " .. label)
        end

        ::continue::
    end

end)
