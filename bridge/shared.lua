Framework = {}

function Framework.esx()
    return GetResourceState("es_extended") ~= "missing"
end

function Framework.qb()
    return GetResourceState("qb-core") ~= "missing"
end
