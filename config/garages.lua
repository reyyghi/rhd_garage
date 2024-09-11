return {
    {
        type = "default", --- default, shared, depot
        class = {"car", "motorcycle", "bicycle"},
        label = "Motel Parking",
        points = {
            save = vector4(271.4693, -339.6272, 44.9198, 164.5973),
            take = vector4(276.2885, -342.7426, 44.9199, 332.1771),
            useMarker = true
        },
        blip = {
            colour = 3,
            sprite = 357,
            label = 'Public Parking'
        }
    },
    {
        type = "default", --- default, shared, depot
        class = {"car", "motorcycle", "bicycle"},
        label = "San Andreas Parking",
        points = {
            take = vector4(-330.67, -781.12, 33.96, 40.46),
            save = vector4(-337.11, -775.34, 33.56, 132.09),
            useMarker = true
        },
        blip = {
            colour = 3,
            sprite = 357,
            label = 'Public Parking'
        }
    },
    {
        type = "default", --- default, shared, depot
        class = {"car", "motorcycle", "bicycle"},
        label = "Spanish Ave Parking",
        points = {
            take = vec4(-1160.46, -741.04, 19.95, 41.26),
            save = vec4(-1165.38, -747.65, 18.94, 40.45),
            useMarker = true
        },
        blip = {
            colour = 3,
            sprite = 357,
            label = 'Public Parking'
        }
    },
    {
        type = "default", --- default, shared, depot
        class = {"car", "motorcycle", "bicycle"},
        label = "Caears 24 Parking",
        points = {
            take = vec4(68.08, 13.15, 69.21, 160.44),
            save = vec4(72.61, 11.72, 68.47, 157.59),
            useMarker = true
        },
        blip = {
            colour = 3,
            sprite = 357,
            label = 'Public Parking'
        }
    },
    {
        type = "depot", --- default, shared, depot
        class = {"car", "motorcycle", "bicycle"},
        label = "Impound Lot",
        points = {
            take = vec4(400.45, -1630.87, 29.29, 228.88),
            save = vec4(407.2, -1645.58, 29.31, 228.28),
            useMarker = true
        },
        blip = {
            sprite = 68,
            colour = 3,
        },
    },
    {
        type = "shared", --- default, shared, depot
        class = {"car", "motorcycle", "bicycle"},
        label = "Police Garage",
        points = {
            take = vec4(458.8759, -1022.2189, 28.2411, 90.9592),
            save = vec4(450.7764, -1019.3550, 28.4631, 91.0165),
            useMarker = true
        },
        groups = { --- job & gang
            police = 1
        },
    }
}