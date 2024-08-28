return {
    InDevelopment = true, --- Set to false when you have finished setting up this garage
    spawnInVehicle = true, --- Set to true if the player should immediately enter the vehicle when taken out of the garage

--- Specifies the fuel script to use:
--- [rhd_fuel](https://rhd.tebex.io/package/6284098) | 
--- [ox_fuel](https://github.com/overextended/ox_fuel/releases) | 
--- [LegacyFuel](https://github.com/InZidiuZ/LegacyFuel.git) | 
--- [ps-fuel](https://github.com/project-sloth/ps-fuel/releases) | 
--- [cdn-fuel](https://github.com/CodineDev/cdn-fuel/releases)
    fuelScript = 'rhd_fuel',

--- Specifies the interactions system to use:
--- [ox](https://github.com/overextended/ox_target/releases) |
--- [qb](https://github.com/qbcore-framework/qb-target.git) |
--- [interact](https://github.com/darktrovx/interact)
    interact = 'interact',

--- Specifies the radial menu system to use:
--- [ox](https://github.com/overextended/ox_lib/releases) |
--- [qb](https://github.com/qbcore-framework/qb-radialmenu) |
--- [rhd](https://github.com/reyyghi/rhd_radialmenu)
    radialMenu = 'ox',

--- If set to true, you will need to use the following resource: 
--- [VehicleDeformation](https://github.com/Kiminaze/VehicleDeformation/releases).
--- This setting enables saving vehicle deformation data, which requires 
--- the VehicleDeformation resource to properly function.
    saveDeformation = true,

    ChangeVehicleName = {
        enable = true,  -- Enable or disable the feature to change the vehicle's name. Set to true to activate this feature.
        price = 10      -- Cost required to change the vehicle's name. For example, 10 units of in-game currency.
    },

    TransferVehicle = {
        enable = true,  -- Enable or disable the feature to transfer a vehicle to another player. Set to true to activate this feature.
        price = 100     -- Cost required to transfer the vehicle to another player. For example, 100 units of in-game currency.
    },

    SwapGarage = {
        enable = true,  -- Enable or disable the feature to swap a vehicle between garages. Set to true to activate this feature.
        price = 500     -- Cost required to move the vehicle from one garage to another. For example, 500 units of in-game currency.
    }
}