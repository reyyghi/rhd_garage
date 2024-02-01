Storage = {}

local function GroupFormat (groupData)
    local gJob = 'nil'

    if groupData and next(groupData) then
        local jobTable = {}
        local formatTable = '{%s}'
        for job, level in pairs(groupData) do
            jobTable[#jobTable + 1] = ('["%s"] = %d'):format(job, level)
        end
        gJob = formatTable:format(table.concat(jobTable, ', '))
    end

    return gJob
end

local function SaveGarage(garageData)
    local result = {}
    local Format = [[
    ["%s"] = {
        type = {%s},
        blip = %s,
        zones = {
            points = {
                %s
            },
            thickness = "%s"
        },
        job = %s,
        gang = %s,
        impound = %s,
        shared = %s
    },
]]
    for label, data in pairs(garageData) do

        local points = {}
        for _, point in ipairs(data.zones.points) do
            points[#points + 1] = ('vec3(%s, %s, %s)'):format(point.x, point.y, point.z)
        end
    
        local gType = {}
        for _, t in ipairs(data.type) do
            gType[#gType+1] = ('%q'):format(tostring(t))
        end

        result[#result+1] = Format:format(
            label,
            table.concat(gType, ', '),
            data.blip and ('{ type = %s, color = %s }'):format(data.blip.type, data.blip.color) or 'nil',
            table.concat(points, ',\n\t\t\t\t'),
            data.zones.thickness,
            GroupFormat(data.job),
            GroupFormat(data.gang),
            data.impound or 'nil',
            data.shared or 'nil'
        ):gsub('[%s]-[%w]+ = "?nil"?,?', '')
    end
    GarageZone = garageData
    GlobalState.rhd_garage_zone = garageData
    local serializedData = ('return {\n%s}'):format(table.concat(result, "\n"))
    SaveResourceFile(GetCurrentResourceName(), 'data/garage.lua', serializedData, -1)
end

local function SaveVehicleName(dataName)
    local result = {}
    local NameFormat = [[
    ["%s"] = {
        name = "%s"
    },
]]
    for plate, data in pairs(dataName) do
        result[#result + 1] = NameFormat:format(plate, data.name)
    end
    CNV = dataName
    local serializedData = ('return {\n%s}'):format(table.concat(result, "\n"))
    SaveResourceFile(GetCurrentResourceName(), 'data/customname.lua', serializedData, -1)
end

Storage.save = {
    garage = SaveGarage,
    vehname = SaveVehicleName,
}
