return {
    InDevelopment = true, --- Set to false when you have finished setting up this garage
    spawnInVehicle = true, --- Set to true if the player should immediately enter the vehicle when taken out of the garage

--- Specifies the fuel script to use:
--- [rhd_fuel](https://rhd.tebex.io/package/6284098) | 
--- [ox_fuel](https://github.com/overextended/ox_fuel/releases) | 
--- [LegacyFuel](https://github.com/InZidiuZ/LegacyFuel.git) | 
--- [ps-fuel](https://github.com/project-sloth/ps-fuel/releases) | 
--- [cdn-fuel](https://github.com/CodineDev/cdn-fuel/releases)
    fuelScript = 'LegacyFuel',

--- Specifies the interactions system to use:
--- [ox](https://github.com/overextended/ox_target/releases) |
--- [qb](https://github.com/qbcore-framework/qb-target.git) |
--- [interact](https://github.com/darktrovx/interact)
    interact = 'interact',

--- Specifies the radial menu system to use:
--- [ox](https://github.com/overextended/ox_lib/releases) |
--- [qb](https://github.com/qbcore-framework/qb-radialmenu) |
--- [rhd](https://github.com/reyyghi/rhd_radialmenu)
    radialMenu = 'rhd',

--- If set to true, you will need to use the following resource: 
--- [VehicleDeformation](https://github.com/Kiminaze/VehicleDeformation/releases).
--- This setting enables saving vehicle deformation data, which requires 
--- the VehicleDeformation resource to properly function.
    saveDeformation = false,
}