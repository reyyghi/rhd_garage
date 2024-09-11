local CLASS_CATEGORY = {
    car = {0, 1, 2, 3, 4, 5, 6, 7},        -- Vehicle class included in the group 'car'
    motorcycle = {8},                      -- Vehicle class included in the group 'motorcycle'
    bicycle = {13},                        -- Vehicle class included in the group 'bicycle'
    truck = {9, 10, 11, 12, 20},           -- Vehicle class included in the group 'truck'
    plane = {16},                          -- Vehicle class included in the group 'plane'
    helicopter = {15},                     -- Vehicle class included in the group 'helicopter'
    boat = {14},                           -- Vehicle class included in the group 'boat'
    train = {21},                           -- Vehicle class included in the group 'train'
}

VEH_CLASS = {}

DepotPriceByClass = {
    [0] = 15000,  --- Price for compact cars
    [1] = 15000,  --- Price for sedans
    [2] = 15000,  --- Price for SUVs
    [3] = 15000,  --- Price for coupes
    [4] = 15000,  --- Price for muscle cars
    [5] = 15000,  --- Price for sports classics
    [6] = 15000,  --- Price for sports cars
    [7] = 15000,  --- Price for super cars
    [8] = 15000,  --- Price for motorcycles
    [9] = 15000,  --- Price for off-road vehicles
    [10] = 15000, --- Price for industrial vehicles
    [11] = 15000, --- Price for utility vehicles
    [12] = 15000, --- Price for vans
    [13] = 15000, --- Price for cycles
    [14] = 15000, --- Price for boats
    [15] = 15000, --- Price for helicopters
    [16] = 15000, --- Price for planes
    [17] = 15000, --- Price for service vehicles
    [18] = 0,     --- Price for emergency vehicles
    [19] = 15000, --- Price for military vehicles
    [20] = 15000, --- Price for commercial vehicles
    [21] = 0      --- Price for trains (not applicable)
}

for category, class in pairs(CLASS_CATEGORY) do
    for _, id in pairs(class) do
        VEH_CLASS[id] = category
    end
end